const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert // Assertions for transactions that should fail
} = require("@openzeppelin/test-helpers");
const { expect } = require("chai");

const Staking = artifacts.require("Staking");
const ERC20Mock = artifacts.require("ERC20Mock");

contract("Staking", accounts => {
  const [initialHolder, recipient, anotherAccount] = accounts;
  let staking;
  let token;

  const name = "My Token";
  const symbol = "TKN";

  const initialSupply = new BN(100);

  before(async () => {
    staking = await Staking.deployed();
    token = await ERC20Mock.deployed();

    await token.mint(initialHolder, new BN("1000"));
    balance = await token.balanceOf(initialHolder);
  });

  describe("stake a certain amount", async () => {
    it("can add a token and remove it", async () => {
      await staking.addToken(token.address);
      expect(await staking.allowedTokens(token.address)).equals(true);
      await staking.removeToken(token.address);
      expect(await staking.allowedTokens(token.address)).equals(false);
    });

    it("can deposit a certain amount of token", async () => {
      await staking.addToken(token.address);

      await token.approve(staking.address, new BN("100"));
      await staking.deposit(new BN("100"), token.address);

      expect(await token.balanceOf(initialHolder)).to.be.bignumber.equal("900");
    });

    it("the staking contract should receive tokens to be staked", async () => {
      expect(
        await token.balanceOf(staking.address)
      ).to.be.bignumber.greaterThan("100");
    });

    it("individual stake amount should be equal to the deposited amount", async () => {
      amount = await staking.StakeMap(token.address, initialHolder);
      expect(new BN(amount.amount)).to.be.bignumber.equal("100");
    });

    it("total stake amount should be increased accordingly", async () => {
      expect(
        await staking.tokenTotalStaked(token.address)
      ).to.be.bignumber.equal("100");
    });

    it("can get the stake amount by token and user", async () => {
      expect(
        await staking.getStakedAmountByToken(token.address, initialHolder)
      ).to.be.bignumber.greaterThan("0");
    });
  });

  describe("distribute a reward", async () => {
    it("can set a reward", async () => {
      await token.approve(staking.address, new BN("10"));
      let result = await staking.distribute(new BN("10"), token.address);
    });

    it("total cummulated reward for the token should be increased accordingly", async () => {
      let amount = await staking.tokenCummRewardPerStake(token.address);

      expect(await amount).to.be.bignumber.greaterThan("0");
    });
    it("total balance of the user should decrease", async () => {
      let balance = await token.balanceOf(initialHolder);
      console.log("user balance: ", balance.toString());

      expect(balance).to.be.bignumber.equal("890");
    });

    it("total balance of the staking tokens should increase", async () => {
      let balance = await token.balanceOf(staking.address);
      console.log("stake balance: ", balance.toString());

      expect(balance).to.be.bignumber.greaterThan("110");
    });
  });

  describe("withdraw some of the stake", async () => {
    it("can withdraw some of the stake", async () => {
      reward = await staking.claim(token.address, initialHolder);
      await staking.withdraw(new BN("10"), token.address);
    });

    it("should decrease the staked amount of the user accordingly", async () => {
      amountByHolder = await staking.getStakedAmountByToken(
        token.address,
        initialHolder
      );

      expect(amountByHolder).to.be.bignumber.eq("90");
    });

    it("should decrease the total staked amount accordingly", async () => {
      amountByToken = await staking.tokenTotalStaked(token.address);

      expect(amountByToken).to.be.bignumber.eq("90");
    });

    it("the user should receive the withdraw amount + reward in token", async () => {
      balance = await token.balanceOf(initialHolder);

      console.log("user balance: ", balance.toString());
      expect(balance).to.be.bignumber.greaterThan("890");
    });
    it("the total balance of the contract should decrease", async () => {
      balance = await token.balanceOf(staking.address);
      console.log("stake balance: ", balance.toString());
      expect(balance).to.be.bignumber.lessThan("110");
    });
  });

  describe("withdraw all of the stake", async () => {
    it("can withdraw all of the stake", async () => {
      // await token.approve(initialHolder, new BN("90"));
      await staking.withdraw(new BN("90"), token.address);
    });

    it("the staked amount of the user should be zero", async () => {
      amountByHolder = await staking.getStakedAmountByToken(
        token.address,
        initialHolder
      );

      expect(amountByHolder).to.be.bignumber.eq("0");
    });

    it("should decrease the total staked amount accordingly", async () => {
      amountByToken = await staking.tokenTotalStaked(token.address);

      expect(amountByToken).to.be.bignumber.eq("0");
    });

    it("the user should receive the withdraw amount + reward in token", async () => {
      balance = await token.balanceOf(initialHolder);
      console.log(balance.toString());
      expect(balance).to.be.bignumber.greaterThan("980");
    });
    it("the total balance of the contract should decrease", async () => {
      balance = await token.balanceOf(staking.address);
      console.log(balance.toString());
      expect(balance).to.be.bignumber.lessThan("20");
    });
  });
});
