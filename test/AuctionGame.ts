// Hardhat Test (test/auction.js)
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Reverse Dutch Auction Swap", function () {
    // let auction, token, owner, buyer;
    describe("SAVE_ERC20", () => {
        async function deploySaveFixture() {
            const [owner, addr1, addr2] = await ethers.getSigners()

            [owner, buyer] = await ethers.getSigners();
            const Token = await ethers.getContractFactory("DutchAuctionSwap");
            token = await Token.deploy("EBUKA", "EBU", owner.address, ethers.utils.parseEther("1000"));
            await token.deployed();

            const Auction = await ethers.getContractFactory("DutchAuctionSwap");
            auction = await Auction.deploy();
            await auction.deployed();
        });

    it("Should allow seller to start an auction", async function () {
        await token.approve(auction.address, ethers.utils.parseEther("100"));
        await auction.startAuction(token.address, ethers.utils.parseEther("100"), ethers.utils.parseEther("10"), 3600);
        expect(await auction.auctionActive()).to.be.true;
    });

    it("Should allow a buyer to purchase at a reduced price", async function () {
        await token.approve(auction.address, ethers.utils.parseEther("100"));
        await auction.startAuction(token.address, ethers.utils.parseEther("100"), ethers.utils.parseEther("10"), 3600);

        await network.provider.send("evm_increaseTime", [1800]);
        await network.provider.send("evm_mine");

        const price = await auction.getCurrentPrice();
        await auction.connect(buyer).buy({ value: price });

        expect(await token.balanceOf(buyer.address)).to.equal(ethers.utils.parseEther("100"));
        expect(await auction.auctionActive()).to.be.false;
    });
});
