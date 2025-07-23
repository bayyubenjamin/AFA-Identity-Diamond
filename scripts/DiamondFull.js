const { ethers } = require("hardhat");
const { FacetNames } = require("../diamondConfig.js");

// Fungsi helper untuk mendapatkan function selector
function getSelector(signature) {
    return ethers.id(signature).substring(0, 10);
}

// Fungsi utama
async function main() {
    const [deployer] = await ethers.getSigners();
    const verifierWalletAddress = "0xE0F4e897D99D8F7642DaA807787501154D316870";
    
    console.log("🔨 Deploying contracts with the account:", deployer.address);
    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("💰 Account balance:", ethers.formatEther(balance));

    // --- SOLUSI NONCE ERROR ---
    // 1. Dapatkan nonce terbaru dari jaringan secara manual
    let nonce = await ethers.provider.getTransactionCount(deployer.address, "latest");
    console.log(`\n🕵️  Starting nonce: ${nonce}`);

    // Deploy Facets secara sekuensial dengan nonce manual
    console.log("\n🚀 Deploying facets one by one...");
    const facetContracts = {};
    for (const facetName of FacetNames) {
        try {
            console.log(`   -> Deploying ${facetName} with nonce ${nonce}...`);
            const FacetFactory = await ethers.getContractFactory(facetName);
            
            // 2. Kirim transaksi deploy dengan nonce yang sudah ditentukan
            const facet = await FacetFactory.deploy({ nonce: nonce });
            await facet.waitForDeployment();
            
            facetContracts[facetName] = facet;
            console.log(`✅ ${facetName} deployed to: ${await facet.getAddress()}`);
            
            // 3. Naikkan nonce untuk transaksi berikutnya
            nonce++;

        } catch (e) {
            console.error(`\n❌❌❌ FAILED TO DEPLOY ${facetName} ❌❌❌`);
            console.error(e);
            process.exit(1);
        }
    }

    // Deploy Diamond
    console.log(`\n💎 Deploying Diamond with nonce ${nonce}...`);
    const DiamondFactory = await ethers.getContractFactory("Diamond");
    const diamondContract = await DiamondFactory.deploy(
        deployer.address,
        await facetContracts["DiamondCutFacet"].getAddress(),
        { nonce: nonce } // Gunakan nonce manual
    );
    await diamondContract.waitForDeployment();
    nonce++; // Naikkan nonce setelah deploy Diamond
    const diamondAddress = await diamondContract.getAddress();
    console.log(`✅ Diamond proxy deployed to: ${diamondAddress}`);

    // Construct Diamond Cut
    console.log("\n🧩 Constructing Diamond Cut...");
    const cut = [];
    // Daftar selector tetap sama
    const selectorsMap = {
        DiamondLoupeFacet: ["facets()", "facetFunctionSelectors(address)", "facetAddress(bytes4)", "supportsInterface(bytes4)"],
        OwnershipFacet: ["owner()", "transferOwnership(address)", "withdraw()"],
        IdentityCoreFacet: ["mintIdentity(bytes)", "getIdentity(address)", "verifier()", "baseURI()", "name()", "symbol()", "balanceOf(address)", "ownerOf(uint256)", "tokenURI(uint256)", "initialize(address,string)"],
        SubscriptionManagerFacet: ["setPriceForTier(uint8,uint256)", "getPriceForTier(uint8)", "upgradeToPremium(uint256,uint8)", "getPremiumExpiration(uint256)", "isPremium(uint256)"],
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

    console.log(`\n🚀 Performing diamondCut with nonce ${nonce}...`);
    const tx = await diamondCutInstance.diamondCut(cut, await initFacet.getAddress(), functionCall, { nonce: nonce });
    await tx.wait();
    nonce++;
    console.log("✅ DiamondCut and initialization successful.");

    // Mengatur harga untuk setiap paket premium
    console.log("\n🛠️  Setting initial prices for subscription tiers...");
    const subscriptionManager = await ethers.getContractAt("SubscriptionManagerFacet", diamondAddress);
    const prices = {
        oneMonth: ethers.parseEther("0.0004"),
        sixMonths: ethers.parseEther("0.0025"),
        oneYear: ethers.parseEther("0.005")
    };

    // Mengatur harga dengan nonce manual
    console.log(`   - Setting 1-Month price with nonce ${nonce}...`);
    await (await subscriptionManager.setPriceForTier(0, prices.oneMonth, { nonce: nonce })).wait();
    nonce++;

    console.log(`   - Setting 6-Month price with nonce ${nonce}...`);
    await (await subscriptionManager.setPriceForTier(1, prices.sixMonths, { nonce: nonce })).wait();
    nonce++;

    console.log(`   - Setting 1-Year price with nonce ${nonce}...`);
    await (await subscriptionManager.setPriceForTier(2, prices.oneYear, { nonce: nonce })).wait();
    nonce++;
    
    console.log("✅ Initial prices for all tiers have been set.");
    console.log("\n🎉 Deployment complete! Diamond is ready at:", diamondAddress);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Uncaught error in script:", error);
        process.exit(1);
    });
