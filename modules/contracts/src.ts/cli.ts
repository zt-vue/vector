import yargs from "yargs";

import { migrateCommand, registerTransferCommand } from "./actions";
import { testCommand } from "./tests";

yargs
  .command(migrateCommand)
  .command(registerTransferCommand)
  .command(testCommand)
  .demandCommand(1, "Choose a command from the above list")
  .help().argv;
