// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MembershipRights.sol";

contract MyCashToken is ERC20, ERC20Burnable, Pausable, Ownable {
    MembershipRights rights;

    constructor(address _rights) ERC20("Digital Stablecoin Based on PLN", "ePLN") {
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
        require(rights.hasRights(msg.sender,  MONEY_MINTER), "User is not approved to mint money");
        require(rights.hasRights(to,  ASSET_HOLDER), "Receiver address is not an approved asset holder");
        require(amount > 0 , "The amout of money to be minted have to be greater than 0");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyOwner {
        require(amount > 0 , "The amout of money to be minted have to be greater than 0");
        require(balanceOf(from) >= amount, "Burn amount is greater than the debit account ballance");
        _burn(from, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        require(rights.hasRights(to, ASSET_HOLDER), "Receiver address is not an approved asset holder");
        require(balanceOf(from) >= amount, "Transfer amount is greater than the debit account ballance");
        super._beforeTokenTransfer(from, to, amount);
    }
}
