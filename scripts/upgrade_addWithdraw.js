const { ethers } = require("hardhat");

async function main() {
  // --- PASTE ALAMAT BARU ANDA DI SINI ---
  const newOwnershipFacetAddress = "0x8C7dc921FD531C8FbF504e78bb099E726c6459bC"; 

  const diamondAddress = "0x9B0bA25ed4306A6F156F78d820EC563AEa9808D4";
  const selector = ethers.id("withdraw()").substring(0, 10);

  const diamondCut = await ethers.getContractAt("IDiamondCut", diamondAddress);

  const cut = [{
    facetAddress: newOwnershipFacetAddress,
    action: 1, // 1 = Replace
    functionSelectors: [selector]
  }];

  console.log(`🚀 Meng-upgrade fungsi 'withdraw()' ke facet baru di: ${newOwnershipFacetAddress}`);
  const tx = await diamondCut.diamondCut(cut, ethers.ZeroAddress, "0x");
  console.log("Transaksi upgrade dikirim:", tx.hash);
  await tx.wait();
  console.log("✅ Diamond berhasil di-upgrade ke logika yang baru dan aman!");
}

main().catch((error) => { console.error("❌ Error saat upgrade:", error); process.exit(1); });
