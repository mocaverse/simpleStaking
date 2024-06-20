const hre = require("hardhat");
const fs = require("fs");
const csv = require("csv-parse");

const ethereumMulticall = require("ethereum-multicall");

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

const GET_USER_ABI = {
  inputs: [
    {
      internalType: "address",
      name: "user",
      type: "address",
    },
  ],
  name: "getUser",
  outputs: [
    {
      components: [
        {
          internalType: "uint256",
          name: "amount",
          type: "uint256",
        },
        {
          internalType: "uint256",
          name: "cumulativeWeight",
          type: "uint256",
        },
        {
          internalType: "uint256",
          name: "lastUpdateTimestamp",
          type: "uint256",
        },
      ],
      internalType: "struct SimpleStaking.Data",
      name: "",
      type: "tuple",
    },
  ],
  stateMutability: "view",
  type: "function",
};

async function validateAllRecords(addresses, expectedAmounts, simpleStaking) {
  if (addresses.length !== expectedAmounts.length) {
    throw new Error("Addresses and amounts length do not match");
  }

  const multicall = new ethereumMulticall.Multicall({
    multicallCustomContractAddress: "0xcA11bde05977b3631167028862bE2a173976CA11",
    nodeUrl: process.env.RPC_URL,
    tryAggregate: true,
  });

  const calls = addresses.map((address) => {
    return { reference: address, methodName: "getUser", methodParameters: [address] };
  });

  const contractCallContext = [
    {
      reference: "SimpleStaking",
      contractAddress: await simpleStaking.getAddress(),
      abi: [GET_USER_ABI],
      calls: calls,
    },
  ];

  const { results } = await multicall.call(contractCallContext);

  const failedCalls = results.SimpleStaking.callsReturnContext.filter((call) => !call.success);

  if (failedCalls.length > 0) {
    console.warn("Failed calls:", failedCalls);
  }

  const amounts = results.SimpleStaking.callsReturnContext.map((call) => hre.ethers.formatEther(BigInt(call.returnValues[0].hex)));

  await amounts.forEach((amount, i) => {
    if (expectedAmounts[i] != amount) {
      console.warn(`${addresses[i]} expected amount ${expectedAmounts[i]} does not match the staking contract data ${amount}`);
      throw `Amounts do not match for ${addresses[i]} expected ${expectedAmounts[i]} got ${amount}`;
    }
  });

  return true;
}

async function run(batchSize = 500, startAt = 0, endAt = 0) {
  const deployerPrivateKey = process.env.PRIVATE_KEY;
  const stakingAddress = process.env.STAKING_CONTRACT;
  const tokenAddress = process.env.TOKEN_CONTRACT;

  const signer = new hre.ethers.Wallet(deployerPrivateKey, hre.ethers.provider);

  const simpleStaking = await hre.ethers.getContractAt("SimpleStaking", stakingAddress, signer);
  const token = await hre.ethers.getContractAt("IERC20", tokenAddress, signer);

  const isPaused = await simpleStaking.paused();

  if (isPaused) {
    console.error("Contract is paused, unable to stake");
    return;
  }

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

  const end = endAt === 0 ? userRecords.length : endAt;

  // do convertion all at once in begining
  const allAddresses = userRecords.map((record) => record.address);
  const allAmounts = userRecords.map((record) => record.amount).map((amount) => (REQUIRE_PARSE ? hre.ethers.parseEther(amount) : amount));

  // const expectedAmounts = new Array(end - startAt).fill(0);
  // await validateAllRecords(allAddresses.slice(startAt, end), expectedAmounts, simpleStaking);

  for (let i = startAt; i < end; i += batchSize) {
    const addresses = allAddresses.slice(i, i + batchSize);
    const amounts = allAmounts.slice(i, i + batchSize);

    // validate the batch records are 0 before staking
    const expectedAmounts = new Array(amounts.length).fill(0);
    await validateAllRecords(addresses, expectedAmounts, simpleStaking);

    const writeContent = addresses.map((address, index) => `${address},${amounts[index]}`).join("\n");

    console.log(`Staking from ${i} to ${i + batchSize} of ${userRecords.length}`);
    try {
      const gasPrice = (await hre.ethers.provider.getFeeData()).gasPrice;

      const estimatedGas = await simpleStaking.stakeBehalf.estimateGas(addresses, amounts);
      console.log(
        `Current gas price per unit: ${hre.ethers.formatUnits(gasPrice, "gwei")} txn gas unit: ${estimatedGas} total cost: ${hre.ethers.formatEther(
          gasPrice * estimatedGas
        )} token: ${hre.ethers.formatEther(await token.balanceOf(await signer.getAddress()))}`
      );

      const txn = await simpleStaking.stakeBehalf(addresses, amounts);
      await txn.wait();
      console.log(`Success, txn hash: ${txn.hash}`);
      fs.appendFileSync(`stake_success_${executeTime}.log`, writeContent + "\n");
    } catch (error) {
      console.warn(error);
      fs.appendFileSync(`stake_error_${executeTime}.log`, writeContent + "\n");
    }
  }

  await validateAllRecords(
    userRecords.map((u) => u.address),
    userRecords.map((u) => u.amount),
    simpleStaking
  );

  console.log(
    `Script finished, ETH:  ${hre.ethers.formatEther(await hre.ethers.provider.getBalance(signer))} token: ${hre.ethers.formatEther(
      await token.balanceOf(await signer.getAddress())
    )}`
  );
}

const BATCH_SIZE = 500;

run(BATCH_SIZE, 0, 0).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
