const { expect } = require("chai");
const { time } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { ethers } = require("hardhat");

describe("JackStaking", function () {
    let owner;
    let rewardHolder;
    let jackToken;
    let params;
    let jackStaking;

    beforeEach(async function () {
        [owner, rewardHolder] = await ethers.getSigners();
        jackToken = await ethers.deployContract("JACK");

        await jackToken.mint(
            rewardHolder.address,
            ethers.parseUnits("10000", "ether")
        );
        await jackToken.mint(
            owner.address,
            ethers.parseUnits("10000", "ether")
        );

        params = [
            60 * 60,
            1,
            20,
            jackToken.target,
            rewardHolder.address,
            "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
            60 * 5,
            100000000000,
        ];

        jackStaking = await ethers.deployContract("JackStaking", params);

        await jackToken.approve(
            jackStaking.target,
            ethers.parseUnits("10000", "ether")
        );
    });

    it("Check TotalStakers", async function () {
        expect(await jackStaking.totalStakers()).to.equal(0);
    });

    it("Check GetRewardTokenBalance", async function () {
        expect(await jackStaking.getRewardTokenBalance()).to.equal(
            ethers.parseUnits("10000", "ether")
        );
    });

    it("Check Stake", async function () {
        expect(await jackStaking.stake(ethers.parseUnits("10000", "ether"))).to
            .not.be.reverted;
    });

    it("Check Withdraw", async function () {
        await jackStaking.stake(ethers.parseUnits("10000", "ether"));
        await time.increaseTo(parseInt(new Date().valueOf() / 1000 + 3601));
        expect(await jackStaking.withdraw(ethers.parseUnits("10000", "ether")))
            .to.not.be.reverted;
    });

    it("Check Withdraw Correct Balance", async function () {
        await jackStaking.stake(ethers.parseUnits("10000", "ether"));
        await time.increaseTo(parseInt(new Date().valueOf() / 1000 + 13601));
        await jackStaking.withdraw(ethers.parseUnits("10000", "ether"));
        expect(await jackToken.balanceOf(owner.address)).to.equal(
            ethers.parseUnits("10000", "ether")
        );
    });

    it("Check SetMinStakeLockTime", async function () {
        expect(await jackStaking.setMinStakeLockTime(100)).to.not.be.reverted;
    });

    it("Check SetMinStakeLockTime Value", async function () {
        await jackStaking.setMinStakeLockTime(100);
        expect(await jackStaking.minStakeLockTime()).to.equal(100);
    });

    it("Check Staker", async function () {
        await jackStaking.stake(ethers.parseUnits("10000", "ether"));
        let staker = await jackStaking.getStakerAtIndex(0);

        expect(staker[0]).to.equal(owner.address);
    });
});
