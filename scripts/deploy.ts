import { ethers } from "hardhat";
import { getSelectors } from "./libraries/diamond";
import { DiamondInit, FacetNames } from "../diamondConfig";
import { Contract } from "ethers";

async function main() {
    const [deployer] = await ethers.getSigners();

    // Ambil fee data untuk mendapatkan estimasi gas price
    const feeData = await ethers.provider.getFeeData();
    const adjustedGasPrice = feeData.gasPrice
        ? feeData.gasPrice + ethers.parseUnits("1", "gwei") // naikkan 1 gwei dari estimasi
        : ethers.parseUnits("5", "gwei"); // fallback

    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Using gas price:", ethers.formatUnits(adjustedGasPrice, "gwei"), "gwei");

    // 1. Deploy semua facets
    console.log("Deploying facets...");
    const facetContracts: { [key: string]: Contract } = {};
    for (const facetName of FacetNames) {
        const FacetFactory = await ethers.getContractFactory(facetName);
        const facet = await FacetFactory.deploy({ gasPrice: adjustedGasPrice });
        await facet.waitForDeployment();
        facetContracts[facetName] = facet;
        console.log(`- ${facetName} deployed to: ${await facet.getAddress()}`);
    }

    // 2. Deploy Diamond
    const DiamondFactory = await ethers.getContractFactory("Diamond");
    const diamondContract = await DiamondFactory.deploy(
        deployer.address,
        await facetContracts["DiamondCutFacet"].getAddress(),
        { gasPrice: adjustedGasPrice }
    );
    await diamondContract.waitForDeployment();
    const diamondAddress = await diamondContract.getAddress();
    console.log("💎 Diamond proxy deployed to:", diamondAddress);

    // 3. Susun cut
    const cut = [];
    const allSelectors = new Set<string>();

    for (const facetName of FacetNames) {
        let selectors = getSelectors(facetContracts[facetName]);

        if (facetName === "DiamondCutFacet") {
            selectors = selectors.filter((s: string) => s !== "0x1f931c1c");
        }

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
            action: 1, // ADD
            functionSelectors: selectors,
        });
    }

    console.log("\n📋 Diamond Cut Summary:");
    for (const entry of cut) {
        console.log(`- ${entry.facetAddress} | ${entry.functionSelectors.length} selectors`);
    }

    // 4. diamondCut + initialize
    const diamondCutInstance = await ethers.getContractAt("IDiamondCut", diamondAddress);
    const initFacet = facetContracts[DiamondInit];

    let functionCall = "0x";
    try {
        functionCall = initFacet.interface.encodeFunctionData("initialize", [
            deployer.address,
            "https://api.afa-weeb3tool.com/metadata/",
        ]);
    } catch (err) {
        console.warn("⚠️  initialize() tidak ditemukan di facet inisialisasi, lanjut tanpa inisialisasi");
    }

    console.log("\n🚀 Performing diamondCut (gas optimized)...");
    try {
        const tx = await diamondCutInstance.connect(deployer).diamondCut(
            cut,
            await initFacet.getAddress(),
            functionCall,
            {
                gasLimit: 3_500_000,
                gasPrice: adjustedGasPrice,
            }
        );
        const receipt = await tx.wait();
        if (receipt?.status === 0) {
            throw new Error("❌ DiamondCut transaction reverted");
        }
        console.log("✅ Diamond cut and initialization successful.");
    } catch (err) {
        console.error("❌ diamondCut failed:");
        console.error(err);
        return;
    }

    // Tes IdentityCoreFacet
    try {
        const identityCore = await ethers.getContractAt("IdentityCoreFacet", diamondAddress);
        console.log(`\n--- Deployment Successful ---`);
        console.log(`Diamond Address: ${diamondAddress}`);
        console.log(`NFT Name: ${await identityCore.name()}`);
        console.log(`NFT Symbol: ${await identityCore.symbol()}`);
        console.log(`-----------------------------`);
    } catch (err) {
        console.warn("⚠️  Tidak bisa membaca IdentityCoreFacet (mungkin belum di-add dengan benar)");
    }
}

main().catch((error) => {
    console.error("❌ Uncaught error in script:");
    console.error(error);
    process.exitCode = 1;
});

