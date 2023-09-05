require("dotenv").config();

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");

const DEFAULT_NETWORK = process.env.DEFAULT_NETWORK || "ganache";

// Ether scan
const ETHER_SCAN_API_KEY = process.env.ETHER_SCAN_API_KEY;

// Ganache
const GANACHE_URL = process.env.GANACHE_URL || "http://localhost:8545/ganache";
const GANACHE_PRIVATE_KEYS = process.env.GANACHE_PRIVATE_KEYS.split(",");

// Sepolia
const SEPOLIA_URL = process.env.SEPOLIA_URL;
const SEPOLIA_PRIVATE_KEYS = process.env.SEPOLIA_PRIVATE_KEYS.split(",");

const GOERLI_URL = process.env.GOERLI_URL;
const GOERLI_PRIVATE_KEYS = process.env.GOERLI_PRIVATE_KEYS.split(",");

console.log("Network: ", process.env.DEFAULT_NETWORK || "ganache");

module.exports = {
  defaultNetwork: DEFAULT_NETWORK,
  networks: {
    hardhat: {
      chainId: 1337,
    },
    ganache: {
      url: GANACHE_URL,
      accounts: GANACHE_PRIVATE_KEYS,
    },
    sepolia: {
      url: SEPOLIA_URL,
      accounts: SEPOLIA_PRIVATE_KEYS,
    },
    goerli: {
      url: GOERLI_URL,
      accounts: GOERLI_PRIVATE_KEYS,
    },
  },
  etherscan: {
    apiKey: ETHER_SCAN_API_KEY,
  },
  solidity: {
    version: "0.8.18",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};
