import { ethers } from "hardhat";

const main = async () => {
  const bee = await ethers.getContractFactory("Bee");
  const Bee = await bee.deploy();
  await Bee.deployed();

  const exchange = await ethers.getContractFactory("Exchange");
  const Exchange = await exchange.deploy(Bee.address);
  await Exchange.deployed();

  console.log("Bee token deployed to:", Bee.address);
  console.log("Exchange deployed to:", Exchange.address);
  process.exitCode = 0;
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
