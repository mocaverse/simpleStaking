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

  const signer = new hre.ethers.Wallet(deployerPrivateKey, hre.ethers.provider);

  const simpleStaking = await hre.ethers.getContractAt("SimpleStaking", stakingAddress, signer);
  const token = await hre.ethers.getContractAt("IERC20", tokenAddress, signer);

  // load csv from file path
  const csvPath = process.env.CSV_PATH;
  const userRecords = await loadCSV(csvPath);

  const executeTime = Date.now();

  console.log(
    "Script started by: ",
    await signer.getAddress(),
    "ETH: ",
    hre.ethers.formatEther(await hre.ethers.provider.getBalance(signer)),
    "token: ",
    hre.ethers.formatEther(await token.balanceOf(await signer.getAddress()))
  );

  await token.approve(stakingAddress, await token.balanceOf(await signer.getAddress()));

  const BATCH_SIZE = 300;
  for (let i = 0; i < userRecords.length; i += BATCH_SIZE) {
    const batch = userRecords.slice(i, i + BATCH_SIZE);
    const addresses = batch.map((record) => record.address);
    const amounts = batch.map((record) => record.amount).map((amount) => (REQUIRE_PARSE ? hre.ethers.parseEther(amount) : amount));

    const writeContent = addresses.map((address, index) => `${address},${amounts[index]}`).join("\n");

    console.log(`Staking from ${i} to ${i + BATCH_SIZE} of ${userRecords.length}`);
    try {
      const gasPrice = (await hre.ethers.provider.getFeeData()).gasPrice;

      const estimatedGas = await simpleStaking.stakeBehalf.estimateGas(addresses, amounts);
      console.log(
        `Current gas price per unit: ${gasPrice} txn gas unit: ${estimatedGas} total cost: ${hre.ethers.formatEther(
          gasPrice * estimatedGas
        )} token: ${hre.ethers.formatEther(await token.balanceOf(await signer.getAddress()))}`
      );
      // currently seems it's callable for owner only
      const txn = await simpleStaking.stakeBehalf(addresses, amounts);
      await txn.wait();
      console.log(`Success, txn hash: ${txn.hash}`);
      fs.appendFileSync(`stake_success_${executeTime}.log`, writeContent + "\n");
    } catch (error) {
      console.warn(error);
      fs.appendFileSync(`stake_error_${executeTime}.log`, writeContent + "\n");
    }
  }

  console.log(
    `Script finished, ETH:  ${hre.ethers.formatEther(await hre.ethers.provider.getBalance(signer))} token: ${await token.balanceOf(
      await signer.getAddress()
    )}`
  );
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
