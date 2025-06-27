const { ethers } = require("hardhat");
const { FacetNames } = require("../diamondConfig.js");

// This is a helper function from your old script.
// In ethers v6, it's better to use Contract.interface.getFunction('myFunction').selector,
// but we will keep this for now to match your existing logic.
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
        
        // --- FIX: Use .waitForDeployment() for ethers v6 ---
        await facet.waitForDeployment();
        
        facetContracts[facetName] = facet;
        // --- FIX: Use .getAddress() for ethers v6 ---
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
    const selectorsMap = {
        DiamondLoupeFacet: ["facets()", "facetFunctionSelectors(address)", "facetAddress(bytes4)", "supportsInterface(bytes4)"],
        OwnershipFacet: ["owner()", "transferOwnership(address)", "withdraw()"],
        IdentityCoreFacet: ["mintIdentity(bytes)", "getIdentity(address)", "verifier()", "baseURI()", "name()", "symbol()", "balanceOf(address)", "ownerOf(uint256)", "tokenURI(uint256)", "initialize(address,string)"],
        SubscriptionManagerFacet: ["setPriceInWei(uint256)", "priceInWei()", "upgradeToPremium(uint256)", "getPremiumExpiration(uint256)", "isPremium(uint256)"],
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

    // Set initial price (optional but recommended)
    const initialPriceInWei = ethers.parseEther("0.001"); // Set initial price to 0.001 ETH
    const subscriptionManager = await ethers.getContractAt("SubscriptionManagerFacet", diamondAddress);
    console.log(`\n🛠  Setting initial price to ${ethers.formatEther(initialPriceInWei)} ETH...`);
    const setPriceTx = await subscriptionManager.setPriceInWei(initialPriceInWei);
    await setPriceTx.wait();
    console.log("✅ Initial price has been set.");

    console.log("\n🎉 Deployment complete! Diamond is ready at:", diamondAddress);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Uncaught error in script:", error);
        process.exit(1);
    });
