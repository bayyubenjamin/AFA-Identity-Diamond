import { ethers } from "ethers";

const RPC_URL = process.env.MONAD_RPC_URL || "https://testnet-rpc.monad.xyz";
const provider = new ethers.JsonRpcProvider(RPC_URL);

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

async function main() {
  for (const [name, addr] of Object.entries(contracts)) {
    try {
      const deployed = await provider.getCode(addr);
      if (deployed === "0x") {
        console.log(`❌ ${name} (${addr}) tidak ada di chain`);
        continue;
      }
      console.log(`✅ ${name} (${addr}) bytecode length: ${deployed.length / 2} bytes`);
    } catch (err) {
      console.error(`⚠️ Gagal ambil ${name}:`, err.message);
    }
  }
}

main();

