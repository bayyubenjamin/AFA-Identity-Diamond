const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    const targetNonce = 8; // GANTI ANGKA INI JIKA DAPAT ERROR NONCE YANG BERBEDA LAGI

    console.log(`\n============== SCRIPT PEMBERSIH NONCE ==============`);
    console.log(`Akun Target: ${deployer.address}`);
    console.log(`Mencoba mengirim transaksi dengan Nonce: ${targetNonce}`);
    console.log(`====================================================\n`);

    try {
        // Mengirim 0 HLS ke alamat sendiri untuk "membersihkan" nonce
        const tx = await deployer.sendTransaction({
            to: deployer.address,
            value: ethers.parseEther("0"),
            nonce: targetNonce,
            // Kita set gas secara manual untuk memastikan transaksi masuk
            gasLimit: 30000, 
            gasPrice: ethers.parseUnits("2", "gwei") // Menggunakan 2 Gwei sebagai harga gas
        });

        console.log(`🚀 Transaksi pembersih dikirim...`);
        console.log(`   Hash: ${tx.hash}`);
        console.log(`   Menunggu konfirmasi...`);

        // Menunggu transaksi selesai
        await tx.wait(1);

        console.log(`\n✅ SUKSES! Transaksi dengan nonce ${targetNonce} berhasil dikonfirmasi.`);
        console.log(`✅ Akun lo seharusnya sudah tidak tersumbat lagi.`);
        console.log(`\n👉 Langkah selanjutnya:`);
        console.log(`   1. Reset akun di MetaMask (Settings > Advanced > Reset Account).`);
        console.log(`   2. Jalankan kembali skrip deploy utama: npx hardhat run scripts/deployDiamondFull.js --network helios`);
        console.log(`====================================================\n`);

    } catch (error) {
        console.error("\n❌ GAGAL mengirim transaksi pembersih.");
        console.error("   Pastikan akun punya cukup HLS untuk bayar gas.");
        console.error("   Error:", error.message);
        process.exit(1);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
