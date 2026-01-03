const { ethers, network } = require("hardhat");
const { FacetNames } = require("../diamondConfig.js");

/**
 * KONFIGURASI DEPLOYMENT
 * Ubah nilai di sini untuk mengganti parameter tanpa menyentuh logika script.
 */
const CONFIG = {
    verifierAddress: "0xE0F4e897D99D8F7642DaA807787501154D316870",
    metadataBaseURI: "https://cxoykbwigsfheaegpwke.supabase.co/functions/v1/metadata/",
    // Enum FacetCutAction dari standar Diamond (0 = Add, 1 = Replace, 2 = Remove)
    FacetCutAction: { Add: 0, Replace: 1, Remove: 2 },
    // Harga Subscription
    pricing: [
        { tierId: 0, price: "0.0004", name: "1 Month" },
        { tierId: 1, price: "0.0025", name: "6 Months" },
        { tierId: 2, price: "0.005",  name: "1 Year" }
    ]
};

/**
 * HELPER: Mengambil selector fungsi secara dinamis dari interface kontrak.
 * Tidak perlu lagi mengetik manual nama fungsi satu per satu!
 */
function getSelectors(contract) {
    const signatures = [];
    contract.interface.forEachFunction((func) => {
        if (func.name !== 'init' && func.name !== 'initialize') { // Biasanya init tidak dimasukkan ke loupe
            signatures.push(func.selector);
        }
    });
    return signatures;
}

/**
 * HELPER: Wrapper untuk deploy kontrak biasa
 */
async function deployContract(contractName, args = []) {
    const Factory = await ethers.getContractFactory(contractName);
    const contract = await Factory.deploy(...args);
    await contract.waitForDeployment();
    return contract;
}

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("=================================================");
    console.log(`🚀 STARTING DEPLOYMENT | Network: ${network.name}`);
    console.log(`👨‍💻 Deployer: ${deployer.address}`);
    console.log(`💰 Balance: ${ethers.formatEther(await ethers.provider.getBalance(deployer.address))} ETH`);
    console.log("=================================================\n");

    // --- STEP 1: Deploy Semua Facet ---
    console.log("🏗️  1. Deploying Facets...");
    const facetAddresses = {};
    const deployedFacets = []; // Menyimpan instance kontrak untuk ekstraksi selector

    for (const name of FacetNames) {
        try {
            const facet = await deployContract(name);
            const address = await facet.getAddress();
            console.log(`   ✅ ${name.padEnd(25)} : ${address}`);
            
            facetAddresses[name] = address;
            deployedFacets.push({ name, contract: facet, address });
        } catch (error) {
            console.error(`   ❌ Failed to deploy ${name}:`, error.message);
            process.exit(1);
        }
    }

    // --- STEP 2: Deploy Diamond Base ---
    console.log("\n💎 2. Deploying Diamond Proxy...");
    // DiamondCutFacet diperlukan saat konstruksi Diamond
    if (!facetAddresses["DiamondCutFacet"]) {
        throw new Error("DiamondCutFacet must be included in FacetNames array!");
    }

    const diamond = await deployContract("Diamond", [
        deployer.address, 
        facetAddresses["DiamondCutFacet"]
    ]);
    const diamondAddress = await diamond.getAddress();
    console.log(`   ✅ DIAMOND DEPLOYED AT: ${diamondAddress}`);

    // --- STEP 3: Membangun Diamond Cut (Secara Otomatis) ---
    console.log("\n✂️  3. Constructing Diamond Cut (Dynamic Selector Extraction)...");
    const cut = [];
    
    for (const facetData of deployedFacets) {
        // Skip DiamondCutFacet karena sudah ditambahkan saat constructor Diamond dipanggil
        if (facetData.name === "DiamondCutFacet") continue;

        const selectors = getSelectors(facetData.contract);
        
        if (selectors.length > 0) {
            cut.push({
                facetAddress: facetData.address,
                action: CONFIG.FacetCutAction.Add,
                functionSelectors: selectors
            });
            console.log(`   🔹 Added ${selectors.length} selectors from ${facetData.name}`);
        } else {
            console.warn(`   ⚠️  Warning: No public functions found in ${facetData.name}`);
        }
    }

    // --- STEP 4: Eksekusi Diamond Cut & Initialize ---
    console.log("\n🔌 4. Executing DiamondCut & Initialization...");
    
    // Kita menggunakan IdentityCoreFacet untuk inisialisasi awal
    const initFacetName = "IdentityCoreFacet";
    const initFacetContract = deployedFacets.find(f => f.name === initFacetName).contract;
    
    // Encode fungsi initialize
    const functionCall = initFacetContract.interface.encodeFunctionData("initialize", [
        CONFIG.verifierAddress,
        CONFIG.metadataBaseURI,
    ]);

    // Panggil fungsi diamondCut melalui interface IDiamondCut di alamat Diamond
    const diamondCut = await ethers.getContractAt("IDiamondCut", diamondAddress);
    
    const tx = await diamondCut.diamondCut(
        cut,
        facetAddresses[initFacetName], // Alamat kontrak yang punya fungsi init
        functionCall                   // Data calldata untuk init
    );
    
    console.log(`   ⏳ Transaction hash: ${tx.hash}`);
    await tx.wait();
    console.log("   ✅ Diamond Cut & Initialization Complete!");

    // --- STEP 5: Konfigurasi Lanjutan (Pricing) ---
    console.log("\n🏷️  5. Setting Subscription Prices...");
    const subscriptionManager = await ethers.getContractAt("SubscriptionManagerFacet", diamondAddress);

    for (const tier of CONFIG.pricing) {
        const priceWei = ethers.parseEther(tier.price);
        process.stdout.write(`   - Setting ${tier.name} (Tier ${tier.tierId}) to ${tier.price} ETH... `);
        
        const priceTx = await subscriptionManager.setPriceForTier(tier.tierId, priceWei);
        await priceTx.wait();
        console.log("✅ Done.");
    }

    console.log("\n=================================================");
    console.log("🎉 DEPLOYMENT FINISHED SUCCESSFULLY");
    console.log(`📍 Diamond Address: ${diamondAddress}`);
    console.log("=================================================");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("\n❌ FATAL ERROR:", error);
        process.exit(1);
    });
