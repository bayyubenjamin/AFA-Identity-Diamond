// Mengimpor 'hardhat' sebagai modul CommonJS, lalu mengambil 'ethers' darinya.
// Ini adalah perbaikan untuk error "Named export 'ethers' not found".
import pkg from 'hardhat';
const { ethers } = pkg;

async function main() {
  const diamondAddress = "0x901b6FDb8FAadfe874B0d9A4e36690Fd8ee1C4cD"; // Ganti dengan alamat Diamond Anda
  const facetAddress = "0x54d0D81c26E8a9c5C134542FBAA5D96aC5D05f6F";   // SubscriptionManagerFacet

  // PERBAIKAN: ethers.utils.Interface menjadi new ethers.Interface
  const iface = new ethers.Interface([
    "function upgradeToPremium(uint256)",
    "function getPremiumExpiration(uint256)",
    "function isPremium(uint256)"
  ]);

  // getSighash sekarang menjadi getFunction
  const selectors = [
    iface.getFunction("upgradeToPremium").selector,
    iface.getFunction("getPremiumExpiration").selector,
    iface.getFunction("isPremium").selector
  ];

  const cut = [
    {
      facetAddress: facetAddress,
      action: 0, // 0 = Add
      functionSelectors: selectors
    }
  ];

  const diamondCut = await ethers.getContractAt("IDiamondCut", diamondAddress);

  console.log("🛠  Menambahkan fungsi ke Diamond...");

  // PERBAIKAN: ethers.constants.AddressZero menjadi ethers.ZeroAddress
  const tx = await diamondCut.diamondCut(cut, ethers.ZeroAddress, "0x");
  
  console.log("✅ Tx sent:", tx.hash);
  await tx.wait();
  console.log("🎉 Fungsi berhasil ditambahkan ke Diamond!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
