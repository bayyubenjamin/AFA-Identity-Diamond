import { ethers } from "hardhat";
import { DiamondInit, FacetNames } from "../diamondConfig";
import { Contract } from "ethers";

// Helper untuk mengubah nama fungsi menjadi selector 4-byte
function getSelector(signature: string): string {
    return ethers.id(signature).substring(0, 10);
}

async function main() {
    const [deployer] = await ethers.getSigners();
    const verifierWalletAddress = "0xE0F4e897D99D8F7642DaA807787501154D316870"; // Alamat verifier (wallet kedua)

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

    // 2. Deploy Diamond
    const DiamondFactory = await ethers.getContractFactory("Diamond");
    const diamondContract = await DiamondFactory.deploy(
        deployer.address,
        await facetContracts["DiamondCutFacet"].getAddress()
    );
    await diamondContract.waitForDeployment();
    const diamondAddress = await diamondContract.getAddress();
    console.log("💎 Diamond proxy deployed to:", diamondAddress);

    // 3. Susun cut SECARA MANUAL & EKSPLISIT
    console.log("\nConstructing Diamond Cut...");
    
    const cut = [
        {
            facetAddress: await facetContracts["DiamondLoupeFacet"].getAddress(),
            action: 0, // Add
            functionSelectors: [
                getSelector("facets()"),
                getSelector("facetFunctionSelectors(address)"),
                getSelector("facetAddress(bytes4)"),
                getSelector("supportsInterface(bytes4)")
            ]
        },
        {
            facetAddress: await facetContracts["OwnershipFacet"].getAddress(),
            action: 0, // Add
            functionSelectors: [
                getSelector("owner()"),
                getSelector("transferOwnership(address)")
            ]
        },
        {
            facetAddress: await facetContracts["IdentityCoreFacet"].getAddress(),
            action: 0, // Add
            functionSelectors: [
                getSelector("mintIdentity(bytes)"),
                getSelector("getIdentity(address)"),
                getSelector("verifier()"),
                getSelector("baseURI()"),
                getSelector("name()"),
                getSelector("symbol()"),
                getSelector("balanceOf(address)"),
                getSelector("ownerOf(uint256)"),
                getSelector("tokenURI(uint256)"),
                getSelector("initialize(address,string)")
            ]
        },
        {
            facetAddress: await facetContracts["SubscriptionManagerFacet"].getAddress(),
            action: 0, // Add
            functionSelectors: [
                getSelector("setPriceInUSD(uint256)"),
                getSelector("renewSubscription(uint256)"),
                getSelector("isPremium(uint256)"),
                getSelector("getPremiumExpiration(uint256)")
            ]
        },
        // Tambahkan facet lain jika perlu (AttestationFacet, etc.)
        {
            facetAddress: await facetContracts["AttestationFacet"].getAddress(),
            action: 0, // Add
            functionSelectors: [
                getSelector("attest(bytes32,bytes32)"),
                getSelector("getAttestation(bytes32)")
            ]
        },
        // Tambahkan TestingAdminFacet (agar adminMint aktif)
        {
            facetAddress: await facetContracts["TestingAdminFacet"].getAddress(),
            action: 0, // Add
            functionSelectors: [
                getSelector("adminMint(address)")
            ]
        }
    ];

    console.log("\n📋 Diamond Cut Summary prepared.");

    // 4. diamondCut + initialize
    const diamondCutInstance = await ethers.getContractAt("IDiamondCut", diamondAddress);
    const initFacet = facetContracts["IdentityCoreFacet"]; // Inisialisasi ada di sini

    const functionCall = initFacet.interface.encodeFunctionData("initialize", [
        verifierWalletAddress,
        "https://cxoykbwigsfheaegpwke.supabase.co/functions/v1/metadata/",
    ]);

    console.log("\n🚀 Performing diamondCut...");
    const tx = await diamondCutInstance.diamondCut(cut, await initFacet.getAddress(), functionCall);
    await tx.wait();
    console.log("✅ Diamond cut and initialization successful.");

    // Tes Akhir
    const identityCore = await ethers.getContractAt("IdentityCoreFacet", diamondAddress);
    console.log(`\n--- FINAL VERIFICATION ---`);
    console.log(`Diamond Address: ${diamondAddress}`);
    console.log(`Verifier Address: ${await identityCore.verifier()}`);
    console.log(`NFT Name: ${await identityCore.name()}`);
    console.log(`------------------------`);
}

main().catch((error) => {
    console.error("❌ Uncaught error in script:", error);
    process.exitCode = 1;
});
