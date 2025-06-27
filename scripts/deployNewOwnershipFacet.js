const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Mendeploy OwnershipFacet versi baru (dengan .call())...");
  
  const FacetFactory = await ethers.getContractFactory("OwnershipFacet");
  const newOwnershipFacet = await FacetFactory.deploy();

  // PERBAIKAN: Menggunakan .waitForDeployment() dari ethers v6, bukan .deployed()
  await newOwnershipFacet.waitForDeployment(); 
  
  // PERBAIKAN: Menggunakan .getAddress() dari ethers v6 untuk mendapatkan alamat
  const newAddress = await newOwnershipFacet.getAddress();

  console.log("\n✅ OwnershipFacet V2 berhasil di-deploy!");
  console.log("Alamat BARU untuk OwnershipFacet adalah:", newAddress);
  console.log("\n--> Salin alamat baru ini untuk digunakan di skrip upgrade selanjutnya.");
}

main().catch((error) => {
  console.error("❌ Error:", error);
  process.exit(1);
});
