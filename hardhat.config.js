require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-foundry");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",

  networks: {
    hardhat: {
      chainId: 1337,
      forking: {
        url: "https://sepolia.infura.io/v3/fc2c3ee84563426590136edf651ad478",
        enabled: true,
      },
    },
    ethereum: {
      url: "https://mainnet.infura.io/v3/fc2c3ee84563426590136edf651ad478",
      gasPrice: 10000000000, //10 gwei
    },
    base: {
      url: "https://base-mainnet.infura.io/v3/fc2c3ee84563426590136edf651ad478",
    },
    sepolia: {
      url: "https://sepolia.infura.io/v3/fc2c3ee84563426590136edf651ad478",
      gasPrice: 1000000000, //1 gwei
    },
  },
};
