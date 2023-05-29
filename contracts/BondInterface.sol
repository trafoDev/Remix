// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface BondInterface {
    function acceptOffer(address seller, address buyer, uint256 bondDate, uint256 amount) external returns (bool);

    function withdrawOffer(address owner, uint256 bondDate, uint256 amount) external returns(bool);
}


    
