import { ethers } from "hardhat";
import { FacetCutAction, getSelectors } from "./libraries/diamond";

// USAGE:
// npx hardhat run scripts/upgradeFacet.ts --network sepolia <DIAMOND_ADDRESS> <NEW_FACET_NAME>
// Example: npx hardhat run scripts/upgradeFacet.ts --network sepolia 0x... AFAIdentityFacetV2

async function main() {
    const [diamondAddress, newFacetName] = process.argv.slice(2);
    if (!diamondAddress || !newFacetName) {
        console.error("Usage: <DIAMOND_ADDRESS> <NEW_FACET_NAME>");
        process.exit(1);
    }
    
    console.log(`Upgrading diamond at ${diamondAddress} with new facet ${newFacetName}`);

    // 1. Deploy new facet
    const NewFacetFactory = await ethers.getContractFactory(newFacetName);
    const newFacet = await NewFacetFactory.deploy();
    await newFacet.waitForDeployment();
    const newFacetAddress = await newFacet.getAddress();
    console.log(`${newFacetName} deployed to: ${newFacetAddress}`);

    // 2. Prepare DiamondCut to replace functions
    const selectors = getSelectors(newFacet);
    
    const cut = [{
        facetAddress: newFacetAddress,
        action: FacetCutAction.Replace, // Use Replace to update existing functions
        functionSelectors: selectors,
    }];
    
    // 3. Execute DiamondCut
    const diamondCutFacet = await ethers.getContractAt("IDiamondCut", diamondAddress);
    const tx = await diamondCutFacet.diamondCut(cut, ethers.ZeroAddress, "0x");
    console.log("DiamondCut transaction sent:", tx.hash);

    await tx.wait();
    console.log("✨ Facet upgraded successfully!");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
