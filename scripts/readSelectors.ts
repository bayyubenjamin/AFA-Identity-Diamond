// scripts/readSelectors.ts
import { ethers } from "hardhat";

async function main() {
  const diamondAddress = "0xd9aB239C897A1595df704124c0bD77560CA3655F";
  const loupe = await ethers.getContractAt("DiamondLoupeFacet", diamondAddress);

  const facets = await loupe.facets();
  for (const facet of facets) {
    console.log(`\nFacet at: ${facet.facetAddress}`);
    for (const selector of facet.functionSelectors) {
      console.log(`  Selector: ${selector}`);
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

