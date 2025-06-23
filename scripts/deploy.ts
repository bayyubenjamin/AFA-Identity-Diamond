import { ethers } from "hardhat";
import { getSelectors } from "./libraries/diamond";
import { DiamondInit, FacetNames } from "../diamondConfig";
import { Contract } from "ethers";

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // 1. Deploy semua facets
    console.log("Deploying facets...");
    const facetContracts: { [key: string]: Contract } = {};
    for (const facetName of FacetNames) {
        const FacetFactory = await ethers.getContractFactory(facetName);
        const facet = await FacetFactory.deploy();
        await facet.waitForDeployment();
        facetContracts[facetName] = facet;
        console.log(`- ${facetName} deployed to: ${await facet.getAddress()}`);
    }

    // 2. Deploy Diamond (constructor: owner + DiamondCutFacet)
    const DiamondFactory = await ethers.getContractFactory("Diamond");
    const diamondContract = await DiamondFactory.deploy(
        deployer.address,
        await facetContracts["DiamondCutFacet"].getAddress()
    );
    await diamondContract.waitForDeployment();
    const diamondAddress = await diamondContract.getAddress();
    console.log("💎 Diamond proxy deployed to:", diamondAddress);

    // 3. Susun `cut` untuk diamondCut
    const cut = [];
    const allSelectors = new Set<string>();

    for (const facetName of FacetNames) {
        let selectors = getSelectors(facetContracts[facetName]);

        // Skip diamondCut function (0x1f931c1c) dari DiamondCutFacet
        if (facetName === "DiamondCutFacet") {
            selectors = selectors.filter((s: string) => s !== "0x1f931c1c");
        }

        // Filter duplikat
        selectors = selectors.filter((selector: string) => {
            if (allSelectors.has(selector)) {
                console.warn(`⚠️  Selector ${selector} dari ${facetName} sudah ada, dilewati`);
                return false;
            }
            allSelectors.add(selector);
            return true;
        });

        console.log(`✅ Facet: ${facetName} | ${selectors.length} selectors`);

        cut.push({
            facetAddress: await facetContracts[facetName].getAddress(),
            action: 0, // ADD
            functionSelectors: selectors,
        });
    }

    // 4. diamondCut + inisialisasi
    const diamondCutInstance = await ethers.getContractAt("IDiamondCut", diamondAddress);
    console.log("\nPerforming diamond cut to add all facets...");

    const initFacet = facetContracts[DiamondInit];
    const functionCall = initFacet.interface.encodeFunctionData("initialize", [
        deployer.address,
        "https://api.afa-weeb3tool.com/metadata/",
    ]);

    const tx = await diamondCutInstance.connect(deployer).diamondCut(
        cut,
        await initFacet.getAddress(),
        functionCall
    );
    await tx.wait();

    console.log("✅ Diamond cut and initialization successful.");

    // Tes kontrak IdentityCoreFacet
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

