// Menggunakan gaya impor CommonJS yang paling stabil untuk Hardhat
const hre = require("hardhat");
const { ethers } = hre;

// Mengimpor konfigurasi dari diamondConfig (pastikan file ini ada)
// Kita menggunakan require karena ini adalah skrip CommonJS
const { FacetNames } = require("../diamondConfig.js");

// Helper untuk mengubah nama fungsi menjadi selector 4-byte (gaya ethers v5)
function getSelector(signature) {
    return ethers.utils.id(signature).substring(0, 10);
}

async function main() {
    const [deployer] = await ethers.getSigners();
    const verifierWalletAddress = "0xE0F4e897D99D8F7642DaA807787501154D316870";

    console.log("🔨 Deploying contracts with the account:", deployer.address);

    // 1. Deploy semua facets
    console.log("\n🚀 Deploying facets...");
    const facetContracts = {};
    for (const facetName of FacetNames) {
        const FacetFactory = await ethers.getContractFactory(facetName);
        const facet = await FacetFactory.deploy();
        
        // PERBAIKAN: Menggunakan .deployed() dari ethers v5
        await facet.deployed(); 
        
        facetContracts[facetName] = facet;
        // PERBAIKAN: Menggunakan backticks (`) untuk string dan .address dari ethers v5
        console.log(`✅ ${facetName} deployed to: ${facet.address}`);
    }

    // 2. Deploy Diamond
    console.log("\n💎 Deploying Diamond...");
    const DiamondFactory = await ethers.getContractFactory("Diamond");
    const diamondContract = await DiamondFactory.deploy(
        deployer.address,
        facetContracts["DiamondCutFacet"].address
    );
    await diamondContract.deployed();
    const diamondAddress = diamondContract.address;
    console.log(`✅ Diamond proxy deployed to: ${diamondAddress}`);

    // 3. Susun cut menggunakan mapping untuk kejelasan
    console.log("\n🧩 Constructing Diamond Cut...");
    const cut = [];
    const selectorsMap = {
        DiamondLoupeFacet: ["facets()", "facetFunctionSelectors(address)", "facetAddress(bytes4)", "supportsInterface(bytes4)"],
        OwnershipFacet: ["owner()", "transferOwnership(address)"],
        IdentityCoreFacet: ["mintIdentity(bytes)", "getIdentity(address)", "verifier()", "baseURI()", "name()", "symbol()", "balanceOf(address)", "ownerOf(uint256)", "tokenURI(uint256)", "initialize(address,string)"],
        SubscriptionManagerFacet: ["setPriceInUSD(uint256)", "renewSubscription(uint256)", "isPremium(uint256)", "getPremiumExpiration(uint256)", "upgradeToPremium(uint256)"],
        AttestationFacet: ["attest(bytes32,bytes32)", "getAttestation(bytes32)"],
        TestingAdminFacet: ["adminMint(address)"],
        IdentityEnumerableFacet: ["totalSupply()", "tokenByIndex(uint256)", "tokenOfOwnerByIndex(address,uint256)"]
    };

    for (const facetName of FacetNames) {
        // DiamondCutFacet sudah ditambahkan di constructor, jadi kita lewati
        if (facetName === "DiamondCutFacet") continue;
        
        const selectors = (selectorsMap[facetName] || []).map(getSelector);
        if (selectors.length > 0) {
            cut.push({
                facetAddress: facetContracts[facetName].address,
                action: 0, // 0 = Add
                functionSelectors: selectors
            });
        }
    }
    console.log("✅ Diamond Cut Summary prepared.");

    // 4. Lakukan diamondCut dan panggil fungsi inisialisasi
    const diamondCutInstance = await ethers.getContractAt("IDiamondCut", diamondAddress);
    const initFacet = facetContracts["IdentityCoreFacet"];

    const functionCall = initFacet.interface.encodeFunctionData("initialize", [
        verifierWalletAddress,
        "https://cxoykbwigsfheaegpwke.supabase.co/functions/v1/metadata/",
    ]);

    console.log("\n🚀 Performing diamondCut...");
    const tx = await diamondCutInstance.diamondCut(cut, initFacet.address, functionCall);
    await tx.wait();
    console.log("✅ Diamond cut and initialization successful.");

    // Tes Akhir untuk verifikasi
    const identityCore = await ethers.getContractAt("IdentityCoreFacet", diamondAddress);
    console.log("\n--- FINAL VERIFICATION ---");
    console.log(`Diamond Address: ${diamondAddress}`);
    console.log(`Verifier Address: ${await identityCore.verifier()}`);
    console.log(`NFT Name: ${await identityCore.name()}`);
    console.log("--------------------------");
    console.log("\n🎉 Deployment complete!");
}

// Pola standar untuk eksekusi skrip Hardhat
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Uncaught error in script:", error);
        process.exit(1);
    });
