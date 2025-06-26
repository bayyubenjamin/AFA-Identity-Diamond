const hre = require("hardhat");

const DIAMOND_ADDRESS = "0x901b6FDb8FAadfe874B0d9A4e36690Fd8ee1C4cD";
const FACET_ADDRESS = "0x2Fc4C92d5C71f8e05B71DaFc01c6f654E1193529"; // Ganti jika perlu

const diamondCutAbi = [
  "function diamondCut(tuple(address facetAddress,uint8 action,bytes4[] functionSelectors)[] _diamondCut, address _init, bytes _calldata) external"
];

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Using deployer:", deployer.address);

    const diamondCut = new hre.ethers.Contract(DIAMOND_ADDRESS, diamondCutAbi, deployer);
    const facet = await hre.ethers.getContractAt(
        "contracts/facets/IdentityEnumerableFacet.sol:IdentityEnumerableFacet",
        FACET_ADDRESS
    );

    const functionNames = [
        "tokenOfOwnerByIndex(address,uint256)",
        "totalSupply()",
        "tokenByIndex(uint256)"
    ];

    // Ethers v6: get selector via getFunction(fn).selector
    const selectors = functionNames.map(
      fn => facet.interface.getFunction(fn).selector
    );

const FacetCutAction = { Add: 0, Replace: 1, Remove: 2 };
const cut = [
    {
        facetAddress: FACET_ADDRESS,
        action: FacetCutAction.Replace, // <-- ganti jadi Replace
        functionSelectors: selectors
    }
];

    console.log("DiamondCut args:", cut);

    const tx = await diamondCut.diamondCut(
        cut,
        hre.ethers.ZeroAddress,
        "0x"
    );
    console.log("diamondCut tx submitted:", tx.hash);
    await tx.wait();
    console.log("diamondCut complete");
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
