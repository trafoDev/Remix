
var mainAcounts;

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

export async function main1() {
try {
  mainAcounts = await web3.eth.getAccounts();
  let contractMR = await deploy('MembershipRights', 10);
  let cashToken = await deploy('CashToken', 10, contractMR.address);
  let baseBond = await deploy('BaseBond', 10);
  let factory = await deploy('Factory', 10, baseBond.address, contractMR.address, cashToken.address);

  //Wszyscy userzy - all rights
  await contractMR.setMemberRights(mainAcounts[0], 0xff);
  await contractMR.setMemberRights(mainAcounts[1], 0xff);
  await contractMR.setMemberRights(mainAcounts[2], 0xff);
  await contractMR.setMemberRights(mainAcounts[3], 0xff);
  await contractMR.setMemberRights(mainAcounts[4], 0xff);

  await contractMR.setMemberRights(mainAcounts[10], 0xff);

  //User0 wydobywa kasę - wszyscy 1000,00
  let cashToken0 = await swapContractSigner(cashToken, 0);
  await cashToken0.mint(mainAcounts[0], 100000);
  await cashToken0.mint(mainAcounts[1], 100000);
  await cashToken0.mint(mainAcounts[2], 100000);
  await cashToken0.mint(mainAcounts[3], 100000);
  await cashToken0.mint(mainAcounts[4], 100000);

  //Issue bonds
  await factory.createChild("Obligacja 1", "OB1");
  await factory.createChild("Obligacja 2", "OB2");
  await factory.createChild("Obligacja 3", "OB3");
  await factory.createChild("Obligacja 4", "OB4");
  await factory.createChild("Obligacja 5", "OB5");
  let bonds = await factory.getChildren()

  //Identiry firsr
  let o0 = await attach('BaseBond', bonds[0], 10);
  let o1 = await attach('BaseBond', bonds[1], 10);
  let o2 = await attach('BaseBond', bonds[2], 10);
  let o3 = await attach('BaseBond', bonds[3], 10);
  let o4 = await attach('BaseBond', bonds[4], 10);
  

  //user 0 kuuje 100 obligacji
  let o0_0 = await swapContractSigner(o0, 0);
  //await o0_0.issue(100);
  await cashToken0.approve(o0_0.address, 10000000);
  await o0_0.issue(9);

//  console.log('qqqqqqqqqq:' +   o1.address);
  console.log('qqqqqqqqqq:' +   await o4.name());



   } catch (e) {
    console.log("err")
    console.log(e.message)
  }
}

//main1();