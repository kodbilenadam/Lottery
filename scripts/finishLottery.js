// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const fs = require("fs");
const contracts = require("../contracts.json");
const { parse } = require("path");

const test = {

}
async function deployContracts() {
  if (contracts.deployed) {
    test.testUSDT = await hre.ethers.getContractAt("TestUSDT", contracts.testUSDT);
    test.honorTicket = await hre.ethers.getContractAt("HonorTicket", contracts.honorTicket);
    test.honorLottery = await hre.ethers.getContractAt("HonorLottery", contracts.honorLottery);
    test.winManager = await hre.ethers.getContractAt("HnrLotoWinManager",contracts.winManager);
  }
  else {
    const testUSDT = await hre.ethers.deployContract("TestUSDT");

    await testUSDT.waitForDeployment();


    const honorTicket = await hre.ethers.deployContract("HonorTicket");

    await honorTicket.waitForDeployment();

    const ticketAddress = await honorTicket.getAddress();

    const honorLottery = await hre.ethers.deployContract("HonorLottery", [ticketAddress]);

    await honorLottery.waitForDeployment();

    
    const file = {};
    file.testUSDT = await testUSDT.getAddress();
    file.honorTicket = await honorTicket.getAddress();
    file.honorLottery = await honorLottery.getAddress();
    file.deployed = true;

    const winManager = await hre.ethers.deployContract("HnrLotoWinManager",[file.honorLottery]);
    await winManager.waitForDeployment();

    file.winManager = await winManager.getAddress();

    await honorTicket.setTicketAdmin(file.honorLottery,true);

    await testUSDT.approve(file.honorLottery, hre.ethers.parseEther("1000000000"));
    fs.writeFileSync("contracts.json", JSON.stringify(file, null, 2))
  }

}



async function main() {

  await deployContracts();


    await test.honorLottery.finishLottery(0);

 
  //await test.honorLottery.finishLottery(0);
  const val =  await test.honorLottery.lotteries(0);

  console.log(val);
  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main();
