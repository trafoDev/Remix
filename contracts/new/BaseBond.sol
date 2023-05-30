// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EnvironmentConfig.sol";
import "./OfferTable.sol";
import "./BondInterface.sol";

error BondZeroAddress();
error NotAvailable();

contract BaseBond is Context, IERC20, IERC20Metadata, Pausable, Ownable, BondInterface {

    string private _name;
    string private _symbol;
    address private _owner;
    //bond initialization indicators
    bool private _envInitialized;
    bool private _bondInitialized;

    EnvironmentConfig private _envConfig;
    ERC20 private _money;

    uint private _moneyDecimal;

    uint256 private _totalSupply;
    uint256 private _maxSupplay;
    uint256 private _bondPrice;
    uint256 private _dailyIntrestRate;
    uint256 private _intrestRate;

    //Platforms 
    mapping(address => bool) private _platformsAllowed;

    //ERC20 data
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;    

/*

    address[] private _buyers;

    struct BondsByDate{
        uint256 date;
        uint256 balance;
        uint256 blocked;
    }

    mapping(address => BondsByDate[]) private _bondBalance;
    mapping(address => mapping(uint256 => uint256)) private _bondIndex;
  */  


    modifier nonZero(uint256 amount) {
        require(amount > 0 , "The number of bonds should be greater than 0.");
        _;
    }     
    modifier initialized() {
        require((_envInitialized && _bondInitialized) == true, "Token wasn't fully initialized.");
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

    function initEnv(address envConfig, address money, address owner_) public {
        if(envConfig == address(0) || money == address(0) || owner_ == address(0)) revert BondZeroAddress();
        _envConfig = EnvironmentConfig(envConfig);
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
        if(platform == address(0)) revert BondZeroAddress();
        require(_envConfig.hasRights(platform,  ASSET_OFFERING), "Platform not approved.");
        _platformsAllowed[platform] = true;
    }
    
    function removePatform(address platform) initialized() public {
        if(platform == address(0)) revert BondZeroAddress();
        require(_platformsAllowed[platform] == true, "Platform not registered.");
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

    function setMembershipenvConfig(address envConfig) public onlyOwner {
        _envConfig = EnvironmentConfig(envConfig);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }    

    function _mint(address account, uint256 amount) internal virtual {
        if(account == address(0)) revert BondZeroAddress();
        _totalSupply += amount;
        unchecked { // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        if(account == address(0)) revert BondZeroAddress();
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "Burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;   // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }
    }

    function allowance(address bondOwner, address platform)  public view virtual override returns (uint256) {
        return _allowances[bondOwner][platform];
    }
    function _approve(address bondOwner, address platform, uint256 amount) internal virtual {
        if(bondOwner == address(0) || platform == address(0)) revert BondZeroAddress();
        _allowances[bondOwner][platform] = amount;
       // emit Approval(bondOwner, platform, amount);
    }
    function _increaseAllowance(address bondOwner, address platform, uint256 addedValue) internal virtual returns (bool) {
        _approve(bondOwner, platform, allowance(bondOwner, platform) + addedValue);
        return true;
    }
    function _decreaseAllowance(address bondOwner, address platform, uint256 subtractedValue) internal virtual returns (bool) {
        uint256 currentAllowance = allowance(bondOwner, platform);
        require(currentAllowance >= subtractedValue, "Decreased allowance below 0");
        unchecked {
            _approve(bondOwner, platform, currentAllowance - subtractedValue);
        }
        return true;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address, uint256) public virtual override returns (bool) {
        revert NotAvailable();
    }

    function approve(address , uint256 ) public virtual override returns (bool) {
        revert NotAvailable();
    }

    function transferFrom(address , address , uint256 ) public virtual override returns (bool) {
        revert NotAvailable();
    }







    function getAllByBuyer(address buyer) public view returns (BondsByDate[] memory) {
        if(buyer == address(0)) revert BondZeroAddress();
        return _bondBalance[buyer];
    }



    function _assignTo(address to, uint256 date, uint256 amount)  internal virtual {
        if(_bondBalance[to].length == 0) {
            _buyers.push(to);
            _bondBalance[to].push(BondsByDate(date, amount, 0));
            _bondIndex[to][date] = _bondBalance[to].length;
        } else {
            if(_bondIndex[to][date] == 0) {
                _bondBalance[to].push(BondsByDate(date, amount, 0));
                _bondIndex[to][date] = _bondBalance[to].length;
            } else {
                _bondBalance[to][_bondIndex[to][date]-1].balance += amount;  
            }
        }
    }

    function _removeFrom(address from, uint256 date, uint256 amount, bool blocked)  internal virtual {
        uint index = _bondIndex[from][date];
        require(index != 0, "No such bonds" );
        BondsByDate memory bonds = _bondBalance[from][index-1];
        require(bonds.balance >= amount, "Not enough bonds" );  
        if(!blocked) {
            require(bonds.balance - bonds.blocked >= amount, "Not enough bonds availible" );  

        } else {
            require(bonds.blocked >= amount, "Not enough blocked bonds" );  
            _bondBalance[from][index-1].blocked -= amount;
        }
        _bondBalance[from][index-1].balance -= amount;
    }

    function issue(uint256 amount) public nonZero(amount) initialized() {
        require(_envConfig.hasRights(msg.sender,  ASSET_HOLDER), "The buyer isn't defined as an approved asset holder.");
        require(totalSupply() + amount <= _maxSupplay, "The total number of bonds exceeds the entire supply value.");
        require(_money.balanceOf(msg.sender) >= amount * _bondPrice, "The buyer doesn't have enough money in their account.");
        require(_money.allowance(msg.sender, address(this)) >= amount * _bondPrice, "The account allowance for the trade is set too low.");

//        uint256 _currDate = timestampToDate(block.timestamp);
        uint256 _currDate = _envConfig.getCurrentDate();

        _assignTo(msg.sender, _currDate, amount);
        _mint(msg.sender, amount);        
        _money.transferFrom(msg.sender, owner(), amount * _bondPrice);
    }

    function makeOffer(address table, uint bondDate, uint256 amount, uint reqPrice) public returns(uint256) {
        require(_platformsAllowed[table] == true, "Platform isn't registered.");
        uint index = _bondIndex[msg.sender][bondDate];
        require(index != 0, "No such bonds" );
        BondsByDate memory bonds = _bondBalance[msg.sender][index-1];
        require(bonds.balance - bonds.blocked >= amount, "Not enough spare bonds" );  

        _bondBalance[msg.sender][index-1].blocked += amount;
        _increaseAllowance(msg.sender, table, amount);
        uint offer = OfferTable(table).newOffer(msg.sender, bondDate, amount, reqPrice);
        return offer;
    }

    function acceptOffer(address seller, address buyer, uint256 bondDate, uint256 amount) public virtual returns (bool) {
        require(_platformsAllowed[msg.sender] == true, "Platform isn't registered.");
        require(totalSupply() >= amount, "Amout exceeds total supplay");
        if(seller == address(0) || buyer == address(0)) revert BondZeroAddress();
        //validating parties envConfig
        require(_envConfig.hasRights(msg.sender, ASSET_OFFERING), "The sender isn't defined as an approved offering platform.");
        require(_envConfig.hasRights(buyer,  ASSET_HOLDER), "Not a holder");
        //Vadidating balances and allowances
        require(allowance(seller, msg.sender) >= amount, "Not enough allowance");
        require(balanceOf(seller) >= amount, "The amout exceeds the total supplay");

        _removeFrom(seller, bondDate, amount, true);
        _balances[seller] -= amount;
        _decreaseAllowance(seller, msg.sender, amount);
        _assignTo(buyer, bondDate, amount);
        _balances[buyer] += amount;

        emit Transfer(seller, buyer, amount);
        return true;
    }

    function withdrawOffer(address bondOwner, uint256 bondDate, uint256 amount) public virtual returns(bool) {
        require(_platformsAllowed[msg.sender] == true, "Platform isn't registered.");
        uint _index = _bondIndex[bondOwner][bondDate];
        require(_index != 0, "No such bonds" );
        BondsByDate memory bonds = _bondBalance[bondOwner][_index-1];
        require(bonds.blocked >= amount, "Something very Wrong" );  

        _bondBalance[bondOwner][_index-1].blocked -= amount;
        _decreaseAllowance(bondOwner, msg.sender, amount);
        return true;
    }

    function redemption(uint buyDate, uint256 amount) public nonZero(amount) initialized() {
        uint _days = _envConfig.getDaysFromNow(buyDate);
        require(_envConfig.hasRights(msg.sender,  ASSET_HOLDER), "Not a holder");
        require(totalSupply() >= amount, "The amout exceeds the total supplay of the asset");
        require(_money.balanceOf(owner()) >= amount * _bondPrice);
        require(_money.allowance(owner(), address(this)) >= amount * _bondPrice, "Allowance too low");
        require(_days > 0, "Cannot redeem the same day");
        
        require(_bondIndex[msg.sender][buyDate] != 0, "No bonds with the date");
        uint256 _index = _bondIndex[msg.sender][buyDate] - 1;
        require(_bondBalance[msg.sender][_index].balance - _bondBalance[msg.sender][_index].blocked >= amount, "Not enough bonds");

        _bondBalance[msg.sender][_index].balance -= amount;
        _money.transferFrom(owner(), msg.sender, amount * (_bondPrice + (_dailyIntrestRate * _days)));
        _burn(msg.sender, amount);
    }

    function coupon() public onlyOwner initialized() {
        require(_envConfig.hasRights(msg.sender, ASSET_HOLDER), "Not a holder");
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
    }

}
