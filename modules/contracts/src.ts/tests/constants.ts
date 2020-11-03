import { utils, Wallet, providers } from "ethers";
import { waffle } from "hardhat";

// Get defaults from global or env
const providerUrl = (global as any).ETH_PROVIDER_URL || process.env.ETH_PROVIDER_URL;
const mnemonic = (global as any).SUGAR_DADDY
  || process.env.SUGAR_DADDY!
  || "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat";

console.log(`global.ETH_PROVIDER_URL = ${(global as any).ETH_PROVIDER_URL}`);

export const provider = providerUrl
  ? new providers.JsonRpcProvider(providerUrl as string)
  : waffle.provider;

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
