require("@nomicfoundation/hardhat-toolbox");
const {privateKey} = require("./secrets.json");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.5.16",
      },
      {
        version: "0.8.19",
        
      },
    ],
    
  },
  defaultNetwork: "localhost",
  networks: {
     // Varsayılan ağı localhost olarak ayarlayın
    hardhat: {
      forking: {
        url: "https://bsc.nodereal.io",
      }    
    },
    localhost: {
      url: "http://127.0.0.1:8545", // localhost ağının URL'sini burada belirtin
    },
    testnet: {
      url: "https://bsc-testnet.nodereal.io/v1/6e51276d312a4f698b27907f87738d87",
      chainId: 97,
      accounts:[privateKey]
    }
  },
  etherscan: {
    apiKey: "WUZCWJ657G2GHFNXZ9H7K9NCUI89HVQI6F",
 }
};