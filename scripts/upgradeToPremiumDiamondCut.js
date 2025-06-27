const { ethers } = require("hardhat");

async function main() {
  const diamondAddress = "0xYourDiamondAddress"; // Ganti dengan address Diamond kamu
  const facetAddress = "0xYourFacetAddressWithUpgradeToPremium"; // Ganti dengan facet address yang punya upgradeToPremium

  const diamondCut = await ethers.getContractAt("IDiamondCut", diamondAddress);

  const functionSelectors = [
    ethers.utils.keccak256(Buffer.from("upgradeToPremium(uint256)")).slice(0, 10), // selector: 0x901bf6d8
  ];

  const cut = [
    {
      facetAddress: facetAddress,
      action: 0, // 0 = Add
      functionSelectors: functionSelectors,
    },
  ];

  console.log("Melakukan diamondCut...");
  const tx = await diamondCut.diamondCut(cut, ethers.constants.AddressZero, "0x");
  console.log("Tx dikirim:", tx.hash);
  await tx.wait();
  console.log("✅ Fungsi upgradeToPremium berhasil ditambahkan!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

