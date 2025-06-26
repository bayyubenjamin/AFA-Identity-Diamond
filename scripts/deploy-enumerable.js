const hre = require("hardhat");

async function main() {
  const Factory = await hre.ethers.getContractFactory("IdentityEnumerableFacet"); // atau ERC721EnumerableFacet
  const facet = await Factory.deploy();
  await facet.waitForDeployment();
  console.log("IdentityEnumerableFacet deployed to:", await facet.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
