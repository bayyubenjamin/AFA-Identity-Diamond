const { ethers } = require("hardhat");

async function main() {
  const proxyAddress = "0xf9B1CF427a562618784B8777003c5Ec4fb95a435"; // GANTI dengan address proxy diamond
  const identityCoreFacet = await ethers.getContractAt("IdentityCoreFacet", proxyAddress);

  const verifier = "0xE0F4e897D99D8F7642DaA807787501154D316870"; // GANTI dengan verifier address
  const baseURI = "https://cxoykbwigsfheaegpwke.supabase.co/functions/v1/metadata/"; // GANTI dengan metadata base URI

  if (
    !proxyAddress.startsWith("0x") ||
    !verifier.startsWith("0x")
  ) {
    throw new Error("Ganti semua address dengan address ETH valid!");
  }

  const tx = await identityCoreFacet.initialize(verifier, baseURI);
  await tx.wait();

  console.log("IdentityCoreFacet initialized with baseURI and verifier!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
