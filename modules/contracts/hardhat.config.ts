import { MaxUint256 } from "@ethersproject/constants";
import { HardhatUserConfig } from "hardhat/config";

import * as packageJson from "./package.json";

import "@nomiclabs/hardhat-waffle";

const mnemonic =
  process.env.SUGAR_DADDY ??
  process.env.MNEMONIC ??
  "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat";

const config: HardhatUserConfig = {
  paths: {
    sources: "./src.sol",
    tests: "./src.ts",
    artifacts: "./artifacts",
  },
  solidity: {
    version: packageJson.devDependencies.solc,
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  defaultNetwork: "hardhat",
  networks: {
    ganache: {
      chainId: 1337,
      url: "http://localhost:8545",
    },
    hardhat: {
      chainId: 1338,
      loggingEnabled: false,
      accounts: {
        mnemonic,
        accountsBalance: MaxUint256.div(2).toString(),
      },
    },
    matic: {
      chainId: 80001,
      url: "https://rpc-mumbai.matic.today",
      accounts: { mnemonic },
    },
  },
};

export default config;
