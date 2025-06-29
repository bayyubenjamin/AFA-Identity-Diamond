const { ethers } = require("hardhat");
const { FacetNames } = require("../diamondConfig.js");

function getSelector(signature) {
    return ethers.id(signature).substring(0, 10);
}

async function main() {
    const [deployer] = await ethers.getSigners();
    const verifierWalletAddress = "0xE0F4e897D99D8F7642DaA807787501154D316870";

    console.log("🔨 Deploying contracts with the account:", deployer.address);
    console.log("\n🚀 Deploying facets...");

    const facetContracts = {};
    for (const facetName of FacetNames) {
        const FacetFactory = await ethers.getContractFactory(facetName);
        const facet = await FacetFactory.deploy();
        
        await facet.waitForDeployment();
        
        facetContracts[facetName] = facet;
        console.log(`✅ ${facetName} deployed to: ${await facet.getAddress()}`);
    }

    // Deploy Diamond
    console.log("\n💎 Deploying Diamond...");
    const DiamondFactory = await ethers.getContractFactory("Diamond");
    const diamondContract = await DiamondFactory.deploy(
        deployer.address,
        await facetContracts["DiamondCutFacet"].getAddress()
    );
    await diamondContract.waitForDeployment();
    const diamondAddress = await diamondContract.getAddress();
    console.log(`✅ Diamond proxy deployed to: ${diamondAddress}`);

    // Construct Diamond Cut
    console.log("\n🧩 Constructing Diamond Cut...");
    const cut = [];

    // --- PERUBAHAN UTAMA: Memperbarui daftar fungsi untuk SubscriptionManagerFacet ---
    const selectorsMap = {
        DiamondLoupeFacet: ["facets()", "facetFunctionSelectors(address)", "facetAddress(bytes4)", "supportsInterface(bytes4)"],
        OwnershipFacet: ["owner()", "transferOwnership(address)", "withdraw()"],
        IdentityCoreFacet: ["mintIdentity(bytes)", "getIdentity(address)", "verifier()", "baseURI()", "name()", "symbol()", "balanceOf(address)", "ownerOf(uint256)", "tokenURI(uint256)", "initialize(address,string)"],
        // Menggunakan fungsi-fungsi baru untuk multi-tier subscription
        SubscriptionManagerFacet: [
            "setPriceForTier(uint8,uint256)", 
            "getPriceForTier(uint8)", 
            "upgradeToPremium(uint256,uint8)", 
            "getPremiumExpiration(uint256)", 
            "isPremium(uint256)"
        ],
        AttestationFacet: ["attest(bytes32,bytes32)", "getAttestation(bytes32)"],
        TestingAdminFacet: ["adminMint(address)"],
        IdentityEnumerableFacet: ["totalSupply()", "tokenByIndex(uint256)", "tokenOfOwnerByIndex(address,uint256)"]
    };

    for (const facetName of FacetNames) {
        if (facetName === "DiamondCutFacet") continue;
        
        const selectors = (selectorsMap[facetName] || []).map(getSelector);
        if (selectors.length > 0) {
            cut.push({
                facetAddress: await facetContracts[facetName].getAddress(),
                action: 0, // Add
                functionSelectors: selectors
            });
        }
    }
    console.log("✅ Diamond Cut Summary prepared.");

    // Perform diamondCut and initialize
    const diamondCutInstance = await ethers.getContractAt("IDiamondCut", diamondAddress);
    const initFacet = facetContracts["IdentityCoreFacet"];
    const functionCall = initFacet.interface.encodeFunctionData("initialize", [
        verifierWalletAddress,
        "https://cxoykbwigsfheaegpwke.supabase.co/functions/v1/metadata/",
    ]);

    console.log("\n🚀 Performing diamondCut and initialization...");
    const tx = await diamondCutInstance.diamondCut(cut, await initFacet.getAddress(), functionCall);
    await tx.wait();
    console.log("✅ DiamondCut and initialization successful.");

    // --- PENAMBAHAN BARU: Mengatur harga untuk setiap paket premium ---
    console.log("\n🛠️  Setting initial prices for subscription tiers...");
    const subscriptionManager = await ethers.getContractAt("SubscriptionManagerFacet", diamondAddress);
    
    // Konfigurasi harga (ubah sesuai kebutuhan Anda)
    // Tier 0 = 1 Bulan
    // Tier 1 = 6 Bulan
    // Tier 2 = 1 Tahun
    const prices = {
        oneMonth: ethers.parseEther("0.0004"), // Contoh: 0.0004 ETH
        sixMonths: ethers.parseEther("0.0025"), // Contoh: 0.0025 ETH (Diskon)
        oneYear: ethers.parseEther("0.005")    // Contoh: 0.005 ETH (Diskon lebih besar)
    };

    // Mengatur harga untuk 1 Bulan (Tier 0)
    console.log(`   - Setting 1-Month price to ${ethers.formatEther(prices.oneMonth)} ETH...`);
    let setPriceTx = await subscriptionManager.setPriceForTier(0, prices.oneMonth);
    await setPriceTx.wait();
    console.log("     ✅ Done.");

    // Mengatur harga untuk 6 Bulan (Tier 1)
    console.log(`   - Setting 6-Month price to ${ethers.formatEther(prices.sixMonths)} ETH...`);
    setPriceTx = await subscriptionManager.setPriceForTier(1, prices.sixMonths);
    await setPriceTx.wait();
    console.log("     ✅ Done.");

    // Mengatur harga untuk 1 Tahun (Tier 2)
    console.log(`   - Setting 1-Year price to ${ethers.formatEther(prices.oneYear)} ETH...`);
    setPriceTx = await subscriptionManager.setPriceForTier(2, prices.oneYear);
    await setPriceTx.wait();
    console.log("     ✅ Done.");
    
    console.log("✅ Initial prices for all tiers have been set.");
    console.log("\n🎉 Deployment complete! Diamond is ready at:", diamondAddress);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Uncaught error in script:", error);
        process.exit(1);
    });
