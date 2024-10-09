// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.

// ~/Downloads/ganache-2.7.1-linux-x86_64.AppImage
//Start node `npx hardhat node`
//Compile `npx hardhat compile`
//Deploy `npx hardhat run scripts/deploy.js --network localhost`
//Deploy `npx hardhat run scripts/deploy.js --network testbnb`

const fs = require("fs");
const hre = require("hardhat");

const fileNameLocal = "./addresses/localhost.json";

const spawn = require("child_process").spawn;

async function main() {
  let params = [
    60 * 60,
    1,
    20,
    "0x0C06C8d3720de21F0dd1D6DEF2f6f8dcB2CFE0BE",
    "0xe1decF69818671FaD8084CB966F9730014A93273",
    "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
    60 * 5,
  ];
  const jack = await hre.ethers.deployContract("JackStaking", params);

  await jack.waitForDeployment();

  console.log(`JackStaking deployed to ${jack.target}`);
  let addr = { address: jack.target };
  let fileName = fileNameLocal;



  fs.writeFile(fileName, JSON.stringify(addr), function writeJSON(err) {
    if (err) return console.log(err);
    console.log(addr);
    console.log("writing to " + fileName);
  });

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
