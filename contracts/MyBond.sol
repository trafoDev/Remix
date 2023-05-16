// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MembershipRights.sol";
//import "hardhat/console.sol";

uint constant SECONDS_PER_DAY = 24 * 60 * 60;
int constant OFFSET19700101 = 2440588;


contract MyBond is Pausable, Ownable {
    MembershipRights rights;
    ERC20 money;
    uint256 totalSupply1;
    uint256 maxSupplay;
    uint256 bondPrice;
    uint256 intrestRate;
    address[] buyers;

    struct BondsByDate{
        uint256 date;
        uint256 balance;
    }
    mapping(address => BondsByDate[]) buys;
/*
    constructor(address _rights, address _money, uint256 _maxSupplay, uint256 _price, uint256 _intrestRate) {
        rights  = MembershipRights(_rights);
        money   = ERC20(_money);
        maxSupplay  = _maxSupplay;
        bondPrice   = _price;
        intrestRate = _intrestRate;
    }
*/
    constructor(address _rights, address _money) {
        rights      = MembershipRights(_rights);
        money       = ERC20(_money);
        maxSupplay  = 1000;
        bondPrice   = 100;
        intrestRate = 10; 
    }

    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampToDate(uint timestamp) internal pure returns (uint256 date) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        date = year*10000+month*100+day;

    }

    function decimals() public view virtual returns (uint8) {
        return 0;
    }    

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function totalSupply() public view virtual returns (uint256) {
       return totalSupply1;
    }

    function getAllByBuyer(address _buyer) public view returns (BondsByDate[] memory) {
//        console.log(buys[_buyer][0].balance);
        return buys[_buyer];
    }
/*    
    function printAllByBuyer() public view  {
        BondsByDate[] memory result = getAllByBuyer(msg.sender); 
        for(uint i; i < result.length; i++) {
            console.log(result[i].balance);
        }
    }
*/    
    function issue(uint256 _amount) public {
        require(totalSupply() + _amount <= maxSupplay, "The total number of bonds exceeds the entire supply value.");
        require(rights.hasRights(msg.sender,  ASSET_HOLDER), "The buyer isn't defined as an approved asset holder.");
        require(_amount > 0 , "The number of ordered bonds should be greater than 0.");
        require(money.balanceOf(msg.sender) >= _amount * bondPrice, "The buyer doesn't have enough money in their account.");
        require(money.allowance(msg.sender, address(this)) >= _amount * bondPrice, "The account allowance for the trade is set too low.");
        uint256 currDate = timestampToDate(block.timestamp);
        uint256 elements = buys[msg.sender].length; 
//        console.log(currDate);
        if(elements == 0) {
//            console.log("Adding:");
//            console.log("Adding: %u");
            buyers.push(msg.sender);
            buys[msg.sender].push(BondsByDate(currDate, _amount));
        } else {
            if(buys[msg.sender][elements-1].date == currDate) {
                buys[msg.sender][elements-1].balance += _amount;  
//                console.log("Add");
//                console.log(buys[msg.sender][elements-1].balance);
            } else {
//                console.log(currDate);
                buys[msg.sender].push(BondsByDate(currDate, _amount));
            }
        }
        totalSupply1 += _amount;
        money.transferFrom(msg.sender, owner(), _amount * bondPrice);
    }


    function redem(uint _buyDate, uint256 _amount) public {
        require(totalSupply() >= _amount, "The amout exceeds the total supplay of the asset");
        require(rights.hasRights(msg.sender,  ASSET_HOLDER), "Not a holder");
        require(_amount > 0 , "Ammount> 0");
        require(money.balanceOf(owner()) >= _amount * bondPrice);
        require(money.allowance(owner(), address(this)) >= _amount * bondPrice, "Allowance too low");
        for(uint i; i < buys[msg.sender].length; i++) {
            if(buys[msg.sender][i].date == _buyDate) {
//                console.log(buys[msg.sender][i].balance);
                if(buys[msg.sender][i].balance >= _amount) {
                    buys[msg.sender][i].balance -= _amount;
                    totalSupply1 -= _amount;
                    money.transferFrom(owner(), msg.sender, _amount * bondPrice);
//                    console.log(buys[msg.sender][i].balance);
                    break;
                }
            }
        }
    }

    function coupon() public onlyOwner {
        require(rights.hasRights(msg.sender,  ASSET_HOLDER), "Not a holder");
        require(money.balanceOf(owner()) >= totalSupply() * intrestRate);

        for(uint i = 0; i<buyers.length; i++ ) {
//            console.log("Cupon for: %s", buyers[i]);
            for(uint ii = 0; ii<buys[msg.sender].length; ii++ ) {
                money.transferFrom(owner(), buyers[i], buys[msg.sender][ii].balance * intrestRate);
            }
        }
    }
}

