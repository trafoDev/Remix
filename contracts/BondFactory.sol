//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './CloneFactory.sol';
import './BaseBond.sol';

contract Factory is CloneFactory {
    BaseBond[] public children;
    address private _masterContract;

    string private _name;
    string private _symbol;

    address private _rights;
    address private _money;

     constructor(address masterContract, address rights, address money){
        require(rights != address(0), "Rights list is null.");
        require(money != address(0), "Money token is null.");
        require(masterContract != address(0), "Master smart contract is null.");
        _masterContract = masterContract;
        _rights = rights;
        _money = money;
     }

     function createChild(string memory name_, string memory symbol_) external{
        BaseBond child = BaseBond(createClone(_masterContract));
        child.initEnv(_rights, _money, msg.sender);
        child.initId(name_, symbol_);
        children.push(child);
     }

     function getChildren() external view returns(BaseBond[] memory){
         return children;
     }

     function getName() external view returns(string memory){
         return children[0].name();
     }
}
