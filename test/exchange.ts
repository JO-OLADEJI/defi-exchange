import { expect } from "chai";
import { Contract, BigNumber } from "ethers";
import { ethers } from "hardhat";

describe("Exchange", () => {
  let Exchange: Contract;
  let Bee: Contract;

  beforeEach(async () => {
    const bee = await ethers.getContractFactory("Bee");
    Bee = await bee.deploy();
    await Bee.deployed();
    const exchange = await ethers.getContractFactory("Exchange");
    Exchange = await exchange.deploy(Bee.address);
    await Exchange.deployed();
  });

  describe("constructor", () => {
    it("should set address of erc20 token to value passed at deployment", async () => {
      const erc20TokenAddress = await Exchange.beeToken();
      expect(erc20TokenAddress).to.equal(Bee.address);
    });

    it("should revert if address of erc20 token passed at deployment is null address", async () => {
      const exchange = await ethers.getContractFactory("Exchange");
      await expect(
        exchange.deploy(ethers.constants.AddressZero)
      ).to.be.revertedWith("NULL_TOKEN_ADDRESS");
    });
  });

  describe("getReserve", () => {
    it("should return the balance of contract for the erc20 token", async () => {
      const contractBalanceOfToken: BigNumber = await Bee.balanceOf(
        Exchange.address
      );
      const tokenReserveInContract: BigNumber = await Exchange.getReserve();
      expect(contractBalanceOfToken).to.equal(tokenReserveInContract);
    });
  });
});
