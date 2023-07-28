require("dotenv").config();

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("solidity-coverage");

console.log("Network: ", process.env.DEFAULT_NETWORK || "ganacheLocal");

module.exports = {
  defaultNetwork: process.env.DEFAULT_NETWORK || "ganacheLocal",
  networks: {
    hardhat: {
      chainId: 1337,
      initialBaseFeePerGas: 0,
    },
    ganacheLocal: {
      url: "http://localhost:8545/ganache",
      accounts: process.env.PRIVATE_KEYS.split(","),
      initialBaseFeePerGas: 0,
    },
    ganacheDev: {
      url: "http://10.60.0.58:8545/ganache",
      accounts: process.env.PRIVATE_KEYS.split(","),
      initialBaseFeePerGas: 0,
    },
    sepolia: {
      url: "https://sepolia.infura.io/v3/5392858ad7a14fb58e4cbcdebe6388fd",
    },
  },
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};
