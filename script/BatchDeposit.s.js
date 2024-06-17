const hre = require("hardhat");
const fs = require("fs");
const csv = require("csv-parse");

const REQUIRE_PARSE = true;

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

  const token = await hre.ethers.getContractAt("IERC20", tokenAddress);

  // load csv from file path
  const csvPath = process.env.CSV_PATH;
  const userRecords = await loadCSV(csvPath);

  const signer = new hre.ethers.Wallet(deployerPrivateKey, hre.ethers.provider);

  console.log("Script started by: ", await signer.getAddress(), "Balance: ", hre.ethers.formatEther(await hre.ethers.provider.getBalance(signer)));

  await token.approve(stakingAddress, await token.balanceOf(await signer.getAddress()));

  // get the first 10 records and stake them
  const BATCH_SIZE = 1;
  for (let i = 0; i < userRecords.length; i += BATCH_SIZE) {
    const batch = userRecords.slice(i, i + BATCH_SIZE);
    const addresses = batch.map((record) => record.address);
    const amounts = batch.map((record) => record.amount).map((amount) => (REQUIRE_PARSE ? hre.ethers.parseEther(amount) : amount));

    console.log(`Staking ${addresses}`);
    try {
      // currently seems it's callable for owner only
      const txn = await simpleStaking.stakeBehalf(addresses, amounts);
      await txn.wait();
      fs.appendFileSync("stake_result.log", `${addresses},${amounts}, success\n`);
    } catch (error) {
      console.warn(error);
      fs.appendFileSync("stake_result.log", `${addresses},${amounts}, failed: ${error}\n`);
    }
  }

  console.log("Script finished, Balance: ", hre.ethers.formatEther(await hre.ethers.provider.getBalance(signer)));
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
