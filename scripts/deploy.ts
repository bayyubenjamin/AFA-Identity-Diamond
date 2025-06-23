import { ethers } from "hardhat";
import { getSelectors } from "./libraries/diamond";
import { DiamondInit, FacetNames } from "../diamondConfig";

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
    
    // --- PERBAIKAN UTAMA DI SINI ---
    // Kita tidak lagi menggunakan placeholder "0x...".
    // Untuk development, kita gunakan alamat deployer sebagai verifier.
    const VERIFIER_ADDRESS = deployer.address; 
    const BASE_URI = "https://api.afa-weeb3tool.com/metadata/"; // Anda bisa mengubah ini nanti

    console.log(`✅ Verifier Address telah diatur ke: ${VERIFIER_ADDRESS}`);

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

    // 3. Prepare initializer call
    const initFacetContract = facetContracts[DiamondInit];
    const functionCall = initFacetContract.interface.encodeFunctionData("initialize", [
        VERIFIER_ADDRESS, // Sekarang menggunakan alamat yang valid
        BASE_URI,
    ]);

    // 4. Perform diamondCut
    const diamond = await ethers.getContractAt("IDiamondCut", diamondAddress);
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
    console.log(`Diamond Address: ${diamondAddress}`);
    console.log(`NFT Name: ${await identityCore.name()}`);
    console.log(`NFT Symbol: ${await identityCore.symbol()}`);
    console.log(`-----------------------------`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
