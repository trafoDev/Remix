// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

uint48 constant MINTER = 0x1;
uint48 constant HOLDER = 0x2;
uint48 constant ADMIN  = 0x4;

contract MembershipRights {
    mapping (address => uint48) members;

    constructor() {
    }
/*    function mint(uint256 _ammount) public {
        require(members[msg.sender] == 1, "Not allwed");
        totalAmmount += _ammount;
        _mint(msg.sender, _ammount);
    }
    function mintTo(uint256 _ammount, address _receiver) public {
        require(members[msg.sender] & MINTER == MINTER, "Not allwed");
        require(members[_receiver]  & HOLDER == HOLDER, "Not holder");
        totalAmmount += _ammount;
        _mint(_receiver, _ammount);
    }
    function burn(uint256 _ammount) public {
        totalAmmount -= _ammount;
        _burn(msg.sender, _ammount);
    }
    function getTotalAmmount() public view returns (uint256){
        return totalAmmount;
    }
  */
    function updateMember(address usr, uint48 role) public {
        members[usr] = role;
    }    
    function hasRights(address usr, uint48 role) public view returns(bool){
        return members[usr] & role == role;
    }    
}