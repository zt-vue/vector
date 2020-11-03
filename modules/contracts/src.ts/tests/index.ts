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

    const mocha = new Mocha({
      timeout: 60000,
      globals: ["SUGAR_DADDY", "ETH_PROVIDER_URL"],
    });

    (mocha as any).globalSetup(() => {
      (global as any).SUGAR_DADDY = argv.mnemonic;
      (global as any).ETH_PROVIDER_URL = argv.ethProvider;
    });

    // Global setup needs to be run before loading any files
    // bc some files try to read from global vars while loading
    await (mocha as any).runGlobalSetup();

    const getFilesFromDir = (dir: string, fileTypes: string[]): string[] =>  {
      const filesToReturn: string[] = [];
      const walkDir = (currentPath: string): void => {
        for (const file of fs.readdirSync(currentPath)) {
          const curFile = path.join(currentPath, file);
          if (
            fs.statSync(curFile).isFile() &&
            fileTypes.some((ft: string) => curFile.endsWith(ft))
          ) {
            filesToReturn.push(curFile);
          } else if (fs.statSync(curFile).isDirectory()) {
           walkDir(curFile);
          }
        }
      };
      walkDir(dir);
      return filesToReturn;
    };
    getFilesFromDir("src.ts", [".spec.ts"]).forEach((f: string) => mocha.addFile(f));

    // Run the tests.
    mocha.run((failures: any) => {
      process.exitCode = failures ? 1 : 0;  // exit with non-zero status if there were failures
    });
  },
};
