// scripts/updateFacets.js
const { ethers } = require("hardhat");
const { getSelectors, FacetCutAction } = require("./libraries/diamond.js");

async function main() {
  const diamondAddress = "ALAMAT_DIAMOND_ANDA_DI_SINI"; // Masukkan alamat yang sudah dideploy
  
  const FacetNames = [
    "ReputationFacet",
    "GovernanceFacet",
    "StakingFacet"
  ];

  const cut = [];

  for (const FacetName of FacetNames) {
    const Facet = await ethers.getContractFactory(FacetName);
    const facet = await Facet.deploy();
    await facet.waitForDeployment(); // Ethers v6 syntax
    console.log(`${FacetName} deployed: ${await facet.getAddress()}`);

    cut.push({
      facetAddress: await facet.getAddress(),
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet)
    });
  }

  // Panggil DiamondCut
  const diamondCut = await ethers.getContractAt("IDiamondCut", diamondAddress);
  const tx = await diamondCut.diamondCut(cut, ethers.ZeroAddress, "0x");
  console.log("Diamond Cut tx:", tx.hash);
  await tx.wait();
  console.log("Facets added successfully!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
