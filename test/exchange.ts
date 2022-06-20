import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract, BigNumber } from "ethers";
import { ethers } from "hardhat";

describe("Exchange", () => {
  let Exchange: Contract;
  let Bee: Contract;
  let addr1: SignerWithAddress;
  // eslint-disable-next-line no-unused-vars
  let addr2: SignerWithAddress;

  beforeEach(async () => {
    [addr1, addr2] = await ethers.getSigners();
    const bee = await ethers.getContractFactory("Bee");
    Bee = await bee.deploy();
    await Bee.deployed();
    const exchange = await ethers.getContractFactory("Exchange");
    Exchange = await exchange.deploy(Bee.address);
    await Exchange.deployed();
  });

  const allowExchange = async (amount: number, signer?: SignerWithAddress) => {
    await Bee.connect(signer ?? addr1).approve(
      Exchange.address,
      ethers.utils.parseEther(amount.toString())
    );
  };

  const initialLiquidity = async (eth: number, token: number) => {
    await allowExchange(token);
    await Exchange.addLiquidity(to18Decimals(token), {
      value: to18Decimals(eth),
    });
  };

  const to18Decimals = (amount: number) => {
    return ethers.utils.parseEther(amount.toString());
  };

  // describe("constructor", () => {
  //   it("should set address of erc20 token to value passed at deployment", async () => {
  //     const erc20TokenAddress = await Exchange.beeToken();
  //     expect(erc20TokenAddress).to.equal(Bee.address);
  //   });

  //   it("should revert if address of erc20 token passed at deployment is null address", async () => {
  //     const exchange = await ethers.getContractFactory("Exchange");
  //     await expect(
  //       exchange.deploy(ethers.constants.AddressZero)
  //     ).to.be.revertedWith("NULL_TOKEN_ADDRESS");
  //   });
  // });

  // describe("getReserves", () => {
  //   it("should return the balance of contract for the erc20 token", async () => {
  //     const contractBalanceOfToken: BigNumber = await Bee.balanceOf(
  //       Exchange.address
  //     );
  //     const tokenReserveInContract: BigNumber[] = await Exchange.getReserves();
  //     expect(contractBalanceOfToken).to.equal(tokenReserveInContract[1]);
  //   });
  // });

  // describe("addLiquidity", () => {
  //   it("should revert if token approval is less than liquidity being provided", async () => {
  //     await expect(
  //       Exchange.addLiquidity(ethers.utils.parseEther("1"))
  //     ).to.be.revertedWith("INSUFFICIENT_TOKEN_APPROVAL");
  //   });

  //   it("should revert if no ether is sent", async () => {
  //     const erc20Liquidity = 1000;
  //     await allowExchange(erc20Liquidity);
  //     await expect(
  //       Exchange.addLiquidity(
  //         ethers.utils.parseEther(erc20Liquidity.toString())
  //       )
  //     ).to.be.revertedWith("NO_ETHER_SENT");
  //   });

  //   it("should revert if not amount of erc20 token is sent", async () => {
  //     await allowExchange(1000);
  //     await expect(
  //       Exchange.addLiquidity(0, { value: ethers.utils.parseEther("0.01") })
  //     ).to.be.revertedWith("NO_TOKEN_SENT");
  //   });

  //   it("should set ratio when first liquidity is added", async () => {
  //     const erc20Liquidity = 1000;
  //     const etherLiquidity = 1;
  //     await initialLiquidity(etherLiquidity, erc20Liquidity);

  //     const reserves: BigNumber[] = await Exchange.getReserves();
  //     expect(await Exchange.balanceOf(addr1.address)).to.equal(
  //       to18Decimals(etherLiquidity)
  //     );
  //     expect(reserves[0]).to.equal(to18Decimals(etherLiquidity));
  //     expect(reserves[1]).to.equal(to18Decimals(erc20Liquidity));
  //   });

  //   it("should revert if tokens added is not in the current price ratio", async () => {
  //     await initialLiquidity(1, 1000);
  //     const erc20Liquidity = 99;
  //     const etherLiquidity = 0.1;
  //     await allowExchange(erc20Liquidity);

  //     await expect(
  //       Exchange.addLiquidity(to18Decimals(erc20Liquidity), {
  //         value: to18Decimals(etherLiquidity),
  //       })
  //     ).to.be.revertedWith("INSUFFICIENT_TOKENS_SENT");
  //   });

  //   it("should add liquidity if sufficient tokens are sent", async () => {
  //     const initialErc20Liquidity = 1000;
  //     const initialEtherLiquidity = 1;
  //     await initialLiquidity(initialEtherLiquidity, initialErc20Liquidity);
  //     const erc20Liquidity = 100;
  //     const etherLiquidity = 0.1;
  //     const totalLpTokens: BigNumber = await Exchange.totalSupply();

  //     await Bee.connect(addr1).transfer(
  //       addr2.address,
  //       ethers.utils.parseEther(erc20Liquidity.toString())
  //     );
  //     await allowExchange(erc20Liquidity, addr2);
  //     await Exchange.connect(addr2).addLiquidity(to18Decimals(erc20Liquidity), {
  //       value: to18Decimals(etherLiquidity),
  //     });

  //     const reserves: BigNumber[] = await Exchange.getReserves();
  //     const lpTokenShare = to18Decimals(etherLiquidity)
  //       .mul(totalLpTokens)
  //       .div(to18Decimals(initialEtherLiquidity));

  //     expect(await Exchange.balanceOf(addr2.address)).to.equal(lpTokenShare);
  //     expect(reserves[0]).to.equal(
  //       to18Decimals(etherLiquidity + initialEtherLiquidity)
  //     );
  //     expect(reserves[1]).to.equal(
  //       to18Decimals(erc20Liquidity + initialErc20Liquidity)
  //     );
  //   });
  // });

  describe("removeLiquidity", () => {
    it("should revert if LP tokens passed is more than LP tokens owned by caller", async () => {
      const initialErc20Liquidity = 1000;
      const initialEtherLiquidity = 1;
      await initialLiquidity(initialEtherLiquidity, initialErc20Liquidity);

      await expect(
        Exchange.removeLiquidity(
          to18Decimals(initialEtherLiquidity).add(BigNumber.from(1))
        )
      ).to.be.revertedWith("INSUFFICIENT_LP_TOKENS");
    });

    it("should withdraw liquidity to sender's address", async () => {
      const initialErc20Liquidity = 1000;
      const initialEtherLiquidity = 1;
      await initialLiquidity(initialEtherLiquidity, initialErc20Liquidity);

      const erc20BalanceBeforeRemoval: BigNumber = await Bee.balanceOf(
        addr1.address
      );
      const lpTokenShareBeforeremoval: BigNumber = await Exchange.balanceOf(
        addr1.address
      );

      const totalLpTokensBeforeRemoval: BigNumber =
        await Exchange.totalSupply();
      const lpTokenShareToWithdraw = lpTokenShareBeforeremoval;

      // simulate withdrawal to obtain return values
      const withdrawalsValue = await Exchange.callStatic.removeLiquidity(
        lpTokenShareToWithdraw
      );
      // authentic call to the function
      await Exchange.removeLiquidity(lpTokenShareBeforeremoval);

      const erc20BalanceAfterRemoval: BigNumber = await Bee.balanceOf(
        addr1.address
      );
      const lpTokenShareAfterRemoval: BigNumber = await Exchange.balanceOf(
        addr1.address
      );
      const totalLpTokensAfterRemoval: BigNumber = await Exchange.totalSupply();

      expect(erc20BalanceBeforeRemoval.add(withdrawalsValue[1])).to.equal(
        erc20BalanceAfterRemoval
      );
      expect(totalLpTokensAfterRemoval).to.equal(
        totalLpTokensBeforeRemoval.sub(lpTokenShareBeforeremoval)
      );
      expect(lpTokenShareAfterRemoval).to.equal(
        lpTokenShareBeforeremoval.sub(lpTokenShareToWithdraw)
      );
    });
  });
});
