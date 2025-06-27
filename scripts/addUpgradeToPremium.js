const { ethers } = require("hardhat");

async function main() {
  const diamondAddress = "0x901b6FDb8FAadfe874B0d9A4e36690Fd8ee1C4cD"; // Ganti dgn Diamond kamu
  const facetAddress = "0x54d0D81c26E8a9c5C134542FBAA5D96aC5D05f6F";  // SubscriptionManagerFacet

  const iface = new ethers.utils.Interface([
    "function upgradeToPremium(uint256)",
    "function getPremiumExpiration(uint256)",
    "function isPremium(uint256)"
  ]);

  const selectors = [
    iface.getSighash("upgradeToPremium(uint256)"),
    iface.getSighash("getPremiumExpiration(uint256)"),
    iface.getSighash("isPremium(uint256)")
  ];

  const cut = [
    {
      facetAddress,
      action: 0, // 0 = Add
      functionSelectors: selectors
    }
  ];

  const diamondCut = await ethers.getContractAt("IDiamondCut", diamondAddress);

  console.log("🛠 Menambahkan fungsi ke Diamond...");
  const tx = await diamondCut.diamondCut(cut, ethers.constants.AddressZero, "0x");
  console.log("✅ Tx sent:", tx.hash);
  await tx.wait();
  console.log("🎉 Fungsi berhasil ditambahkan ke Diamond!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

