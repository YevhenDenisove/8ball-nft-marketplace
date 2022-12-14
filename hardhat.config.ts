import "@nomicfoundation/hardhat-toolbox";
import '@openzeppelin/hardhat-upgrades';

import "dotenv/config";

import "./tasks";

const accounts = [process.env.PRIVATE_KEY];
const networks = {
  avalanche: { url: 'https://ava-mainnet.public.blastapi.io/ext/bc/C/rpc', chainId: 43114 },
  avalancheFujiTestnet: { url: 'https://api.avax-test.network/ext/bc/C/rpc', chainId: 43113 },
}

module.exports = {
  solidity: {
    compilers: ["0.8.16", "0.8.9", "0.8.2", "0.6.0"].map(version => ({
      version,
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    })),
  },
  networks: Object.entries(networks).reduce((o, [network, config]) => {
    o[network] = { ...config, accounts };
    return o;
  }, {} as any),
  etherscan: {
    apiKey: {
      avalanche: process.env.SNOWTRACE_API_KEY,
      avalancheFujiTestnet: process.env.SNOWTRACE_API_KEY
    },
  }
};
