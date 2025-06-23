// scripts/deploy.ts

import { ethers } from "hardhat";
import { getSelectors } from "./libraries/diamond";
import { DiamondInit, FacetNames } from "../diamondConfig";

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
    
    const VERIFIER_ADDRESS = "0x..."; // ISI ALAMAT BACKEND VERIFIER ANDA DI SINI
    const BASE_URI = "https://api.yourproject.com/metadata/"; // ISI BASE URI API METADATA ANDA

    // 1. Deploy Diamond
    const DiamondFactory = await ethers.getContractFactory("Diamond");
    const diamondContract = await DiamondFactory.deploy(deployer.address);
    await diamondContract.waitForDeployment();
    const diamondAddress = await diamondContract.getAddress();
    console.log("💎 Diamond proxy deployed to:", diamondAddress);

    // 2. Deploy Facets
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
            action: 0, // FacetCutAction.Add
            functionSelectors: getSelectors(facet),
        });
    }

    // 3. Prepare initializer call for the new initializer facet
    const initFacetContract = facetContracts[DiamondInit]; // Now 'SubscriptionManagerFacet'
    const functionCall = initFacetContract.interface.encodeFunctionData("initialize", [
        VERIFIER_ADDRESS,
        BASE_URI,
    ]);

    // 4. Perform diamondCut
    const diamond = await ethers.getContractAt("Diamond", diamondAddress);
    console.log("\nPerforming diamond cut and initialization...");
    const tx = await diamond.connect(deployer).diamondCut(
        cut, 
        await initFacetContract.getAddress(), 
        functionCall
    );
    
    await tx.wait();
    console.log("✅ Diamond cut and initialization successful.");

    // Final check
    const identityCore = await ethers.getContractAt("IdentityCoreFacet", diamondAddress);
    console.log(`\n--- Deployment Successful ---`);
    console.log(`NFT Name: ${await identityCore.name()}`);
    console.log(`NFT Symbol: ${await identityCore.symbol()}`);
    console.log(`Base URI: ${await identityCore.baseURI()}`);
    console.log(`-----------------------------`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
