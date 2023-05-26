// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";

uint48 constant NONE            = 0x00;
uint48 constant MONEY_MINTER    = 0x01;
uint48 constant ASSET_HOLDER    = 0x02;
uint48 constant LIST_ADMIN      = 0x04;
uint48 constant ASSET_OFFERING  = 0x80;

contract MembershipRights is Ownable {
    mapping (address => uint48) private _members;

    modifier manageable() {
        require(msg.sender == owner() || hasRights(msg.sender, LIST_ADMIN), "User isn't a list administrator.");
        _;
    }     

    constructor() {
        _members[msg.sender] = LIST_ADMIN;
    }
    function setMemberRights(address usr, uint48 role) public manageable() {
        _members[usr] = role;
    }    
    function setMembersRights(address[] memory usr, uint48 role) public manageable() {
        for(uint i=0; i < usr.length; i++) {
            _members[usr[i]] = role;
        }
    }    
    function updateMemberRights(address usr, uint48 role) public manageable() {
        _members[usr] = role;
    }    
    function updateMembersRights(address[] memory usr, uint48 role) public manageable() {
        for(uint i=0; i < usr.length; i++) {
            _members[usr[i]] |= role;
        }
    }    
    function hasRights(address usr, uint48 role) public view returns(bool){
        return _members[usr] & role == role;
    }    
    function getRights(address usr) public view returns(uint48){
        return _members[usr];
    }    
}