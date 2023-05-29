
var mainAcounts;
var bonds;

var envConfig;
var cashToken, cashToken0, cashToken1, cashToken2;
var baseBond; 
var bond0, bond0_0, bond0_1, bond0_2;
var bond1, bond1_0, bond1_1, bond1_2;
var bond2, bond2_0, bond2_1, bond2_2;
var bond3, bond3_0, bond3_1, bond3_2;
var bond4, bond4_0, bond4_1, bond4_2;
var factory;
var table, table0, table1, table2;

async function swapContractSigner(contract, accountNr) {
  try {
    // the variable web3Provider is a remix global variable object
    const signer = (new ethers.providers.Web3Provider(web3Provider)).getSigner(accountNr)
    let newContract = await contract.connect(signer);
    console.log('contract signer swapped')
    return newContract;
  } catch (e) {
    console.log(e.message)
  }
}

async function deploy(contractName, accountNr, ...arg1) {
try {
    console.log('deploying contracy: ' +contractName);
    const metadata = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/'+contractName+'.json'))
    // the variable web3Provider is a remix global variable object
    const signer = (new ethers.providers.Web3Provider(web3Provider)).getSigner(accountNr)
    // Create an instance of a Contract Factory
    let factory = new ethers.ContractFactory(metadata.abi, metadata.data.bytecode.object, signer);
    // Notice we pass the constructor's parameters here
    let contract = await factory.deploy(...arg1); 
    // The transaction that was sent to the network to deploy the Contract
    console.log('Tx: '+contract.deployTransaction.hash);
    // The contract is NOT deployed yet; we must wait until it is mined
    await contract.deployed()
    // Done! The contract is deployed.
    console.log('contract deployed: ' + contract.address)
//    var accounts = await web3.eth.getAccounts();
/*
    console.log(accounts);
    console.log(await contract.owner());
    console.log(await contract.getRights(accounts[1]));
    contract = await swapContractSigner(contract, 2);
    console.log(await contract.getRights(accounts[2]));
//  console.log(cn)
*/
    return contract;
  } catch (e) {
    console.log("err")
    console.log(e.message)
  }
}


async function attach(contractName, contractAddress, accountNr) {
try {
    console.log('Attaching contract: ' +contractName);
    const metadata = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/'+contractName+'.json'))
    // the variable web3Provider is a remix global variable object
    const signer = (new ethers.providers.Web3Provider(web3Provider)).getSigner(accountNr)
    // Create an instance of a Contract Factory
    let factory = new ethers.ContractFactory(metadata.abi, metadata.data.bytecode.object, signer);
    // Notice we pass the constructor's parameters here
    let contract = factory.attach(contractAddress); 
    // The transaction that was sent to the network to deploy the Contract
    console.log('contract Attached: ' + contract.address)
//    var accounts = await web3.eth.getAccounts();
/*
    console.log(accounts);
    console.log(await contract.owner());
    console.log(await contract.getRights(accounts[1]));
    contract = await swapContractSigner(contract, 2);
    console.log(await contract.getRights(accounts[2]));
//  console.log(cn)
*/
    return contract;
  } catch (e) {
    console.log("err")
    console.log(e.message)
  }
}

async function setup() {
  try {
    mainAcounts = await web3.eth.getAccounts();
    envConfig = await deploy('EnvironmentConfig', 10);
    cashToken = await deploy('CashToken', 10, envConfig.address);
    baseBond = await deploy('BaseBondToken', 10);
    factory = await deploy('BondFactory', 10, baseBond.address, envConfig.address, cashToken.address);
    table = await deploy('OfferTable', 10);

    //Wszyscy userzy - all rights
    await envConfig.setMemberRights(mainAcounts[0], 0xff);
    await envConfig.setMemberRights(mainAcounts[1], 0xff);
    await envConfig.setMemberRights(mainAcounts[2], 0xff);
    await envConfig.setMemberRights(mainAcounts[3], 0xff);
    await envConfig.setMemberRights(mainAcounts[4], 0xff);

    await envConfig.setMemberRights(mainAcounts[10], 0xff);

    //User0 wydobywa kasę - wszyscy 1000,00
    cashToken0 = await swapContractSigner(cashToken, 0);
    await cashToken0.mint(mainAcounts[0], 10000000);
    await cashToken0.mint(mainAcounts[1], 10000000);
    await cashToken0.mint(mainAcounts[2], 10000000);
    await cashToken0.mint(mainAcounts[3], 10000000);
    await cashToken0.mint(mainAcounts[4], 10000000);
    cashToken1 = await swapContractSigner(cashToken, 1);

    //Issue bonds
    await factory.createChild("Obligacja 1", "OB1");
    await factory.createChild("Obligacja 2", "OB2");
    await factory.createChild("Obligacja 3", "OB3");
    await factory.createChild("Obligacja 4", "OB4");
    await factory.createChild("Obligacja 5", "OB5");
    bonds = await factory.getChildren()

    //Identiry firsr
    bond0 = await attach('BaseBondToken', bonds[0], 10);
    bond1 = await attach('BaseBondToken', bonds[1], 10);
    bond2 = await attach('BaseBondToken', bonds[2], 10);
    bond3 = await attach('BaseBondToken', bonds[3], 10);
    bond4 = await attach('BaseBondToken', bonds[4], 10);

    //oznacz platformę jako uprawnioną
    await envConfig.setMemberRights(table.address, 0xff);

    //register table to Oblig
    await bond0.addPatform(table.address);
    await bond1.addPatform(table.address);
    await bond2.addPatform(table.address);
    await bond3.addPatform(table.address);
    await bond4.addPatform(table.address);

    console.log("Setup completed.")

  } catch (e) {
    console.log("err")
    console.log(e.message)
  }
}
 
