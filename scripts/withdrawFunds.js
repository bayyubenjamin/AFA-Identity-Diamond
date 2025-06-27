const { ethers } = require("hardhat");

async function main() {
  const diamondAddress = "0x9B0bA25ed4306A6F156F78d820EC563AEa9808D4";
  const [owner] = await ethers.getSigners();
  
  // Membuat instance dari OwnershipFacet pada alamat Diamond
  const ownershipFacet = await ethers.getContractAt("OwnershipFacet", diamondAddress);
  
  // getBalance() di ethers v6 mengembalikan 'bigint'
  const balanceSebelum = await ethers.provider.getBalance(diamondAddress);
  
  console.log(`Saldo di Diamond sebelum ditarik: ${ethers.formatEther(balanceSebelum)} ETH`);

  // PERBAIKAN: Membandingkan 'bigint' langsung dengan 0n
  if (balanceSebelum === 0n) {
    console.log("Tidak ada dana untuk ditarik.");
    return;
  }

  console.log(`\n💸 Menjalankan fungsi withdraw() untuk mengirim dana ke ${owner.address}...`);

  const tx = await ownershipFacet.withdraw();
  console.log("Transaksi penarikan dikirim:", tx.hash);
  await tx.wait();
  console.log("✅ Penarikan dana berhasil!");

  const balanceSesudah = await ethers.provider.getBalance(diamondAddress);
  
  console.log(`Saldo di Diamond setelah ditarik: ${ethers.formatEther(balanceSesudah)} ETH`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Error saat menarik dana:", error);
    process.exit(1);
  });
