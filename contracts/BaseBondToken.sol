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


contract BaseBond is Context, IERC20, IERC20Metadata, Pausable, Ownable {

    string private _name;
    string private _symbol;
    address private _owner;
    //bond initialization indicators
    bool private _envInitialized;
    bool private _bondInitialized;

    MembershipRights private _rights;
    ERC20 private _money;

    uint private _moneyDecimal;

    uint256 private _maxSupplay;
    uint256 private _bondPrice;
    uint256 private _dailyIntrestRate;
    uint256 private _intrestRate;

    address[] private _buyers;

    struct BondsByDate{
        uint256 date;
        uint256 balance;
        uint256 blocked;
    }

    mapping(address => BondsByDate[]) private _bondBalance;
    mapping(address => mapping(uint256 => uint256)) private _bondIndex;
    
    //Platforms 
    mapping(address => bool) private _platformsAllowed;

    //ERC20 data
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;    
    uint256 private _totalSupply;

    modifier nonZero(uint256 amount) {
        require(amount > 0 , "The number of bonds should be greater than 0.");
        _;
    }     
    modifier initialized() {
        require(_envInitialized && _bondInitialized == true, "Token wasn't fully initialized.");
        _;
    }     

    constructor() {
        _maxSupplay = 1000000;
        _bondPrice = 10000;
        _intrestRate = 100; 
        _dailyIntrestRate = 1;
        _envInitialized = false;
        _bondInitialized = false;
        _totalSupply = 0;
    }

    function initEnv(address rights, address money, address owner_) public {
        require(rights != address(0), "Rights list is null.");
        require(money != address(0), "Money token is null.");
        require(owner_ != address(0), "Owner address is null.");
        _rights = MembershipRights(rights);
        _money = ERC20(money);
        _moneyDecimal = _money.decimals();
        _owner = owner_;
        _envInitialized = true;
    }
    
    function initId(string memory bondName, string memory bondSymbol) public {
        _maxSupplay = 1000000;
        _bondPrice = 10000;
        _intrestRate = 100; 
        _dailyIntrestRate = 1;
        _name = bondName;
        _symbol = bondSymbol;
        _bondInitialized = true;
    }
    
    function addPatform(address platform) initialized() public {
        require(platform != address(0), "Adding zero address platform");
        bool _setRights = (address(_rights) != address(0));
        require(_setRights && _rights.hasRights(platform,  ASSET_OFFERING), "The platform isn't defined as an approved offering platform.");
        _platformsAllowed[platform] = true;
    }
    
    function removePatform(address platform) initialized() public {
        require(platform != address(0), "Removing zero address platform");
        require(_platformsAllowed[platform] == true, "The platform isn't registered.");
        _platformsAllowed[platform] = false;
    }
    
    function owner() public view virtual override returns (address) {
        return _owner;
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

    function getAllByBuyer(address buyer) public view returns (BondsByDate[] memory) {
        require(buyer != address(0), "Listing bonds from  zero address.");
        return _bondBalance[buyer];
    }

    //IERC20
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }    

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Mint to the zero address");

//        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
//        emit Transfer(address(0), account, amount);

//        _afterTokenTransfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Burn from the zero address");
//        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "Burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }
//        emit Transfer(account, address(0), amount);
//        _afterTokenTransfer(account, address(0), amount);
    }

    function allowance(address bondOwner, address platform)  public view virtual override returns (uint256) {
        return _allowances[bondOwner][platform];
    }
    function _approve(address bondOwner, address platform, uint256 amount) internal virtual {
        require(bondOwner != address(0), "Approve from the zero address");
        require(platform != address(0), "Approve to the zero address");

        _allowances[bondOwner][platform] = amount;
       // emit Approval(bondOwner, platform, amount);
    }
    function _spendAllowance(address bondOwner, address platform, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(bondOwner, platform);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Insufficient allowance for the platform");
            unchecked {
                _approve(bondOwner, platform, currentAllowance - amount);
            }
        }
    }
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");

 //       _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "Transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

  //      _afterTokenTransfer(from, to, amount);
    }    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        //revert("This option is not available for eBOND");
    }

    function transfer(address to, uint256 date, uint256 amount) public virtual returns (bool) {
        //revert("This option is not available for eBOND");

        //require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(date > 20200101, "Invalid bond date");



        bool _setRights = (address(_rights) != address(0));
 //       uint256 _now = timestampToDate(block.timestamp);
 //       uint _days = _daysFromDateConcatenated(_now) - _daysFromDateConcatenated(buyDate);
        require(_setRights && _rights.hasRights(msg.sender,  ASSET_HOLDER), "Not a holder");
        require(totalSupply() >= amount, "The amout exceeds the total supplay of the asset");
//        require(_money.balanceOf(owner()) >= amount * _bondPrice);
//        require(_money.allowance(owner(), address(this)) >= amount * _bondPrice, "Allowance too low");
 //       require(_now > buyDate, "The bond may be redeemed at least one day after the date of purchase.");

/*

  //      _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
*/
//        _afterTokenTransfer(from, to, amount);
        return true;
    }

