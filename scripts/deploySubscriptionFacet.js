const { ethers } = require("hardhat");

async function main() {
  const facetFactory = await ethers.getContractFactory("SubscriptionManagerFacet");
  const facet = await facetFactory.deploy();
  await facet.deployed();

  console.log("✅ SubscriptionManagerFacet deployed at:", facet.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

