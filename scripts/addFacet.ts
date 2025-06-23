import { ethers } from "hardhat";
import { getSelectors } from "./libraries/diamond";

const diamondAddress = "0xd9aB239C897A1595df704124c0bD77560CA3655F";
const facetName = "IdentityCoreFacet";

async function main() {
  console.log(`🚀 Deploying facet: ${facetName}...`);
  const Facet = await ethers.getContractFactory(facetName);
  const facet = await Facet.deploy();
  await facet.waitForDeployment(); // ethers v6
  const facetAddress = await facet.getAddress();
  console.log(`✅ ${facetName} deployed at: ${facetAddress}`);

  console.log(`🔍 Getting selectors...`);
  const allSelectors = getSelectors(facet);

  console.log(`📡 Getting existing selectors from diamond...`);
  const diamond = await ethers.getContractAt("IDiamondLoupe", diamondAddress);
  const facets = await diamond.facets();

  const existingSelectors = facets.flatMap((f: any) => f.functionSelectors);

  const newSelectors = allSelectors.filter(
    (sel: string) => !existingSelectors.includes(sel)
  );

  if (newSelectors.length === 0) {
    console.log("⚠️  No new selectors to add. All functions already exist.");
    return;
  }

  console.log("✅ New selectors to add:", newSelectors);

  const diamondCut = await ethers.getContractAt("IDiamondCut", diamondAddress);
  const tx = await diamondCut.diamondCut(
    [
      {
        facetAddress,
        action: 0, // Add
        functionSelectors: newSelectors,
      },
    ],
    ethers.ZeroAddress,
    "0x"
  );

  console.log("🔨 diamondCut transaction sent:", tx.hash);
  await tx.wait();
  console.log("🎉 Facet added successfully!");
}

main().catch((err) => {
  console.error("❌ Error adding facet:", err);
  process.exit(1);
});