//    function allowance(address , address ) public view virtual override returns (uint256) {
//        return 0;
//    }

    function approve(address , uint256 ) public virtual override returns (bool) {
        revert("This option is not available for eBOND");
    }

    function transferFrom(address , address , uint256 ) public virtual override returns (bool) {
        return true;
    }
    function transferFrom(address from, address to, uint256 date, uint256 amount) public virtual returns (bool) {
        address platform = msg.sender;
        //Basic validations
        require(date > 20200101, "Invalid bond date");
        require(totalSupply() >= amount, "The amout exceeds the total supplay of the asset");
        require(from != address(0), "From address is set to null.");
        require(to != address(0), "To address is set to null.");
        //validating parties rights
        if (address(_rights) != address(0)) {
            require(_rights.hasRights(platform, ASSET_OFFERING), "The sender isn't defined as an approved offering platform.");
            require(_rights.hasRights(to,  ASSET_HOLDER), "Not a holder");
        }
        //Vadidating balances and allowances
        require(allowance(from, platform) >= amount, "Not enough allowance");
        require(balanceOf(from) >= amount, "The amout exceeds the total supplay of the asset");
        require(_bondBalance[from][date].balance >= amount, "The amout exceeds the total supplay of the asset");

  //      _beforeTokenTransfer(from, to, amount);


        for(uint i=0; i < _bondBalance[from].length; i++) {
            if(_bondBalance[from][i].date == date) {
                BondsByDate memory bond = _bondBalance[from][i];
                require(bond.balance >= amount, "The amout exceeds the total supplay of the asset");
                _bondBalance[from][i].balance -= amount;
                break;
            }
        }
        uint256 fromBalance = _balances[from];
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }
/*
        for(uint i=0; i < _bondBalance[from].length; i++) {
            if(_bondBalance[from][i].date == date) {
                BondsByDate bond = _bondBalance[from][i];
                require(bond.balance >= amount, "The amout exceeds the total supplay of the asset");
                _bondBalance[from][i].balance -= amount;
                break;
            }
        }
*/

        emit Transfer(from, to, amount);

