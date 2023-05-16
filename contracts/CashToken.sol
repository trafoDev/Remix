// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MembershipRights.sol";

contract CashToken is ERC20, ERC20Burnable, Pausable, Ownable {
    MembershipRights private _rights;

    modifier nonZero(uint256 amount) {
        require(amount > 0 , "The amout of money to be minted have to be greater than 0");
        _;
    }     

    constructor(address rights) ERC20("Digital Stablecoin Based on PLN", "ePLN") {
        _rights = MembershipRights(rights);
    }

    function decimals() public view virtual override returns (uint8) {
        return 2;
    }    

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setMembershipRights(address rights) public onlyOwner {
        _rights = MembershipRights(rights);
    }

    function mint(address to, uint256 amount) public nonZero(amount) {
        bool _setRights = (address(_rights) != address(0));
        require(to != address(0), "Minting to zero address.");
        require(_setRights && _rights.hasRights(msg.sender, MONEY_MINTER), "User is not approved to mint money");
        require(_setRights && _rights.hasRights(to,  ASSET_HOLDER), "Receiver address is not an approved asset holder");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public nonZero(amount) onlyOwner  {
        require(from != address(0), "Burning from zero address.");
        require(balanceOf(from) >= amount, "Burn amount is greater than the debit account ballance");
        _burn(from, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        bool _setRights = (address(_rights) != address(0));
        require(_setRights && _rights.hasRights(to, ASSET_HOLDER), "Receiver address is not an approved asset holder");
        require(from==address(0) || balanceOf(from) >= amount, "Transfer amount is greater than the debit account ballance");
        super._beforeTokenTransfer(from, to, amount);
    }
}
