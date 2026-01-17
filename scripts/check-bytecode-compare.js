// CommonJS
const fs = require("fs");
const path = require("path");
const { ethers } = require("ethers");

const RPC_URL = process.env.MONAD_RPC_URL || "https://testnet-rpc.monad.xyz";
const provider = new ethers.JsonRpcProvider(RPC_URL);

// alamat on-chain
const contracts = {
  Diamond: "0x17388b3f57Ab6188f6f9A88421f770a7A0f70332",
  DiamondCutFacet: "0xd9aB239C897A1595df704124c0bD77560CA3655F",
  DiamondLoupeFacet: "0x2e2480Ed093512A1B089A31DcE5Ffbd531Ec16A2",
  OwnershipFacet: "0x1771Ada0617C59a7feb0D49AA2B2D8c91a593B48",
  IdentityEnumerableFacet: "0x2E386d5Bd09c94aa795b0979BC470E5cAdb9eeDE",
  IdentityCoreFacet: "0x48d78F5E5CA178006f1F5F36e5404dfEdc628480",
  AttestationFacet: "0xaE7Eeaa6Ac1DA6346384268996F2044CE8e2f8C1",
  SubscriptionManagerFacet: "0x27C94d767245a20A0EEA4299eFcB279b1b7aeA02",
  TestingAdminFacet: "0xaCfC87E78C2582674fDABdDBc966CBFce7805566",
};

function findArtifactForName(name) {
  const root = path.join(process.cwd(), "artifacts", "contracts");
  if (!fs.existsSync(root)) return null;

  const q = [root];
  while (q.length) {
    const dir = q.shift();
    for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, ent.name);
      if (ent.isDirectory()) q.push(full);
      else if (ent.isFile() && ent.name === `${name}.json`) {
        const parent = path.basename(path.dirname(full));
        if (parent === `${name}.sol`) return full;
      }
    }
  }
  return null;
}

const to0x = (v) => (v ? (v.startsWith("0x") ? v : "0x" + v) : "0x");

(async () => {
  for (const [name, addr] of Object.entries(contracts)) {
    try {
      const chain = (await provider.getCode(addr))?.toLowerCase() || "0x";
      if (chain === "0x") {
        console.log(`❌ ${name} (${addr}) tidak ada code di chain`);
        continue;
      }

      const artPath = findArtifactForName(name);
      if (!artPath) {
        console.log(`⚠️  Artifact untuk ${name} tidak ketemu. Jalankan: npx hardhat compile`);
        continue;
      }
      const artifact = JSON.parse(fs.readFileSync(artPath, "utf8"));

      // Hardhat v2: deployedBytecode = string; fallback ke .object kalau ada
      let local = artifact.deployedBytecode;
      if (!local || local.length < 4) local = artifact.deployedBytecode?.object;
      local = to0x(String(local || "")).toLowerCase();

      if (local === "0x") {
        console.log(`⚠️  ${name}: deployedBytecode kosong di artifact (periksa build).`);
        continue;
      }

      if (chain === local) {
        console.log(`✅ MATCH (full) ${name}`);
      } else if (chain.length === local.length) {
        console.log(`🟡 Panjang sama tapi konten beda → ${name} (kemungkinan metadata hash)`);
      } else {
        console.log(
          `🔴 MISMATCH ${name} (on-chain ${chain.length / 2}B vs local ${local.length / 2}B)`
        );
      }
    } catch (e) {
      console.log(`⚠️  Gagal cek ${name}: ${e.message}`);
    }
  }
})();

