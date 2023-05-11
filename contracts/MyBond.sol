// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MembershipRights.sol";

contract MyBond is ERC20, ERC20Burnable, Pausable, Ownable {
    MembershipRights rights;
    ERC20 money;
    uint256 maxSupplay;
    uint256 multiplier;

    constructor(address _rights, address _money, uint256 _maxSupplay) ERC20("Bond", "eBond") {
        rights = MembershipRights(_rights);
        money = ERC20(_money);
        maxSupplay = _maxSupplay;
        multiplier = 100;
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }    

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function issue(uint256 amount) public {
        require(totalSupply() + amount <= maxSupplay, "Not enough");
        require(rights.hasRights(msg.sender,  HOLDER), "Not a holder");
        require(amount > 0 , "Ammount> 0");
        require(money.balanceOf(msg.sender) >= amount * multiplier);
        require(money.allowance(msg.sender, address(this)) >= amount * multiplier, "Allowance too low");
        _mint(msg.sender, amount);
        money.transferFrom(msg.sender, address(this), amount * multiplier);

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
