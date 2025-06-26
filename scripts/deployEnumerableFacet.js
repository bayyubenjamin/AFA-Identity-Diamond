const hre = require("hardhat"); // <--- hanya satu kali!

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contracts with:", deployer.address);

    const IdentityEnumerableFacet = await hre.ethers.getContractFactory(
        "contracts/facets/IdentityEnumerableFacet.sol:IdentityEnumerableFacet"
    );
    const facet = await IdentityEnumerableFacet.deploy();

    console.log("IdentityEnumerableFacet deployed to:", await facet.getAddress());
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
