const { ethers } = require("hardhat");
const { FacetNames, DiamondInit } = require("../diamondConfig.js");

function getSelector(signature) {
    return ethers.id(signature).substring(0, 10);
}

// Fungsi untuk mendapatkan semua selector dari sebuah facet
function getSelectors(contract) {
    const signatures = Object.keys(contract.interface.fragments);
    const selectors = signatures.reduce((acc, val) => {
        if (val !== 'init(bytes)') { // jangan sertakan fungsi init
            acc.push(contract.interface.getSighash(val));
        }
        return acc;
    }, []);
    return selectors;
}


async function main() {
    const [deployer] = await ethers.getSigners();
    const verifierWalletAddress = "0xE0F4e897D99D8F7642DaA807787501154D316870";

    console.log("🔨 Deploying contracts with the account:", deployer.address);

    // 1. Deploy Facets
    console.log("\n🚀 Deploying facets...");
    const facetContracts = {};
    for (const facetName of FacetNames) {
        const FacetFactory = await ethers.getContractFactory(facetName);
        const facet = await FacetFactory.deploy();
        await facet.waitForDeployment();
        facetContracts[facetName] = facet;
        console.log(`✅ ${facetName} deployed to: ${await facet.getAddress()}`);
    }

    // 2. Deploy Diamond
    console.log("\n💎 Deploying Diamond...");
    const DiamondFactory = await ethers.getContractFactory("Diamond");
    const diamondContract = await DiamondFactory.deploy(
        deployer.address,
        await facetContracts["DiamondCutFacet"].getAddress()
    );
    await diamondContract.waitForDeployment();
    const diamondAddress = await diamondContract.getAddress();
    console.log(`✅ Diamond proxy deployed to: ${diamondAddress}`);
    
    // 3. Lakukan Diamond Cut untuk SEMUA facet sekaligus
    console.log("\n🧩 Performing DiamondCut to add all facets and initialize...");
    const diamondCutInstance = await ethers.getContractAt("IDiamondCut", diamondAddress);
    
    const selectorsMap = {
        DiamondLoupeFacet: ["facets()", "facetFunctionSelectors(address)", "facetAddress(bytes4)", "supportsInterface(bytes4)"],
        OwnershipFacet: ["owner()", "transferOwnership(address)", "withdraw()"],
        IdentityCoreFacet: ["mintIdentity(bytes)", "getIdentity(address)", "verifier()", "baseURI()", "name()", "symbol()", "balanceOf(address)", "ownerOf(uint256)", "tokenURI(uint256)", "initialize(address,string)"],
        SubscriptionManagerFacet: [
            "setPriceForTier(uint8,uint256)", "getPriceForTier(uint8)", "upgradeToPremium(uint256,uint8)", 
            "getPremiumExpiration(uint256)", "isPremium(uint256)"
        ],
        AttestationFacet: ["attest(bytes32,bytes32)", "getAttestation(bytes32)"],
        TestingAdminFacet: ["adminMint(address)"],
        IdentityEnumerableFacet: ["totalSupply()", "tokenByIndex(uint256)", "tokenOfOwnerByIndex(address,uint256)"]
    };

    const cut = [];
    for (const facetName of FacetNames) {
        // DiamondCutFacet sudah ditambahkan di constructor, jadi kita lewati
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

    // Siapkan panggilan inisialisasi
    const initFacet = facetContracts[DiamondInit];
    const functionCall = initFacet.interface.encodeFunctionData("initialize", [
        verifierWalletAddress,
        "https://cxoykbwigsfheaegpwke.supabase.co/functions/v1/metadata/",
    ]);

    // Lakukan cut dan inisialisasi dalam satu transaksi
    // Menambahkan gasLimit manual untuk stabilitas di L2
    const tx = await diamondCutInstance.diamondCut(cut, await initFacet.getAddress(), functionCall, { gasLimit: 2000000 });
    const receipt = await tx.wait();

    if(receipt.status === 0) {
        throw new Error("DiamondCut transaction failed. The contract may not have been initialized correctly.");
    }
    console.log("✅ DiamondCut and initialization successful.");

    // 4. Set Prices
    console.log("\n🛠️  Setting initial prices for subscription tiers...");
    const subscriptionManager = await ethers.getContractAt("SubscriptionManagerFacet", diamondAddress);
    const prices = {
        oneMonth: ethers.parseEther("0.0004"),
        sixMonths: ethers.parseEther("0.0025"),
        oneYear: ethers.parseEther("0.005")
    };

    let setPriceTx;
    console.log(`   - Setting 1-Month price...`);
    setPriceTx = await subscriptionManager.setPriceForTier(0, prices.oneMonth, { gasLimit: 500000 });
    await setPriceTx.wait();
    
    console.log(`   - Setting 6-Month price...`);
    setPriceTx = await subscriptionManager.setPriceForTier(1, prices.sixMonths, { gasLimit: 500000 });
    await setPriceTx.wait();

    console.log(`   - Setting 1-Year price...`);
    setPriceTx = await subscriptionManager.setPriceForTier(2, prices.oneYear, { gasLimit: 500000 });
    await setPriceTx.wait();
    
    console.log("✅ Initial prices for all tiers have been set.");
    console.log("\n🎉 Deployment complete! Diamond is ready at:", diamondAddress);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Uncaught error in script:", error);
        process.exit(1);
    });
