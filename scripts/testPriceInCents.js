const { ethers } = require("hardhat");

async function main() {
  // Ganti dengan alamat Diamond kamu
  const diamondAddress = "0x901b6FDb8FAadfe874B0d9A4e36690Fd8ee1C4cD";

  // Minimal ABI hanya fungsi priceInCents()
  const abi = [
    "function priceInCents() public view returns (uint256)"
  ];

  // Dapatkan contract instance
  const diamond = await ethers.getContractAt(abi, diamondAddress);

  // Panggil fungsi priceInCents
  const price = await diamond.priceInCents();
  console.log("priceInCents():", price.toString());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
