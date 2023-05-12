// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

uint48 constant MONEY_MINTER    = 0x1;
uint48 constant ASSET_HOLDER    = 0x2;
uint48 constant LIST_ADMIN      = 0x4;

contract MembershipRights {
    mapping (address => uint48) members;

    constructor() {
        members[msg.sender] = LIST_ADMIN;
    }
    function setMemberRigts(address _usr, uint48 _role) public {
        require(hasRights(msg.sender, LIST_ADMIN), "Not an RightsList admin");
        members[_usr] = _role;
    }    
    function updateMembersRigts(address[] memory _usr, uint48 _role) public {
        require(hasRights(msg.sender, LIST_ADMIN), "Not an RightsList admin");
        for(uint i=0; i < _usr.length; i++) {
            members[_usr[i]] |= _role;
        }
    }    
    function hasRights(address usr, uint48 role) public view returns(bool){
        return members[usr] & role == role;
    }    
}