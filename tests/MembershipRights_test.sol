// SPDX-License-Identifier: GPL-3.0
        
pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "../contracts/MR.sol";
import "remix_accounts.sol";
import "hardhat/console.sol";

   //MembershipRights rights;

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract testSuite1 is MembershipRights{
    address acc0 = TestsAccounts.getAccount(0);
    address acc1 = TestsAccounts.getAccount(1);

    function beforeAll() public {
        console.log("sender -> %s",  msg.sender);
        console.log("Acc0 -> %s",  acc0);
        console.log("this -> %s",  address(this));
        console.log("MR -> %s",  getRights(address(this)));
        console.log("owner -> %s",  owner());

  
      //  Assert.equal(acc0, msg.sender, "!!doesn't have rights");
    //    Assert.equal(acc1, rights.owner(), "!!---doesn't have rights");
        Assert.equal(hasRights(acc0, LIST_ADMIN), true, "doesn't have rights");
        Assert.notEqual(hasRights(acc0, MONEY_MINTER), true, "doesn't have rights");
        Assert.equal(acc0, owner(), "doesn't have rights");
       // Assert.equal(rights.hasRights(acc0, MONEY_MINTER), true, "doesn't have MINTER rights");
    }

    /// #sender: account-1
    function checkSuccess() public {
        // Use 'Assert' methods: https://remix-ide.readthedocs.io/en/latest/assert_library.html
        console.log("sender -> %s",  msg.sender);
//        Assert.ok(setMemberRights(msg.sender, LIST_ADMIN), "sss");
    }

}
/*
contract testSuite {

    MembershipRights rights;

    address acc0 = TestsAccounts.getAccount(0); //owner by default
    address acc1 = TestsAccounts.getAccount(1); 
    address acc2 = TestsAccounts.getAccount(2);
    address acc3 = TestsAccounts.getAccount(3);

    /// #sender: account-0
    function beforeAll() public {
        console.log("sender -> %s",  msg.sender);
        console.log("Acc0 -> %s",  acc0);
        console.log("this -> %s",  address(this));

        rights = MembershipRights(testSuite1); //new MembershipRights();
        Assert.notEqual(address(rights), address(0), ""); 
        Assert.equal(rights.hasRights(address(this), LIST_ADMIN), true, "doesn't have rights");
  
  //      Assert.equal(acc0, msg.sender, "!!doesn't have rights");
    //    Assert.equal(acc1, rights.owner(), "!!---doesn't have rights");
      //  Assert.equal(rights.hasRights(acc0, LIST_ADMIN), true, "doesn't have rights");
       // Assert.equal(rights.hasRights(acc0, MONEY_MINTER), true, "doesn't have MINTER rights");
    }

    /// #sender: account-1
    function checkSuccess() public {
        // Use 'Assert' methods: https://remix-ide.readthedocs.io/en/latest/assert_library.html
        console.log("sender -> %s",  msg.sender);
        Assert.ok(msg.sender == acc1, 'caller should be custom account i.e. acc1');
        //rights.setMemberRights(acc0, LIST_ADMIN);
        bool x = rights.hasRights(acc0, LIST_ADMIN);
        Assert.equal(x, true, "doesn't have rights");
        Assert.ok(2 == 2, 'should be true');
        Assert.greaterThan(uint(2), uint(1), "2 should be greater than to 1");
        Assert.lesserThan(uint(2), uint(3), "2 should be lesser than to 3");
    }

    /// #sender: account-0
    function checkSuccess2() public  returns (bool) {
        // Use the return value (true or false) to test the contract
        bool x = rights.hasRights(acc0, LIST_ADMIN);
        Assert.equal(x, true, "doesn't have rights");
        return true;
    }
    
    function checkFailure() public {
        Assert.notEqual(uint(1), uint(1), "1 should not be equal to 1");
    }

    /// Custom Transaction Context: https://remix-ide.readthedocs.io/en/latest/unittesting.html#customization
    /// #sender: account-1
    /// #value: 100
    function checkSenderAndValue() public payable {
        // account index varies 0-9, value is in wei
        Assert.equal(msg.sender, TestsAccounts.getAccount(1), "Invalid sender");
        Assert.equal(msg.value, 100, "Invalid value");
    }
}
    */