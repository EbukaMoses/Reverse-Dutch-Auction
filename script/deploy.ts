const { ethers } = require("hardhat");

async function main() {
    const signer = await ethers.provider.getSigners();
    console.log("Deploying contract with account:", signer.address);

    const ReverseDutchAuctionSwap = await ethers.getContractFactory("DutchAuctionSwap");
    const auctionContract = await ReverseDutchAuctionSwap.deploy();
    await auctionContract.deployed();

    console.log("Contract deployed at:", auctionContract.address);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});

