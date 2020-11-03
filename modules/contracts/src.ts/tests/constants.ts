import { utils, Wallet, providers } from "ethers";
import * as hardhat from "hardhat";

// Get defaults from global or env
const providerUrl = ETH_PROVIDER_URL || process.env.ETH_PROVIDER_URL;
const mnemonic = SUGAR_DADDY || process.env.SUGAR_DADDY!;

export const provider = providerUrl
  ? new providers.JsonRpcProvider(providerUrl as string)
  : hardhat.waffle.provider;

const hdNode = utils.HDNode.fromMnemonic(mnemonic).derivePath("m/44'/60'/0'/0");
export const wallets: Wallet[] = Array(20)
  .fill(0)
  .map((_, idx) => {
    const wallet = new Wallet(hdNode.derivePath(idx.toString()).privateKey, provider);
    return wallet;
  });

export const chainIdReq = provider.getNetwork().then(net => net.chainId);
export const alice = wallets[0];
export const bob = wallets[1];
export const rando = wallets[2];
