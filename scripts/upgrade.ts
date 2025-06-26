import { ethers } from "hardhat";

// GANTI dengan alamat Diamond Proxy milikmu di Optimism Sepolia!
const DIAMOND_ADDRESS = "0xce6FbcB9337C39eA5DFfE44ABD8b5d35bfD0f684";

// Fungsi2 dari IdentityCoreFacet (silakan tambah jika ada perubahan)
const FUNCTIONS_IDENTITY_CORE = [
    "function mintIdentity(bytes calldata _signature) external payable",
    "function getIdentity(address _user) external view returns (uint256, uint256, bool)",
    "function verifier() external view returns (address)",
    "function baseURI() external view returns (string memory)",
    "function tokenURI(uint256 _tokenId) external view returns (string memory)",
    "function ownerOf(uint256 tokenId) external view returns (address owner)",
    "function balanceOf(address owner) external view returns (uint256 balance)",
    "function name() external view returns (string memory)",
    "function symbol() external view returns (string memory)"
];

// Fungsi2 dari TestingAdminFacet (tambahkan kalau ada fungsi admin lain)
const FUNCTIONS_ADMIN = [
    "function adminMint(address _to) external"
];

function getSelectors(signatures: string[]): string[] {
    return signatures.map(sig => ethers.id(sig).substring(0, 10));
}

async function main() {
    console.log(`🚀 Starting upgrade for Diamond at: ${DIAMOND_ADDRESS}`);

    // 1. Deploy ulang IdentityCoreFacet (jika ingin replace/update)
    console.log("Deploying IdentityCoreFacet...");
    const IdentityCoreFactory = await ethers.getContractFactory("IdentityCoreFacet");
    const identityCoreFacet = await IdentityCoreFactory.deploy();
    await identityCoreFacet.waitForDeployment();
    const identityCoreFacetAddress = await identityCoreFacet.getAddress();
    console.log(`✅ IdentityCoreFacet deployed to: ${identityCoreFacetAddress}`);

    // 2. Deploy TestingAdminFacet (supaya adminMint bisa digunakan)
    console.log("Deploying TestingAdminFacet...");
    const TestingAdminFactory = await ethers.getContractFactory("TestingAdminFacet");
    const testingAdminFacet = await TestingAdminFactory.deploy();
    await testingAdminFacet.waitForDeployment();
    const testingAdminFacetAddress = await testingAdminFacet.getAddress();
    console.log(`✅ TestingAdminFacet deployed to: ${testingAdminFacetAddress}`);

    // 3. Siapkan diamond cut array untuk kedua facet
    const cut = [
        {
            facetAddress: identityCoreFacetAddress,
            action: 0, // <--- GUNAKAN 0 (Add) untuk facet/fungsi baru
            functionSelectors: getSelectors(FUNCTIONS_IDENTITY_CORE),
        },
        {
            facetAddress: testingAdminFacetAddress,
            action: 0, // <--- GUNAKAN 0 (Add) untuk facet/fungsi baru
            functionSelectors: getSelectors(FUNCTIONS_ADMIN),
        }
    ];

    // 4. Eksekusi diamondCut
    const diamondCutFacet = await ethers.getContractAt("IDiamondCut", DIAMOND_ADDRESS);

    console.log("\n📋 Performing Diamond Cut to add/replace functions...");
    const tx = await diamondCutFacet.diamondCut(cut, ethers.ZeroAddress, "0x");
    console.log("DiamondCut transaction sent:", tx.hash);

    await tx.wait();
    console.log("\n✨✨✨ Upgrade complete! All functions should now be registered.");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
