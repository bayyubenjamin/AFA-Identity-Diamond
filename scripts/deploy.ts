import { ethers } from "hardhat";
import { getSelectors } from "./libraries/diamond";
import { DiamondInit, FacetNames } from "../diamondConfig";

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
    
    const VERIFIER_ADDRESS = deployer.address;
    const BASE_URI = "https://api.afa-weeb3tool.com/metadata/";

    console.log(`✅ Verifier Address will be set to: ${VERIFIER_ADDRESS}`);

    // --- PERBAIKAN UTAMA DI SINI ---
    // 1. Deploy DiamondCutFacet terlebih dahulu.
    const DiamondCutFacetFactory = await ethers.getContractFactory("DiamondCutFacet");
    const diamondCutFacet = await DiamondCutFacetFactory.deploy();
    await diamondCutFacet.waitForDeployment();
    console.log(`- DiamondCutFacet deployed to: ${await diamondCutFacet.getAddress()}`);

    // 2. Deploy Diamond dengan DUA argumen yang benar.
    const DiamondFactory = await ethers.getContractFactory("Diamond");
    const diamondContract = await DiamondFactory.deploy(deployer.address, await diamondCutFacet.getAddress());
    await diamondContract.waitForDeployment();
    const diamondAddress = await diamondContract.getAddress();
    console.log("💎 Diamond proxy deployed to:", diamondAddress);

    // 3. Deploy sisa facet lainnya.
    console.log("\nDeploying other facets...");
    const cut = [];
    const facetContracts: { [key: string]: any } = {
        'DiamondCutFacet': diamondCutFacet
    };

    // Filter DiamondCutFacet karena sudah di-deploy
    const otherFacetNames = FacetNames.filter(name => name !== 'DiamondCutFacet');
    for (const facetName of otherFacetNames) {
        const FacetFactory = await ethers.getContractFactory(facetName);
        const facet = await FacetFactory.deploy();
        await facet.waitForDeployment();
        facetContracts[facetName] = facet;
        console.log(`- ${facetName} deployed to: ${await facet.getAddress()}`);
    }

    // Siapkan 'cut' untuk semua facet KECUALI DiamondCutFacet (karena sudah ditambahkan di constructor)
    for (const facetName of otherFacetNames) {
         cut.push({
            facetAddress: await facetContracts[facetName].getAddress(),
            action: 0, // FacetCutAction.Add
            functionSelectors: getSelectors(facetContracts[facetName]),
        });
    }

    // 4. Prepare initializer call
    const initFacetContract = facetContracts[DiamondInit];
    const functionCall = initFacetContract.interface.encodeFunctionData("initialize", [
        VERIFIER_ADDRESS,
        BASE_URI,
    ]);

    // 5. Perform diamondCut
    const diamondCutInstance = await ethers.getContractAt("IDiamondCut", diamondAddress);
    console.log("\nPerforming diamond cut and initialization...");
    const tx = await diamondCutInstance.connect(deployer).diamondCut(
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
