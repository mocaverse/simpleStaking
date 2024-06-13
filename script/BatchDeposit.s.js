const hre = require("hardhat");
const fs = require("fs");
const csv = require("csv-parser");

async function loadCSV(filePath) {
  const results = [];

  return new Promise((resolve, reject) => {
    fs.createReadStream(filePath)
      .pipe(
        csv.parse({
          delimiter: ",",
          columns: true,
          ltrim: true,
        })
      )
      .on("data", (data) => results.push(data))
      .on("end", () => {
        resolve(results);
      })
      .on("error", reject);
  });
}

async function run() {
  const deployerPrivateKey = process.env.PRIVATE_KEY;
  const stakingAddress = process.env.STAKING_CONTRACT;
  const tokenAddress = process.env.TOKEN_CONTRACT;

  const SimpleStaking = await hre.ethers.getContractFactory("SimpleStaking");
  const simpleStaking = await SimpleStaking.attach(stakingAddress);

  const Token = await hre.ethers.getContractFactory("ERC20");
  const token = await Token.attach(tokenAddress);

  // load csv from file path
  const csvPath = process.env.CSV_PATH;
  const userRecords = await loadCSV(csvPath);

  const signer = new hre.ethers.Wallet(deployerPrivateKey, hre.ethers.provider);

  console.log("Script starteed by: ", await signer.getAddress(), "Balance: ", hre.ethers.utils.formatEther(await signer.getBalance()));

  await token.approve(stakingAddress, await token.balanceOf(await signer.getAddress()));

  for (let i = 0; i < userRecords.length; i++) {
    try {
      const { recipient, amount } = userRecords[i];
      const txn = await simpleStaking.stakeBehalf(recipient, amount);
      await txn.wait();
      fs.appendFileSync("stake_result.log", `${recipient},${amount}, success\n`);
    } catch (error) {
      fs.appendFileSync("stake_result.log", `${recipient},${amount}, failed: ${error}\n`);
    }
  }

  console.log("Script finished, Balance: ", hre.ethers.utils.formatEther(await signer.getBalance()));
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
