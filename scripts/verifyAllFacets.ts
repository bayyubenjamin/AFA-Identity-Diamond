const hre = require("hardhat");

const addresses = [
  "0x42C58e3AdA7BADF565c248bd124C7198Bf3a0d29", // DiamondCutFacet
  "0xbd0E0E87faCF61d4E6E09aD014C757F84191c951", // DiamondLoupeFacet
  "0x978E6DD78a41dF828FeE91EfAEaE6827f058d425", // OwnershipFacet
  "0x1b3CeA9A1A33698c5eFdBF1cEA667Bc5f588030c", // IdentityCoreFacet
  "0x2A4d42DB2cb752d0dE7973cB9582baAae7229cd4", // AttestationFacet
  "0x5f2337639b0d8E6563d2B73f9b126774048a815b", // SubscriptionManagerFacet
  "0x6a86e4dd3d1159795cBebE2aeD97A66be489aF70", // TestingAdminFacet
  // Diamond proxy biasanya tidak perlu diverifikasi, kecuali punya logika (constructor)
];

async function main() {
  for (const addr of addresses) {
    try {
      console.log(`🔍 Verifying: ${addr}`);
      await hre.run("verify:verify", {
        address: addr,
        constructorArguments: [],
      });
      console.log(`✅ Verified: ${addr}`);
    } catch (err) {
      console.error(`❌ Failed: ${addr}`);
      console.error(err.message || err);
    }
  }
}

main();

