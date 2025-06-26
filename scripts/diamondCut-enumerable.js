const { ethers } = require("hardhat");

async function main() {
  const diamondAddress = "0x901b6FDb8FAadfe874B0d9A4e36690Fd8ee1C4cD"; // ← Ganti dengan alamat proxy diamond kamu!
  const facetAddress = "0xD3e643C914f2c02d74b6699494629b17f0750Cdb";

  const selectors = [
    "0x2f745c59", // tokenOfOwnerByIndex(address,uint256)
    "0x18160ddd", // totalSupply()
    "0x4f6ccce7", // tokenByIndex(uint256)
  ];

  // GUNAKAN getContractAt UNTUK INTERFACE!
  const diamondCut = await ethers.getContractAt("IDiamondCut", diamondAddress);

  const cut = [
    {
      facetAddress,
      action: 0, // 0 = Add
      functionSelectors: selectors,
    },
  ];

  const tx = await diamondCut.diamondCut(cut, ethers.ZeroAddress, "0x");
  await tx.wait();
  console.log("Facet ERC721Enumerable berhasil di-diamondCut ke proxy!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
