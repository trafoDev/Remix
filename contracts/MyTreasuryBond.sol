// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MembershipRights.sol";
import "hardhat/console.sol";

uint constant SECONDS_PER_DAY = 24 * 60 * 60;
int constant OFFSET19700101 = 2440588;


contract MyBond is Pausable, Ownable {
    MembershipRights rights;
    ERC20 money;
    uint256 totalSupply1;
    uint256 maxSupplay;
    uint256 bondPrice;
    uint256 couponMultiplier;
    address[] buyers;
    mapping(address => mapping(uint256  => uint256 )) buys;

/*    constructor(address _rights, address _money, uint256 _maxSupplay, uint256 _price) {
        rights  = MembershipRights(_rights);
        money   = ERC20(_money);
        maxSupplay  = _maxSupplay;
        bondPrice   = _price;
        couponMultiplier = 10;
    }
*/
    constructor() {
        maxSupplay  = 1000;
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

    function getAll() public view returns (address[] memory){
        address[] memory ret = new address[](addressRegistryCount);
        for (uint i = 0; i < addressRegistryCount; i++) {
            ret[i] = addresses[i];
        }
        return ret;
    }

    function issue(uint256 _amount) public {
        require(totalSupply() + _amount <= maxSupplay, "The total number of bonds exceeds the entire supply value.");
        //require(rights.hasRights(msg.sender,  ASSET_HOLDER), "The buyer isn't defined as an approved asset holder.");
        require(_amount > 0 , "The number of ordered bonds should be greater than 0.");
        //require(money.balanceOf(msg.sender) >= _amount * bondPrice, "The buyer doesn't have enough money in their account.");
        //require(money.allowance(msg.sender, address(this)) >= _amount * bondPrice, "The account allowance for the trade is set too low.");
        if(buys[msg.sender][0] == 0) {
            console.log("Adding:");
            console.log("Adding: %u");
           buys[msg.sender][0] = 1;
           buyers.push(msg.sender);
        }

        buys[msg.sender][timestampToDate(block.timestamp)] += _amount;
        totalSupply1 += _amount;
        //money.transferFrom(msg.sender, owner(), _amount * bondPrice);
    }


    function redem(uint256 amount) public {
        //require(totalSupply() <= amount, "Not enough bonds issued");
        require(rights.hasRights(msg.sender,  ASSET_HOLDER), "Not a holder");
        require(amount > 0 , "Ammount> 0");
        require(money.balanceOf(owner()) >= amount * bondPrice);
        //require(money.allowance(msg.sender, address(this)) >= amount * multiplier, "Allowance too low");
     //   _burn(owner(), amount);
        money.transferFrom(owner(), owner(), amount * bondPrice);
    }
/*
    function coupon() public {
        require(rights.hasRights(msg.sender,  ASSET_HOLDER), "Not a holder");
       // require(money.balanceOf(owner()) >= totalSupply() * couponMultiplier);

    ///    for(uint i = 0; i<buyers.length; i++ ) {
    ///        console.log("Cupon for: %s", buyers[i]);
    ///        money.transferFrom(owner(), buyers[i], balanceOf(buyers[i]) * couponMultiplier);
    ///    }

    }
/*
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        require(rights.hasRights(to,  ASSET_HOLDER), "Not a holder");
        super._beforeTokenTransfer(from, to, amount);
    }
*/
}

