// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

const honorTicket = require("../../contracts.json").HonorTicket;

async function main() {


    const honorLottery = await hre.ethers.deployContract("HonorLottery",[honorTicket]);

    await honorLottery.waitForDeployment();
    const contractAddress= await honorLottery.getAddress()
  console.log(contractAddress);
  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main();
