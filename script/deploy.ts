const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const ReverseDutchAuctionSwap = await ethers.getContractFactory("ReverseDutchAuctionSwap");
    const auctionContract = await ReverseDutchAuctionSwap.deploy();
    await auctionContract.deployed();

    console.log("Contract deployed at:", auctionContract.address);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});


import { ethers } from "hardhat";

async function deploy() {
    const signer = await ethers.provider.getSigner()

    console.log("=============STARTING DEPLOYMENT============\n\n")

    console.log("=============DEPLOYING TOKEN CONTRACT============\n")

    const tokenContract = await ethers.deployContract("W3BXII")
    await tokenContract.waitForDeployment()

    console.log("=============TOKEN CONTRACT DEPLOYED SUCCESSFULLY============\n")


    console.log("=============DEPLOYING SAVE ERC20 CONTRACT============\n")

    const saveContract = await ethers.deployContract("SaveERC20", [tokenContract.target])
    await saveContract.waitForDeployment()

    console.log("=============TOKEN CONTRACT DEPLOYED SUCCESSFULLY============\n")
    console.log("SAVE ERC20 CONTRACT ADDRESS:", saveContract.target)


}