//        _afterTokenTransfer(from, to, amount);
        return true;
    }

    function issue(uint256 amount) public nonZero(amount) initialized() {
        bool _setRights = (address(_rights) != address(0));
        require(_setRights && _rights.hasRights(msg.sender,  ASSET_HOLDER), "The buyer isn't defined as an approved asset holder.");
        require(totalSupply() + amount <= _maxSupplay, "The total number of bonds exceeds the entire supply value.");
        require(_money.balanceOf(msg.sender) >= amount * _bondPrice, "The buyer doesn't have enough money in their account.");
        require(_money.allowance(msg.sender, address(this)) >= amount * _bondPrice, "The account allowance for the trade is set too low.");

        uint256 _currDate = timestampToDate(block.timestamp);
        uint256 _elements = _bondBalance[msg.sender].length; 

        if(_elements == 0) {
            _buyers.push(msg.sender);
            _bondBalance[msg.sender].push(BondsByDate(_currDate, amount, 0));
            _bondIndex[msg.sender][_currDate] = _bondBalance[msg.sender].length;
        } else {
            if(_bondIndex[msg.sender][_currDate] == 0) {
                _bondBalance[msg.sender].push(BondsByDate(_currDate, amount, 0));
                _bondIndex[msg.sender][_currDate] = _bondBalance[msg.sender].length;
            } else {
                _bondBalance[msg.sender][_bondIndex[msg.sender][_currDate]-1].balance += amount;  
            }
        }
        _mint(msg.sender, amount);        
        _money.transferFrom(msg.sender, owner(), amount * _bondPrice);
    }

    function redem(uint buyDate, uint256 amount) public nonZero(amount) initialized() {
        bool _setRights = (address(_rights) != address(0));
        uint256 _now = timestampToDate(block.timestamp);
        uint _days = _daysFromDateConcatenated(_now) - _daysFromDateConcatenated(buyDate);
        require(_setRights && _rights.hasRights(msg.sender,  ASSET_HOLDER), "Not a holder");
        require(totalSupply() >= amount, "The amout exceeds the total supplay of the asset");
        require(_money.balanceOf(owner()) >= amount * _bondPrice);
        require(_money.allowance(owner(), address(this)) >= amount * _bondPrice, "Allowance too low");
        require(_now > buyDate, "The bond may be redeemed at least one day after the date of purchase.");
        
        uint256 _index = _bondIndex[msg.sender][buyDate]-1;
        require(_index > 0, "No bonds with the date");
        require(_bondBalance[msg.sender][_index].balance - _bondBalance[msg.sender][_index].blocked >= amount, "Not enough bonds");

        _bondBalance[msg.sender][_index].balance -= amount;
        _money.transferFrom(owner(), msg.sender, amount * (_bondPrice + (_dailyIntrestRate * _days)));
        _burn(msg.sender, amount);
    }

    function blockForOfferning(uint buyDate, uint256 amount) public nonZero(amount) initialized() {
    /*    bool _setRights = (address(_rights) != address(0));
        uint256 _now = timestampToDate(block.timestamp);
        uint _days = _daysFromDateConcatenated(_now) - _daysFromDateConcatenated(buyDate);
        require(_setRights && _rights.hasRights(msg.sender,  ASSET_HOLDER), "Not a holder");
        require(totalSupply() >= amount, "The amout exceeds the total supplay of the asset");
        require(_money.balanceOf(owner()) >= amount * _bondPrice);
        require(_money.allowance(owner(), address(this)) >= amount * _bondPrice, "Allowance too low");
        require(_now > buyDate, "The bond may be redeemed at least one day after the date of purchase.");
        
        uint256 _index = _bondIndex[msg.sender][buyDate]-1;
        require(_index > 0, "No bonds with the date");
        require(_bondBalance[msg.sender][_index].balance - _bondBalance[msg.sender][_index].blocked >= amount, "Not enough bonds");

        _bondBalance[msg.sender][_index].balance -= amount;
        _money.transferFrom(owner(), msg.sender, amount * (_bondPrice + (_dailyIntrestRate * _days)));
        _burn(msg.sender, amount);
*/        
    }

    function coupon() public onlyOwner initialized() {
/*        bool _setRights = (address(_rights) != address(0));
        require(_setRights && _rights.hasRights(msg.sender,  ASSET_HOLDER), "Not a holder");
        require(_money.balanceOf(owner()) >= totalSupply() * _intrestRate);
        uint256 _sum;

        for(uint i = 0; i<_buyers.length; i++ ) {
            _sum=0;
            for(uint ii = 0; ii<_bondBalance[_buyers[i]].length; ii++ ) {
                _sum += _bondBalance[_buyers[i]][ii].balance;
            }
            if( _sum > 0) {
                _money.transferFrom(owner(), _buyers[i], _sum * _intrestRate);
            }
        }
*/  
    }
}

