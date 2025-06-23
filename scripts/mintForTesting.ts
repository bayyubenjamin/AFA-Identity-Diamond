import { ethers } from "hardhat";

async function main() {
    const [deployer] = await ethers.getSigners();
    
    const diamondAddress = "0x0aF4D85CfB27428799270BECd89505bbD1A07910";
    const recipientAddress = "0xC25F0BFc89859C7076C5400968A900323b48005d";

    if (diamondAddress === "0x..." || recipientAddress === "0x...") {
        console.error("Harap isi alamat Diamond dan alamat penerima di dalam skrip.");
        return;
    }

    console.log(`Mencoba minting NFT dari kontrak Diamond: ${diamondAddress}`);
    console.log(`Admin (pemanggil): ${deployer.address}`);
    console.log(`Penerima: ${recipientAddress}`);

    const testingAdminFacet = await ethers.getContractAt('TestingAdminFacet', diamondAddress);

    try {
        const tx = await testingAdminFacet.connect(deployer).adminMint(recipientAddress);
        console.log("Transaksi dikirim, hash:", tx.hash);
        
        await tx.wait();
        console.log("Transaksi berhasil di-mine!");
        console.log(`✅ NFT berhasil di-mint untuk ${recipientAddress}.`);
        console.log(`Cek transaksinya di: https://sepolia.etherscan.io/tx/${tx.hash}`);

    } catch (error) {
        console.error("Minting gagal:", error);
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
