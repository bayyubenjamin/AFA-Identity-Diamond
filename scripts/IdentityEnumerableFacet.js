const hre = require("hardhat");

async function main() {
    const IdentityEnumerableFacet = await hre.ethers.getContractFactory("IdentityEnumerableFacet");
    const facet = await IdentityEnumerableFacet.deploy();
    await facet.deployed();
    console.log("IdentityEnumerableFacet deployed to:", facet.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
