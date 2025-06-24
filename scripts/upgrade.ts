// scripts/upgrade.ts

import { ethers } from "hardhat";

// <-- GANTI DENGAN ALAMAT DIAMOND PROXY TERAKHIR ANDA
const DIAMOND_ADDRESS = "0xD1F93e4F2a9De2e162483c91714543813b37E5d1"; 

// Daftar fungsi yang ingin kita pastikan ada
const FUNCTIONS_TO_ADD = [
    // Dari IdentityCoreFacet
    "function mintIdentity(bytes calldata _signature) external payable",
    "function getIdentity(address _user) external view returns (uint256, uint256, bool)",
    "function verifier() external view returns (address)",
    "function baseURI() external view returns (string memory)",
    "function tokenURI(uint256 _tokenId) external view returns (string memory)",
    "function ownerOf(uint256 tokenId) external view returns (address owner)",
    "function balanceOf(address owner) external view returns (uint256 balance)",
    "function name() external view returns (string memory)",
    "function symbol() external view returns (string memory)",

    // Dari SubscriptionManagerFacet
    "function setPriceInUSD(uint256 _priceInCents) external",
    "function renewSubscription(uint256 tokenId) external payable",
    "function isPremium(uint256 tokenId) external view returns (bool)",
    "function getPremiumExpiration(uint256 tokenId) external view returns (uint256)",

    // Dari OwnershipFacet
    "function owner() external view returns (address owner_)",
    "function transferOwnership(address _newOwner) external"
];

function getSelectors(signatures: string[]): string[] {
    return signatures.map(sig => ethers.id(sig).substring(0, 10));
}

async function main() {
    console.log(`🚀 Starting upgrade for Diamond at: ${DIAMOND_ADDRESS}`);

    const diamondCutFacet = await ethers.getContractAt("IDiamondCut", DIAMOND_ADDRESS);

    // 1. Deploy ulang Facet yang fungsinya hilang (IdentityCoreFacet)
    console.log("Deploying IdentityCoreFacet...");
    const IdentityCoreFactory = await ethers.getContractFactory("IdentityCoreFacet");
    const identityCoreFacet = await IdentityCoreFactory.deploy();
    await identityCoreFacet.waitForDeployment();
    const identityCoreFacetAddress = await identityCoreFacet.getAddress();
    console.log(`✅ IdentityCoreFacet deployed to: ${identityCoreFacetAddress}`);

    // 2. Siapkan diamond cut
    const selectors = getSelectors(FUNCTIONS_TO_ADD);

    const cut = [{
        facetAddress: identityCoreFacetAddress,
        action: 1, // 1 = Replace. Ini akan menambah fungsi jika belum ada, atau menggantinya jika sudah ada.
        functionSelectors: selectors
    }];

    console.log("\n📋 Performing Diamond Cut to add/replace functions...");
    
    // 3. Eksekusi diamondCut
    const tx = await diamondCutFacet.diamondCut(cut, ethers.ZeroAddress, "0x");
    console.log("DiamondCut transaction sent:", tx.hash);

    await tx.wait();
    console.log("\n✨✨✨ Upgrade complete! Functions should now be registered.");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
