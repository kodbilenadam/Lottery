const hre = require("hardhat");
const fs = require("fs");
const contracts = require("../contracts.json");
const { parse } = require("path");

async function main() {
  // Load the Ethereum provider and get the network
  const { ethers } = hre;

  // Load the FixedStaking contract
  const fixedStakingContract = await ethers.getContractAt(
    "FixedStaking",
    contracts.FixedStaking
  );

  // Get the total number of farms
  const allFarmsLength = await fixedStakingContract.getAllFarmsLength();
  console.log("Total number of farms:", allFarmsLength.toString());

  const farmsList = [];

  if (allFarmsLength > 0) {
    console.log("List of all farms:");

    for (let farmID = 0; farmID < allFarmsLength; farmID++) {
      const farm = await fixedStakingContract.getFarm(farmID);

      const stakeToken0 = farm[0];
      const stakeToken1 = "";
      const rewardToken = farm[1];
      const rewardAmount = farm[2];
      const isLPFarm = stakeToken1 !== ""; // Check if it's an LP farm based on stakeToken1
      const lpTokenName = isLPFarm ? "LP Token" : "Single Token";

      const farmObject = {
        farmID: farmID,
        stakeToken0: stakeToken0,
        stakeToken1: stakeToken1,
        rewardToken: rewardToken,
        rewardAmount: rewardAmount,
        isLPFarm: isLPFarm,
        lpTokenName: lpTokenName,
      };

      farmsList.push(farmObject);

      console.log(`Farm ${farmID + 1}:`);
      console.log("Stake Token 0:", stakeToken0);
      console.log("Stake Token 1:", stakeToken1);
      console.log("Reward Token:", rewardToken);
      console.log("Reward Amount:", rewardAmount);
      console.log("Is LP Farm:", isLPFarm);
      console.log("LP Token Name:", lpTokenName);
      console.log("------------------------");
    }
  } else {
    console.log("No farms found.");
  }

  // Output farmsList
  console.log("Farms List:", farmsList);
}

// Execute the script
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
