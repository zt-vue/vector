import { getEthProvider } from "@connext/vector-utils";
import { EtherSymbol, Zero } from "@ethersproject/constants";
import { providers, utils, Wallet } from "ethers";
import { Argv } from "yargs";

import { AddressBook, getAddressBook } from "../addressBook";
import { cliOpts, logger } from "../constants";

import { deployContracts } from "./deployContracts";
import { registerTransfer } from "./registerTransfer";

const { formatEther } = utils;

export const migrate = async (wallet: Wallet, addressBook: AddressBook, log = logger.child({})): Promise<void> => {
  // Setup env & log initial state
  const chainId = (process?.env?.REAL_CHAIN_ID || (await wallet.provider.getNetwork()).chainId).toString();
  const balance = await wallet.getBalance();
  const nonce = await wallet.getTransactionCount();
  const providerUrl = (wallet.provider as providers.JsonRpcProvider).connection.url;

  log.info(`\nPreparing to migrate contracts to provider ${providerUrl} w chainId: ${chainId}`);
  log.info(`Deployer address=${wallet.address} nonce=${nonce} balance=${formatEther(balance)}`);

  if (balance.eq(Zero)) {
    throw new Error(`Account ${wallet.address} has zero balance on chain ${chainId}, aborting migration`);
  }

  ////////////////////////////////////////
  // Run the migration

  // Don't migrate to mainnet until disputes are working & major vulnerabilities are mitigated
  if (chainId === "1") {
    throw new Error(`Contract migration for chain ${chainId} is not supported yet`);

    // Default: run testnet migration
  } else {
    await deployContracts(
      wallet,
      addressBook,
      [
        ["TestToken", []],
        ["ChannelMastercopy", []],
        ["ChannelFactory", ["ChannelMastercopy"]],
        ["HashlockTransfer", []],
        ["Withdraw", []],
        ["TransferRegistry", []],
      ],
      log,
    );
    await registerTransfer("Withdraw", wallet, addressBook, log);
    await registerTransfer("HashlockTransfer", wallet, addressBook, log);
  }

  ////////////////////////////////////////
  // Print summary
  log.info("\nAll done!");
  const spent = formatEther(balance.sub(await wallet.getBalance()));
  const nTx = (await wallet.getTransactionCount()) - nonce;
  log.info(`Sent ${nTx} transaction${nTx === 1 ? "" : "s"} & spent ${EtherSymbol} ${spent}`);
};

export const migrateCommand = {
  command: "migrate",
  describe: "Migrate contracts",
  builder: (yargs: Argv): Argv => {
    return yargs
      .option("a", cliOpts.addressBook)
      .option("m", cliOpts.mnemonic)
      .option("p", cliOpts.ethProvider)
      .option("s", cliOpts.silent);
  },
  handler: async (argv: { [key: string]: any } & Argv["argv"]): Promise<void> => {
    const wallet = Wallet.fromMnemonic(argv.mnemonic).connect(getEthProvider(argv.ethProvider));
    const addressBook = getAddressBook(
      argv.addressBook,
      process?.env?.REAL_CHAIN_ID || (await wallet.provider.getNetwork()).chainId.toString(),
    );
    const level = argv.silent ? "silent" : "info";
    await migrate(wallet, addressBook, logger.child({ level }));
  },
};
