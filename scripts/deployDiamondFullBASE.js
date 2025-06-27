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

    console.log("\n💎 Deploying Diamond...");
    const DiamondFactory = await ethers.getContractFactory("Diamond");
    const diamondContract = await DiamondFactory.deploy(
        deployer.address,
        await facetContracts["DiamondCutFacet"].getAddress()
    );
    await diamondContract.waitForDeployment();
    const diamondAddress = await diamondContract.getAddress();
    console.log(`✅ Diamond proxy deployed to: ${diamondAddress}`);

    console.log("\n🧩 Constructing Diamond Cut in batches...");
    const diamondCutInstance = await ethers.getContractAt("IDiamondCut", diamondAddress);

    const selectorsMap = {
        DiamondLoupeFacet: ["facets()", "facetFunctionSelectors(address)", "facetAddress(bytes4)", "supportsInterface(bytes4)"],
        OwnershipFacet: ["owner()", "transferOwnership(address)", "withdraw()"],
        IdentityCoreFacet: ["mintIdentity(bytes)", "getIdentity(address)", "verifier()", "baseURI()", "name()", "symbol()", "balanceOf(address)", "ownerOf(uint256)", "tokenURI(uint256)", "initialize(address,string)"],
        SubscriptionManagerFacet: ["setPriceInWei(uint256)", "priceInWei()", "upgradeToPremium(uint256)", "getPremiumExpiration(uint256)", "isPremium(uint256)"],
        AttestationFacet: ["attest(bytes32,bytes32)", "getAttestation(bytes32)"],
        TestingAdminFacet: ["adminMint(address)"],
        IdentityEnumerableFacet: ["totalSupply()", "tokenByIndex(uint256)", "tokenOfOwnerByIndex(address,uint256)"]
    };
    
    const facetsToAddInBatches = FacetNames.filter(
        name => name !== "DiamondCutFacet" && name !== "DiamondLoupeFacet"
    );

    for (const facetName of facetsToAddInBatches) {
        console.log(`--- ⏳ Preparing to add ${facetName}...`);
        const selectors = (selectorsMap[facetName] || []).map(getSelector);
        if (selectors.length > 0) {
            const cut = [{
                facetAddress: await facetContracts[facetName].getAddress(),
                action: 0, // Add
                functionSelectors: selectors
            }];

            // --- PERBAIKAN DI SINI: Menambahkan gasLimit secara manual ---
            const tx = await diamondCutInstance.diamondCut(cut, ethers.ZeroAddress, "0x", { gasLimit: 800000 });
            console.log(`   > DiamondCut transaction sent for ${facetName}: ${tx.hash}`);
            await tx.wait();
            console.log(`   > ✅ SUCCESS: ${facetName} was added successfully!`);
        }
    }
    console.log("✅ All facets added successfully in batches.");
    
    console.log("\n🚀 Performing initialization...");
    const initFacet = facetContracts["IdentityCoreFacet"];
    const functionCall = initFacet.interface.encodeFunctionData("initialize", [
        verifierWalletAddress,
        "https://cxoykbwigsfheaegpwke.supabase.co/functions/v1/metadata/",
    ]);
    // --- PERBAIKAN DI SINI: Menambahkan gasLimit secara manual ---
    const initTx = await diamondCutInstance.diamondCut([], await initFacet.getAddress(), functionCall, { gasLimit: 800000 });
    await initTx.wait();
    console.log("✅ Diamond initialization successful.");

    const initialPriceInWei = ethers.parseEther("0.001");
    const subscriptionManager = await ethers.getContractAt("SubscriptionManagerFacet", diamondAddress);
    console.log(`\n🛠  Setting initial price to ${ethers.formatEther(initialPriceInWei)} ETH...`);
    const setPriceTx = await subscriptionManager.setPriceInWei(initialPriceInWei);
    await setPriceTx.wait();
    console.log("✅ Initial price has been set.");

    console.log("\n🎉 Deployment complete! Diamond is ready at:", diamondAddress);
}

main().catch((error) => {
    console.error("❌ Uncaught error in script:", error);
    process.exit(1);
});
