import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { ethers } from "hardhat";
import { expect } from "chai";

describe("ReverseDutchAuctionSwap", () => {
    async function deployAuctionFixture() {
        const [owner, buyer] = await ethers.getSigners();
        const Token = await ethers.getContractFactory("MAINERC20");
        const token = await Token.deploy(owner.address, ethers.parseUnits("1000", 18));
        await token.waitForDeployment();

        const Auction = await ethers.getContractFactory("DutchAuctionSwap");
        const auction = await Auction.deploy(Token.target);
        await auction.waitForDeployment();

        return { owner, buyer, token, auction };
    }

    describe("Deployment", () => {
        it("Should set the seller correctly", async () => {
            const { owner, auction } = await loadFixture(deployAuctionFixture);
            expect(await auction.seller()).to.equal(owner.address);
        });
    });

    describe("Start Auction", () => {
        it("Should allow seller to start an auction", async () => {
            const { owner, token, auction } = await loadFixture(deployAuctionFixture);
            const amount = ethers.parseUnits("100", 18);
            await token.approve(auction.target, amount);
            await expect(auction.startAuction(token.target, amount, ethers.parseUnits("10", 18), 3600))
                .to.not.be.reverted;
        });
    });

    describe("Get Current Price", () => {
        it("Should return the correct price after time passes", async () => {
            const { owner, token, auction } = await loadFixture(deployAuctionFixture);
            const amount = ethers.parseUnits("100", 18);
            await token.approve(auction.target, amount);
            await auction.startAuction(token.target, amount, ethers.parseUnits("10", 18), 3600);

            await network.provider.send("evm_increaseTime", [1800]);
            await network.provider.send("evm_mine");

            const currentPrice = await auction.getCurrentPrice();
            expect(currentPrice).to.be.below(ethers.parseUnits("10", 18));
        });
    });

    describe("Buy", () => {
        it("Should allow a buyer to purchase at the current price", async () => {
            const { owner, buyer, token, auction } = await loadFixture(deployAuctionFixture);
            const amount = ethers.parseUnits("100", 18);
            await token.approve(auction.target, amount);
            await auction.startAuction(token.target, amount, ethers.parseUnits("10", 18), 3600);

            await network.provider.send("evm_increaseTime", [1800]);
            await network.provider.send("evm_mine");

            const price = await auction.getCurrentPrice();
            await expect(auction.connect(buyer).buy({ value: price })).to.not.be.reverted;
            expect(await auction.auctionActive()).to.be.false;
        });
    });
});
