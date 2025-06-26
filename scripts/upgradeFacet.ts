import { ethers } from "hardhat";
import { FacetCutAction, getSelectors } from "./libraries/diamond";

// Hardcode di sini (atau pakai env/argumen jika mau)
const diamondAddress = "0x5045c77a154178db4b41b8584830311108124489";
const newFacetName = "SubscriptionManagerFacet";

// Helper untuk dapatkan semua selector yang sudah teregister di diamond
async function getExistingSelectors(diamondAddress: string) {
    // IDiamondLoupe interface harus ada di diamondmu
    // Fungsi 'facets()' mengembalikan daftar facet dan selector mereka
    const loupe = await ethers.getContractAt("IDiamondLoupe", diamondAddress);
    const facets = await loupe.facets();
    const existingSelectors: Set<string> = new Set();
    for (const facet of facets) {
        for (const selector of facet.functionSelectors) {
            existingSelectors.add(selector);
        }
    }
    return existingSelectors;
}

async function main() {
    console.log(`Upgrading diamond at ${diamondAddress} with new facet ${newFacetName}`);

    // 1. Deploy new facet
    const NewFacetFactory = await ethers.getContractFactory(newFacetName);
    const newFacet = await NewFacetFactory.deploy();
    await newFacet.waitForDeployment();
    const newFacetAddress = await newFacet.getAddress();
    console.log(`${newFacetName} deployed to: ${newFacetAddress}`);

    // 2. Ambil semua selector baru dari facet
    const selectors = getSelectors(newFacet);

    // 3. Ambil semua selector yang sudah ada di diamond
    const existingSelectors = await getExistingSelectors(diamondAddress);

    // 4. Pisahkan: selector yang sudah ada = Replace, yang belum ada = Add
    const addSelectors: string[] = [];
    const replaceSelectors: string[] = [];
    for (const sel of selectors) {
        if (existingSelectors.has(sel)) {
            replaceSelectors.push(sel);
        } else {
            addSelectors.push(sel);
        }
    }

    const cut = [];
    if (addSelectors.length > 0) {
        cut.push({
            facetAddress: newFacetAddress,
            action: FacetCutAction.Add,
            functionSelectors: addSelectors,
        });
    }
    if (replaceSelectors.length > 0) {
        cut.push({
            facetAddress: newFacetAddress,
            action: FacetCutAction.Replace,
            functionSelectors: replaceSelectors,
        });
    }

    if (cut.length === 0) {
        console.log("Nothing to upgrade: all selectors already exist and are identical.");
        return;
    }

    // 5. Execute DiamondCut
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
