const { ethers } = require("hardhat");

async function main() {
  const diamondAddress = "0x9B0bA25ed4306A6F156F78d820EC563AEa9808D4";
  
  console.log(`🔍 Memeriksa fungsi di Diamond: ${diamondAddress}`);

  // Menghitung selector untuk fungsi withdraw()
  const withdrawSelector = ethers.id("withdraw()").substring(0, 10);
  console.log(`Selector untuk "withdraw()": ${withdrawSelector}`);

  // Menggunakan DiamondLoupeFacet untuk memeriksa selector
  const loupeFacet = await ethers.getContractAt("IDiamondLoupe", diamondAddress);

  // Menanyakan ke facet mana selector ini terdaftar
  const facetAddress = await loupeFacet.facetAddress(withdrawSelector);

  console.log(`\nAlamat Facet yang terdaftar untuk selector ini: ${facetAddress}`);

  // Membandingkan dengan alamat OwnershipFacet yang seharusnya
  const expectedFacetAddress = "0xd64C1560361a0df0a30F1DE836eB1e496ecA5534"; // Alamat OwnershipFacet Anda

  if (facetAddress.toLowerCase() === "0x0000000000000000000000000000000000000000") {
    console.log("\n❌ HASIL: Gagal! Fungsi 'withdraw()' TIDAK DITEMUKAN di dalam Diamond.");
    console.log("Ini berarti proses upgrade sebelumnya tidak berhasil. Silakan jalankan kembali skrip upgrade.");
  } else if (facetAddress.toLowerCase() === expectedFacetAddress.toLowerCase()) {
    console.log("\n✅ HASIL: Sukses! Fungsi 'withdraw()' SUDAH AKTIF di dalam Diamond.");
    console.log("Masalahnya kemungkinan besar hanya pada cache Etherscan. Coba refresh halaman Etherscan (Ctrl+Shift+R) atau tunggu beberapa saat.");
  } else {
    console.log(`\n⚠️ HASIL: Aneh! Fungsi 'withdraw()' ditemukan, tetapi terdaftar di alamat facet yang salah: ${facetAddress}`);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Error saat memeriksa fungsi:", error);
    process.exit(1);
  });
