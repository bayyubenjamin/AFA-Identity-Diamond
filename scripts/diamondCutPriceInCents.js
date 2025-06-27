// Menggunakan cara impor yang kompatibel
const { ethers } = require("hardhat");

async function main() {
  // Ganti dengan alamat diamond kamu
  const diamondAddress = "0x9B0bA25ed4306A6F156F78d820EC563AEa9808D4";
  // Ganti dengan alamat facet yang memiliki fungsi priceInCents()
  // Kemungkinan besar ini adalah SubscriptionManagerFacet
  const facetAddress = "0x600eAF33e044040CEA60f1dE8e15D4cBB5872006";

  // PERBAIKAN: ethers.utils.id menjadi ethers.id
  // Asumsi fungsi yang ingin ditambahkan adalah 'priceInCents()'
  const selector = ethers.id("priceInCents()").substring(0, 10);

  // Ambil contract diamondCut interface
  const diamondCut = await ethers.getContractAt("IDiamondCut", diamondAddress);

  const FacetCutAction = { Add: 0, Replace: 1, Remove: 2 };

  // Prepare diamondCut
  const cut = [{
    facetAddress: facetAddress,
    action: FacetCutAction.Add,
    functionSelectors: [selector]
  }];

  // Lakukan diamondCut
  // PERBAIKAN: ethers.constants.AddressZero menjadi ethers.ZeroAddress
  const tx = await diamondCut.diamondCut(
    cut,
    ethers.ZeroAddress, // Menggunakan properti ethers v6
    "0x"
  );
  console.log("DiamondCut tx sent:", tx.hash);
  await tx.wait();
  console.log("✅ DiamondCut complete! Fungsi 'priceInCents' seharusnya sudah ditambahkan.");
}

// Pola eksekusi standar
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Error:", error);
    process.exit(1);
  });
