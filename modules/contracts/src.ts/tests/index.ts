import * as fs from "fs";
import * as path from "path";

import Mocha from "mocha";
import { Argv } from "yargs";

import { cliOpts } from "../constants";

export * from "./constants";
export * from "./utils";

// https://github.com/mochajs/mocha/wiki/Using-mocha-programmatically

export const testCommand = {
  command: "test",
  describe: "Test contracts",
  builder: (yargs: Argv): Argv => {
    return yargs
      .option("m", cliOpts.mnemonic)
      .option("p", cliOpts.ethProvider)
      .option("s", cliOpts.silent);
  },
  handler: async (argv: { [key: string]: any } & Argv["argv"]): Promise<void> => {

    SUGAR_DADDY = argv.mnemonic;
    ETH_PROVIDER_URL = argv.ethProvider;

    const mocha = new Mocha({
      timeout: 60000,
      globals: ["SUGAR_DADDY", "ETH_PROVIDER_URL"],
    });

    // Add each test file to the mocha instance
    const testDir = "src.ts";
    fs.readdirSync(testDir).filter(function(file) {
      return file.substr(-3) === ".spec.ts";
    }).forEach(function(file) {
      mocha.addFile(path.join(testDir, file));
    });

    // Run the tests.
    mocha.run((failures: any) => {
      process.exitCode = failures ? 1 : 0;  // exit with non-zero status if there were failures
    });
  },
};