async function test1() {

try {
  //user 0 kuuje 100 obligacji
  bond0_0 = await swapContractSigner(bond0, 0);
  table0 = await swapContractSigner(table, 0);
  table1 = await swapContractSigner(table, 1);

  //await bond0_0.issue(100);
  await cashToken0.approve(bond0_0.address, 10000000);

  await envConfig.setCurrentDate(20230529);
//  console.log ("Now: ", (await envConfig.getCurrentDate()).toString()); 

  await bond0_0.issue(9);
  await envConfig.setCurrentDate(20230530);
//  await envConfig.setNow(0);

//nowa oferta
  //let table0 = await swapContractSigner(table, 0);
  //await table0.newOffer(bond0_0.address, 20230527, 10);
  console.log("ssssssss: "+table.address);
  console.log("ssssssss: "+bond0_0.address);
  var off = await bond0_0.makeOffer(table.address, 20230529, 5, 50000);
  console.log(off.toString());
  console.log("-->" + await bond0_0.allowance(mainAcounts[0], table.address));
  console.log("==>" + await bond0_0.balanceOf(mainAcounts[0]));
  console.log("offer nr: " + await bond0_0.makeOffer(table.address, 20230529, 3, 30000));
  console.log("-->" + await bond0_0.allowance(mainAcounts[0], table.address));
  console.log("==>" + await bond0_0.balanceOf(mainAcounts[0]));
  await bond0_0.canceleOffer1(table.address, 2);
  console.log("-->" + await bond0_0.allowance(mainAcounts[0], table.address));
  console.log("==>" + await bond0_0.balanceOf(mainAcounts[0]));


  //sprawdzam allowance
  await cashToken1.approve(table.address, 100000);
  console.log("==>" + await cashToken.balanceOf(mainAcounts[0]));
  console.log("==>" + await cashToken.balanceOf(mainAcounts[1]));
  //await bond0_0.allowance(from, table0)
  await table1.finalizeOffer(1, cashToken.address);
  console.log("-->" + await bond0_0.allowance(mainAcounts[0], table.address));
  console.log("==>" + await bond0_0.balanceOf(mainAcounts[0]));
  console.log("==>" + await bond0_0.balanceOf(mainAcounts[1]));
  console.log("==>" + await cashToken.balanceOf(mainAcounts[0]));
  console.log("==>" + await cashToken.balanceOf(mainAcounts[1]));
  
//  console.log("-->" + await bond0_0.makeOffer(table.address, 20230527, 5));
  await cashToken.approve(bond0_0.address, 10000000);
  await bond0_0.redemption(20230529, 1);
  console.log("==>" + await bond0_0.balanceOf(mainAcounts[0]));
  console.log("==>" + await cashToken.balanceOf(mainAcounts[0]));
  console.log("=======================================");
  await bond0.coupon();
  console.log("==>" + await bond0_0.balanceOf(mainAcounts[0]));
  console.log("==>" + await bond0_0.balanceOf(mainAcounts[1]));
  console.log("==>" + await cashToken.balanceOf(mainAcounts[0]));
  console.log("==>" + await cashToken.balanceOf(mainAcounts[1]));
  console.log("=======================================");

    console.log("==>" + (await table.getOffers()).toString());
//  console.log('qqqqqqqqqq:' +   o1.address);
  console.log('qqqqqqqqqq:' +   await bond4.name());



   } catch (e) {
    console.log("err")
    console.log(e.message)
  }
}

async function main() {
  await setup();
 // await init()
 await test1();
}

main();