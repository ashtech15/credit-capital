const { expect } = require("chai");
const { toUtf8Bytes } = require("ethers/lib/utils");
const { ethers } = require("hardhat");

const deployContract = async (contract, params) => {
  let c = await ethers.getContractFactory(contract);
  if (params) c = await c.deploy(...params);
  else c = await c.deploy();
  return await c.deployed();
};

const deployContracts = async (deployer) => {
  const capl = await deployContract("CreditCapitalPlatformToken", [100]);
  const vault = await deployContract("Vault", [
    capl.address, // Assume that we have only one pool
    BigInt((5000 / (24 * 60 * 60)) * 10 ** 18), // token reward per second
  ]);
  const rewards = await deployContract("Rewards", [
    vault.address,
    capl.address,
  ]);
  return { capl, vault, rewards };
};

describe("Deposit Vault", function () {
  let deployer;
  let user;
  let capl;
  let vault;
  let rewards;

  beforeEach(async function () {
    [deployer, user] = await ethers.getSigners();
    // deploy token contract
    ({ capl, vault, rewards } = await deployContracts(deployer));
  });

  it("Deploy a new pool", async function () {
    // await capl.mint(deployer.address, 100); // mint 100 CAPL
    const pool = await vault.getPool(capl.address);

    expect(Number(pool.totalPooled.toString())).to.equal(0);
    expect(
      Number(ethers.utils.formatEther(pool.rewardsPerSecond.toString()))
    ).to.equal(5000 / (24 * 60 * 60));
  });

  it("Deposit a new position", async function () {
    await capl.mint(deployer.address, 100);

    // grant rewards the REWARDS role in the vault
    vault.grantRole(
      ethers.utils.keccak256(ethers.utils.toUtf8Bytes("REWARDS")),
      rewards.address
    );

    // check deployer account capl balance & approve rewards spending
    expect(await capl.balanceOf(deployer.address)).to.equal(100);
    capl.approve(rewards.address, 10);

    await rewards.deposit(capl.address, 10);

    // check all vault variables to be correct
    // withdraw should be impossible
    const userPosition = await vault.getUserPosition(
      capl.address,
      deployer.address
    );
    // should be one user position, one pool, and one stake
    expect(Number(userPosition.totalAmount.toString())).to.equal(10);
    expect(Number(userPosition.rewardDebt.toString())).to.equal(0);
    expect(userPosition.stakes.length).to.equal(1);
    expect(Number(userPosition.stakes[0].amount.toString())).to.equal(10);

    // expect no unlocked amount
    const unlockedAmount = await vault.getUnlockedAmount(
      capl.address,
      deployer.address
    );
    expect(Number(ethers.utils.formatEther(unlockedAmount)).toFixed(0)).to.equal("0");
    // check pool instance for correct values
    const pool = await vault.getPool(capl.address);

    expect(Number(pool.totalPooled.toString())).to.equal(10);
    expect(
      Number(ethers.utils.formatEther(pool.rewardsPerSecond.toString()))
    ).to.equal(5000 / (24 * 60 * 60));
  });
});
