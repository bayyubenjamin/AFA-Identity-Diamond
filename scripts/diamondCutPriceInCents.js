const { ethers } = require("hardhat");

async function main() {
  // Ganti dengan alamat diamond kamu
  const diamondAddress = "0x901b6FDb8FAadfe874B0d9A4e36690Fd8ee1C4cD";
  // Ganti dengan alamat facet yang benar
  const facetAddress = "0xA6dfeAd9F0eb041865187356956b5493b9B1c1d2";

  // Selector dari priceInCents()
  const selector = ethers.utils.id("priceInCents()").substring(0, 10); // hasil: 0xd6b98d54

  // Ambil contract diamondCut interface
  const diamondCut = await ethers.getContractAt("IDiamondCut", diamondAddress);

  const FacetCutAction = { Add: 0, Replace: 1, Remove: 2 };

  // Prepare diamondCut
  const cut = [{
    facetAddress: facetAddress,
    action: FacetCutAction.Add,
    functionSelectors: [selector]
  }];

  // Lakukan diamondCut
  const tx = await diamondCut.diamondCut(
    cut,
    ethers.constants.AddressZero,
    "0x"
  );
  console.log("DiamondCut tx sent:", tx.hash);
  await tx.wait();
  console.log("DiamondCut complete!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
