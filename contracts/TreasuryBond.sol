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


contract TreasuryBond is IERC20, IERC20Metadata, Pausable, Ownable {
    MembershipRights private _rights;
    ERC20 private _money;
    uint private _moneyDecimal;
    string private _name;
    string private _symbol;

    uint256 private _maxSupplay;
    uint256 private _bondPrice;
    uint256 private _dailyIntrestRate;
    uint256 private _intrestRate;

    uint256 private _totalSupply1;
    mapping(address => uint256) private _balances;
    address[] private _buyers;

    struct BondsByDate{
        uint256 date;
        uint256 balance;
    }

    mapping(address => BondsByDate[]) private _buys;

    modifier nonZero(uint256 amount) {
        require(amount > 0 , "The number of bonds should be greater than 0.");
        _;
    }     
/*
    constructor(address _rights, address _money, uint256 _maxSupplay, uint256 _price, uint256 _intrestRate) {
        rights  = MembershipRights(_rights);
        money   = ERC20(_money);
        maxSupplay  = _maxSupplay;
        bondPrice   = _price;
        intrestRate = _intrestRate;
    }
*/
    constructor(address rights, address money) {
        _rights       = MembershipRights(rights);
        _money        = ERC20(money);
        _maxSupplay   = 1000000;
        _bondPrice    = 10000;
        _intrestRate  = 100; 
        _dailyIntrestRate = 1;

        _moneyDecimal = 2;
        _name = "First Polish Bond based on blockchain"; 
        _symbol = "eBOND"; 
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

    function _daysFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day - 32075 + (1461 * (_year + 4800 + (_month - 14) / 12)) / 4
            + (367 * (_month - 2 - ((_month - 14) / 12) * 12)) / 12
            - (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) / 4 - OFFSET19700101;

        _days = uint256(__days);
    }

    function _daysFromDateConcatenated(uint256 date) internal pure returns  (uint256 _days) {
        require(date >= 19710000);
        int256 _day = int256(date % 100);
        int256 _month = int256((date / 100) % 100);
        int256 _year = int256(date / 10000);
        int256 __days = _day - 32075 + (1461 * (_year + 4800 + (_month - 14) / 12)) / 4
            + (367 * (_month - 2 - ((_month - 14) / 12) * 12)) / 12
            - (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) / 4 - OFFSET19700101;

        _days = uint256(__days);
    }


    function timestampToDate(uint timestamp) internal pure returns (uint256 date) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        date = year * 10000 + month * 100 + day;

    }

    function setMembershipRights(address rights) public onlyOwner {
        _rights = MembershipRights(rights);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }    
    
    function decimals() public view virtual override returns (uint8) {
            return 0;
    }    

    function totalSupply() public view virtual override returns (uint256) {
       return _totalSupply1;
    }

    function getAllByBuyer(address buyer) public view returns (BondsByDate[] memory) {
        require(buyer != address(0), "Listing bonds from  zero address.");
        return _buys[buyer];
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        require(account != address(0), "Checking balance of zero account.");
        return _balances[account];
//        uint256 _balance = 0;
//        for(uint i; i < _buys[msg.sender].length; i++) {
//           _balance += _buys[msg.sender][i].balance;
//        }
//        return _balance;
    }

    function transfer(address , uint256 ) public virtual override returns (bool) {
        return false;
    }

    function allowance(address , address ) public view virtual override returns (uint256) {
        return 0;
    }

    function approve(address , uint256 ) public virtual override returns (bool) {
        return false;
    }

    function transferFrom(
        address ,
        address ,
        uint256 
    ) public virtual override returns (bool) {
        return false;
    }






    function issue(uint256 amount) public nonZero(amount){
        bool _setRights = (address(_rights) != address(0));
        require(_setRights && _rights.hasRights(msg.sender,  ASSET_HOLDER), "The buyer isn't defined as an approved asset holder.");
        require(totalSupply() + amount <= _maxSupplay, "The total number of bonds exceeds the entire supply value.");
        require(_money.balanceOf(msg.sender) >= amount * _bondPrice, "The buyer doesn't have enough money in their account.");
        require(_money.allowance(msg.sender, address(this)) >= amount * _bondPrice, "The account allowance for the trade is set too low.");
        uint256 _currDate = timestampToDate(block.timestamp);
        uint256 _elements = _buys[msg.sender].length; 
        if(_elements == 0) {
            _buyers.push(msg.sender);
            _buys[msg.sender].push(BondsByDate(_currDate, amount));
        } else {
            if(_buys[msg.sender][_elements-1].date == _currDate) {
                _buys[msg.sender][_elements-1].balance += amount;  
            } else {
                _buys[msg.sender].push(BondsByDate(_currDate, amount));
            }
        }
        _balances[msg.sender] += amount;
        _totalSupply1 += amount;
        _money.transferFrom(msg.sender, owner(), amount * _bondPrice);
    }

    function redem(uint buyDate, uint256 amount) public nonZero(amount){
        bool _setRights = (address(_rights) != address(0));
        uint256 _now = timestampToDate(block.timestamp);
        uint _days = _daysFromDateConcatenated(_now) - _daysFromDateConcatenated(buyDate);
        require(_setRights && _rights.hasRights(msg.sender,  ASSET_HOLDER), "Not a holder");
        require(totalSupply() >= amount, "The amout exceeds the total supplay of the asset");
        require(_money.balanceOf(owner()) >= amount * _bondPrice);
        require(_money.allowance(owner(), address(this)) >= amount * _bondPrice, "Allowance too low");
        require(_now > buyDate, "The bond may be redeemed at least one day after the date of purchase.");
        for(uint i; i < _buys[msg.sender].length; i++) {
            if(_buys[msg.sender][i].date == buyDate) {
                if(_buys[msg.sender][i].balance >= amount) {
                    _buys[msg.sender][i].balance -= amount;
                    _totalSupply1 -= amount;
                    _money.transferFrom(owner(), msg.sender, amount * (_bondPrice + (_dailyIntrestRate * _days)));
                    _balances[msg.sender] -= amount;
                    break;
                }
            }
        }
    }

    function coupon() public onlyOwner {
        bool _setRights = (address(_rights) != address(0));
        require(_setRights && _rights.hasRights(msg.sender,  ASSET_HOLDER), "Not a holder");
        require(_money.balanceOf(owner()) >= totalSupply() * _intrestRate);
        uint256 _sum;

        for(uint i = 0; i<_buyers.length; i++ ) {
            _sum=0;
            for(uint ii = 0; ii<_buys[_buyers[i]].length; ii++ ) {
                _sum += _buys[_buyers[i]][ii].balance;
            }
            if( _sum > 0) {
                _money.transferFrom(owner(), _buyers[i], _sum * _intrestRate);
            }
        }
    }
}

