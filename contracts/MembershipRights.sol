// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

uint48 constant MINTER = 0x1;
uint48 constant HOLDER = 0x2;
uint48 constant ADMIN  = 0x4;

contract MembershipRights {
    mapping (address => uint48) members;

    constructor() {
        members[msg.sender] = ADMIN;
    }
    function updateMember(address usr, uint48 role) public {
        members[usr] = role;
    }    
    function hasRights(address usr, uint48 role) public view returns(bool){
        return members[usr] & role == role;
    }    
}