// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MembershipRights.sol";

contract MyCashToken is ERC20, ERC20Burnable, Pausable, Ownable {
    MembershipRights rights;

    constructor(address _rights) ERC20("CashToken", "ePLN") {
        rights = MembershipRights(_rights);
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

    function mint(address to, uint256 amount) public {
        require(rights.hasRights(msg.sender,  MINTER), "Not allwed");
        require(rights.hasRights(to,  HOLDER), "Not a holder");
        require(amount > 0 , "Ammount> 0");
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        require(rights.hasRights(to,  HOLDER), "Not a holder");
        super._beforeTokenTransfer(from, to, amount);
    }
}
