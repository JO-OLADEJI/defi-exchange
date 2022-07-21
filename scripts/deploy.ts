import hre, { ethers } from "hardhat";

const delay = async (seconds: number) => {
  return new Promise((resolve) => setTimeout(resolve, seconds * 1000));
};

const main = async () => {
  const bee = await ethers.getContractFactory("Bee");
  const Bee = await bee.deploy();
  await Bee.deployed();

  const exchange = await ethers.getContractFactory("Exchange");
  const Exchange = await exchange.deploy(Bee.address);
  await Exchange.deployed();

  console.log("Bee token deployed to:", Bee.address);
  console.log("Exchange deployed to:", Exchange.address);

  const delayTime = 60;
  await delay(delayTime);
  console.log(
    `Waiting for ${delayTime} seconds for Etherscan to index contract(s)...`
  );

  hre.run("verify:verify", {
    address: Bee.address,
    contract: "contracts/Bee.sol:Bee",
    constructorArguments: [],
  });

  hre.run("verify:verify", {
    address: Exchange.address,
    contract: "contracts/Exchange.sol:Exchange",
    constructorArguments: [Bee.address],
  });

  process.exitCode = 0;
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
