//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './CloneFactory.sol';
import './BaseBond.sol';

contract Factory is CloneFactory {
     BaseBond[] public children;
     address masterContract;

     constructor(address _masterContract){
         masterContract = _masterContract;
     }

     function createChild(uint ) external{
        BaseBond child = BaseBond(createClone(masterContract));
        //child.init(data);
        child.init();
        children.push(child);
     }

     function getChildren() external view returns(BaseBond[] memory){
         return children;
     }

     function getName() external view returns(string memory){
         return children[0].name();
     }
}
