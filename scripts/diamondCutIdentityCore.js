const { ethers } = require("hardhat");

async function main() {
  // GANTI dengan address deploy-mu!
  const diamondAddress = "0x901b6FDb8FAadfe874B0d9A4e36690Fd8ee1C4cD";
  const identityCoreFacetAddress = "0x3abbCDB5d61d14948DEe784b7B17Dc51E9eBe189";

  if (
    !diamondAddress.startsWith("0x") ||
    !identityCoreFacetAddress.startsWith("0x")
  ) {
    throw new Error("Ganti semua address dengan address ETH valid!");
  }

  const identityCoreFacet = await ethers.getContractAt("IdentityCoreFacet", identityCoreFacetAddress);

  const selectors = [
    identityCoreFacet.interface.getFunction("ownerOf").selector,
    identityCoreFacet.interface.getFunction("balanceOf").selector,
    identityCoreFacet.interface.getFunction("tokenURI").selector,
    identityCoreFacet.interface.getFunction("name").selector,
    identityCoreFacet.interface.getFunction("symbol").selector,
    identityCoreFacet.interface.getFunction("approve").selector,
    identityCoreFacet.interface.getFunction("getApproved").selector,
    identityCoreFacet.interface.getFunction("setApprovalForAll").selector,
    identityCoreFacet.interface.getFunction("isApprovedForAll").selector,
    identityCoreFacet.interface.getFunction("transferFrom").selector,
    identityCoreFacet.interface.getFunction("safeTransferFrom(address,address,uint256)").selector,
    identityCoreFacet.interface.getFunction("safeTransferFrom(address,address,uint256,bytes)").selector,
    identityCoreFacet.interface.getFunction("supportsInterface").selector
  ];

  const diamondCut = await ethers.getContractAt("IDiamondCut", diamondAddress);
  const tx = await diamondCut.diamondCut(
    [
      [identityCoreFacetAddress, 0, selectors]
    ],
    "0x0000000000000000000000000000000000000000", // Fix AddressZero
    "0x"
  );
  await tx.wait();

  console.log("DiamondCut for IdentityCoreFacet selectors SUCCESS!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
