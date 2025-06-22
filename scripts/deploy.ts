import { ethers } from "hardhat";
import { FacetCutAction, getSelectors } from "./libraries/diamond";
import { DiamondInit, FacetNames } from "../diamondConfig";

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // 1. Deploy Diamond
    const diamondFactory = await ethers.getContractFactory("Diamond");
    const diamond = await diamondFactory.deploy(deployer.address);
    await diamond.waitForDeployment();
    const diamondAddress = await diamond.getAddress();
    console.log("Diamond deployed to:", diamondAddress);

    // 2. Deploy Facets
    console.log("\nDeploying facets...");
    const facets: { name: string, contract: any }[] = [];
    const facetContracts: { [key: string]: any } = {};

    for (const facetName of FacetNames) {
        const facetFactory = await ethers.getContractFactory(facetName);
        const facet = await facetFactory.deploy();
        await facet.waitForDeployment();
        facets.push({ name: facetName, contract: facet });
        facetContracts[facetName] = facet;
        console.log(`- ${facetName} deployed to: ${await facet.getAddress()}`);
    }

    // 3. Prepare DiamondCut
    const diamondCut = [];
    let functionCall;

    for (const { name, contract } of facets) {
        // Hapus fungsi yang tidak ingin diekspos jika perlu (contoh: initializer)
        let selectors = getSelectors(contract);
        if (name === 'AFA_Admin_Facet') {
            selectors = selectors.filter(sel => sel !== contract.interface.getFunction('initialize').selector);
        }
        
        diamondCut.push({
            facetAddress: await contract.getAddress(),
            action: FacetCutAction.Add,
            functionSelectors: selectors,
        });
    }
    
    // Prepare initializer call
    const initFacetContract = facetContracts[DiamondInit];
    functionCall = initFacetContract.interface.encodeFunctionData("initialize", [
        "AFA Identity", // NFT Name
        "AFAID",        // NFT Symbol
        deployer.address // Initial Admin
    ]);

    console.log("\nPerforming DiamondCut...");
    const diamondCutFacet = await ethers.getContractAt("IDiamondCut", diamondAddress);
    
    const tx = await diamondCutFacet.diamondCut(
        diamondCut,
        await initFacetContract.getAddress(),
        functionCall
    );
    
    const receipt = await tx.wait();
    if (!receipt?.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`);
    }
    console.log("DiamondCut successful. All facets have been added and initialized.");

    // Final check
    const afaERC721 = await ethers.getContractAt("AFA_ERC721_Facet", diamondAddress);
    console.log(`\nNFT Name from Diamond: ${await afaERC721.name()}`);
    console.log(`NFT Symbol from Diamond: ${await afaERC721.symbol()}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
