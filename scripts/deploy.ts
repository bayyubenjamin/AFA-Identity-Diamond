// scripts/deploy.ts (Corrected with passing test logic)

import { ethers } from "hardhat";
import { getSelectors } from "./libraries/diamond";
import { DiamondInit, FacetNames } from "../diamondConfig";

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const FacetCut = {
        Add: 0,
        Replace: 1,
        Remove: 2
    };

    // 1. Deploy the main Diamond contract (it's "empty" initially)
    const DiamondFactory = await ethers.getContractFactory("Diamond");
    const diamondContract = await DiamondFactory.deploy(deployer.address);
    await diamondContract.waitForDeployment();
    const diamondAddress = await diamondContract.getAddress();
    const diamond = await ethers.getContractAt("Diamond", diamondAddress);
    console.log("💎 Diamond proxy deployed to:", diamondAddress);

    // 2. Deploy all Facets
    console.log("\nDeploying facets...");
    const cut = [];
    const facetContracts: { [key: string]: any } = {};
    for (const facetName of FacetNames) {
        const FacetFactory = await ethers.getContractFactory(facetName);
        const facet = await FacetFactory.deploy();
        await facet.waitForDeployment();
        facetContracts[facetName] = facet;
        
        console.log(`- ${facetName} deployed to: ${await facet.getAddress()}`);
        cut.push({
            facetAddress: await facet.getAddress(),
            action: FacetCut.Add,
            functionSelectors: getSelectors(facet),
        });
    }

    // 3. Prepare the initializer call
    const initFacetContract = facetContracts[DiamondInit];
    const functionCall = initFacetContract.interface.encodeFunctionData("initialize", [
        "AFA Identity",
        "AFAID",
        deployer.address,
    ]);

    // 4. Perform a single diamondCut to add all facets AND initialize the state
    console.log("\nPerforming diamond cut and initialization...");
    const tx = await diamond.connect(deployer).diamondCut(
        cut, 
        await initFacetContract.getAddress(), 
        functionCall
    );
    
    const receipt = await tx.wait();
    if (!receipt?.status) {
        throw Error(`Diamond cut/initialization failed: ${tx.hash}`);
    }
    console.log("✅ Diamond cut and initialization successful.");


    // Final check
    const afaERC721 = await ethers.getContractAt("AFA_ERC721_Facet", diamondAddress);
    console.log(`\n--- Deployment Successful ---`);
    console.log(`NFT Name: ${await afaERC721.name()}`);
    console.log(`NFT Symbol: ${await afaERC721.symbol()}`);
    console.log(`-----------------------------`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
