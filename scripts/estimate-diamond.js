/* eslint-disable no-console */
const hre = require("hardhat");
const { ethers } = hre;
require("dotenv").config();

const { FacetNames } = require("../diamondConfig.js"); // same as deploy

// ===== Konfigurasi yang sama dengan skrip deploy-mu =====
const verifierWalletAddress = "0xE0F4e897D99D8F7642DaA807787501154D316870";
const INIT_BASE_URI = "https://cxoykbwigsfheaegpwke.supabase.co/functions/v1/metadata/";

// Daftar selector persis dari skrip deploy kamu
const selectorsMap = {
  DiamondLoupeFacet: [
    "facets()", "facetFunctionSelectors(address)", "facetAddress(bytes4)", "supportsInterface(bytes4)"
  ],
  OwnershipFacet: [
    "owner()", "transferOwnership(address)", "withdraw()"
  ],
  IdentityCoreFacet: [
    "mintIdentity(bytes)", "getIdentity(address)", "verifier()", "baseURI()", "name()", "symbol()",
    "balanceOf(address)", "ownerOf(uint256)", "tokenURI(uint256)", "initialize(address,string)"
  ],
  SubscriptionManagerFacet: [
    "setPriceForTier(uint8,uint256)", "getPriceForTier(uint8)", "upgradeToPremium(uint256,uint8)",
    "getPremiumExpiration(uint256)", "isPremium(uint256)"
  ],
  AttestationFacet: [
    "attest(bytes32,bytes32)", "getAttestation(bytes32)"
  ],
  TestingAdminFacet: [
    "adminMint(address)"
  ],
  IdentityEnumerableFacet: [
    "totalSupply()", "tokenByIndex(uint256)", "tokenOfOwnerByIndex(address,uint256)"
  ],
};

// Harga yang sama dengan deploy script
const SUB_PRICES = {
  oneMonth: ethers.parseEther("0.0004"),
  sixMonths: ethers.parseEther("0.0025"),
  oneYear: ethers.parseEther("0.005"),
};

const FacetCutAction = { Add: 0, Replace: 1, Remove: 2 };

// ===== formatting =====
const fmtETH = (wei) => ethers.formatEther(wei);
const fmtGwei = (wei) => ethers.formatUnits(wei, "gwei");

// selector helper (mirror deploy script)
function getSelector(signature) {
  return ethers.id(signature).substring(0, 10);
}

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer (forked local):", deployer.address);

  // gas price (v6) + fallback + override
  let gasPrice = (await ethers.provider.getFeeData()).gasPrice;
  if (!gasPrice) gasPrice = BigInt(await hre.network.provider.send("eth_gasPrice", []));
  if (!gasPrice || gasPrice === 0n) gasPrice = 1_000_000_000n; // 1 gwei

  const FORCE_GWEI = process.env.FORCE_GWEI ? Number(process.env.FORCE_GWEI) : null;
  if (FORCE_GWEI && FORCE_GWEI > 0) {
    gasPrice = BigInt(Math.round(FORCE_GWEI * 1e9));
    console.log("Override gasPrice via FORCE_GWEI:", FORCE_GWEI, "gwei");
  }
  console.log("Live gasPrice:", Number(gasPrice) / 1e9, "gwei");

  const ETH_IDR = process.env.ETH_IDR ? Number(process.env.ETH_IDR) : null;
  if (ETH_IDR) console.log("Kurs manual ETH/IDR:", ETH_IDR.toLocaleString("id-ID"));

  const APPLY_CUT_ON_FORK = (process.env.APPLY_CUT_ON_FORK ?? "true").toLowerCase() !== "false";

  await hre.run("compile");

  // ===== ambil FQN artifacts agar nama path pasti benar =====
  const allFQNs = await hre.artifacts.getAllFullyQualifiedNames();
  const need = (hint) => {
    const hit = allFQNs.filter(
      (n) => n.endsWith(":" + hint) || n.includes("/" + hint + ".sol:" + hint)
    );
    if (hit.length === 0) throw new Error("Artifact not found for: " + hint);
    if (hit.length > 1) {
      console.log("Multiple artifacts for", hint, "→ pakai index 0:", hit);
    }
    return hit[0];
  };
  const FQN = {
    Diamond: need("Diamond"),
    DiamondCutFacet: need("DiamondCutFacet"),
    DiamondLoupeFacet: need("DiamondLoupeFacet"),
    OwnershipFacet: need("OwnershipFacet"),
    IdentityCoreFacet: need("IdentityCoreFacet"),
    IdentityEnumerableFacet: need("IdentityEnumerableFacet"),
    AttestationFacet: need("AttestationFacet"),
    SubscriptionManagerFacet: need("SubscriptionManagerFacet"),
    TestingAdminFacet: allFQNs.some((n) => n.endsWith(":TestingAdminFacet") || n.includes("/TestingAdminFacet.sol:TestingAdminFacet"))
      ? need("TestingAdminFacet")
      : null,
    IDiamondCut: need("IDiamondCut"),
  };

  // ===== helper deploy (di fork; tidak broadcast) =====
  const costs = [];
  async function deployFQN(fqn, args = []) {
    const artifact = await hre.artifacts.readArtifact(fqn);
    if (!artifact.bytecode || artifact.bytecode === "0x") {
      throw new Error(`Bytecode kosong untuk ${fqn} (kemungkinan abstract/interface/nama salah)`);
    }
    const Factory = await ethers.getContractFactory(fqn);
    const c = await Factory.deploy(...args);
    const r = await c.deploymentTransaction().wait();
    const addr = await c.getAddress();
    const gasUsed = r.gasUsed; // BigInt
    const feeWei = gasUsed * gasPrice;
    costs.push({ kind: "deploy", name: fqn, address: addr, gas: gasUsed, feeWei });
    console.log(`Deployed ${fqn} @ ${addr} | gasUsed=${gasUsed} | fee≈${fmtETH(feeWei)} ETH`);
    return c;
  }

  // ===== 1) Deploy facets sesuai FacetNames (persis deploy script) =====
  console.log("\n🚀 Deploying facets (order from FacetNames)...");
  const facetContracts = {};
  for (const facetName of FacetNames) {
    const fqn = FQN[facetName];
    if (!fqn) {
      console.log(`⚠️  Skip ${facetName} (artifact tidak ditemukan di FQN mapping)`);
      continue;
    }
    facetContracts[facetName] = await deployFQN(fqn);
  }

  // ===== 2) Deploy Diamond (owner, diamondCutFacet) =====
  const DiamondFactory = await ethers.getContractFactory(FQN.Diamond);
  const diamond = await DiamondFactory.deploy(
    deployer.address,
    await facetContracts["DiamondCutFacet"].getAddress()
  );
  const dr = await diamond.deploymentTransaction().wait();
  const diamondAddr = await diamond.getAddress();
  const diamondGas = dr.gasUsed;
  const diamondFee = diamondGas * gasPrice;
  costs.push({ kind: "deploy", name: FQN.Diamond, address: diamondAddr, gas: diamondGas, feeWei: diamondFee });
  console.log(`Deployed ${FQN.Diamond} @ ${diamondAddr} | gasUsed=${diamondGas} | fee≈${fmtETH(diamondFee)} ETH`);

  // ===== 3) diamondCut — bangun cut dari selectorsMap (de-dupe) =====
  const seen = new Set(); // selector bytes4 yang sudah dipakai
  const cut = [];
  const dupLog = [];

  for (const facetName of FacetNames) {
    if (facetName === "DiamondCutFacet") continue; // sama seperti deploy script
    const selectors = (selectorsMap[facetName] || []).map(getSelector);

    const filtered = [];
    for (const sel of selectors) {
      if (seen.has(sel)) {
        dupLog.push({ facet: facetName, selector: sel });
        continue;
      }
      seen.add(sel);
      filtered.push(sel);
    }
    if (filtered.length > 0) {
      cut.push({
        facetAddress: await facetContracts[facetName].getAddress(),
        action: FacetCutAction.Add,
        functionSelectors: filtered,
      });
    }
  }

  if (dupLog.length > 0) {
    console.log("\n[Info] Duplikat selector dibuang (agar diamondCut tidak revert):");
    for (const d of dupLog) console.log(`- ${d.selector} @ ${d.facet}`);
  }

  const IDiamondCut = await ethers.getContractAt(FQN.IDiamondCut, diamondAddr);

  // initializer: IdentityCoreFacet.initialize(verifier, baseURI)
  const initFacet = facetContracts["IdentityCoreFacet"];
  const functionCall = initFacet.interface.encodeFunctionData("initialize", [
    verifierWalletAddress,
    INIT_BASE_URI,
  ]);

  // ===== GasPriceOracle untuk L1 fee (OP Stack / Base) =====
  const GPO = await ethers.getContractAt(
    [
      "function getL1Fee(bytes data) view returns (uint256)",
      "function l1BaseFee() view returns (uint256)",
      "function overhead() view returns (uint256)",
      "function scalar() view returns (uint256)",
      "function decimals() view returns (uint256)"
    ],
    "0x420000000000000000000000000000000000000F"
  );

  // encode call diamondCut
  const dataCut = IDiamondCut.interface.encodeFunctionData("diamondCut", [
    cut,
    await initFacet.getAddress(),
    functionCall,
  ]);

  // L1 fee diamondCut (estimate)
  let l1FeeDiamondCut = 0n;
  try {
    l1FeeDiamondCut = await GPO.getL1Fee(dataCut);
    console.log(`Estimated L1 fee (diamondCut): ${fmtETH(l1FeeDiamondCut)} ETH`);
  } catch (e) {
    console.log("[WARN] gagal mengambil L1 fee diamondCut:", e.message || e);
  }

  // L2 gas diamondCut (estimate)
  let gasDiamondCut;
  try {
    gasDiamondCut = await ethers.provider.estimateGas({
      from: deployer.address,
      to: diamondAddr,
      data: dataCut,
      value: 0,
    });
  } catch (e) {
    console.error("\n[WARN] estimateGas diamondCut gagal. Detail:", e.message || e);
    throw e;
  }
  const feeDiamondCutL2_est = gasDiamondCut * gasPrice;
  console.log(`\nEstimate diamondCut(+init) gas(L2)=${gasDiamondCut} | fee(L2)≈${fmtETH(feeDiamondCutL2_est)} ETH`);
  if (l1FeeDiamondCut > 0n) {
    console.log(`Estimate diamondCut L1≈${fmtETH(l1FeeDiamondCut)} ETH`);
    console.log(`diamondCut TOTAL (estimate) ≈ ${fmtETH(feeDiamondCutL2_est + l1FeeDiamondCut)} ETH`);
  }

  // === APPLY CUT DI FORK (agar fungsi Diamond ada) ===
  let gasDiamondCut_receipt = null;
  if (APPLY_CUT_ON_FORK) {
    console.log("\n[APPLY] Mengirim tx diamondCut(+init) di fork (tidak broadcast)...");
    const tx = await IDiamondCut.diamondCut(cut, await initFacet.getAddress(), functionCall);
    const rc = await tx.wait();
    gasDiamondCut_receipt = rc.gasUsed;
    const feeL2_real = gasDiamondCut_receipt * gasPrice;
    console.log(`diamondCut applied. gasUsed=${gasDiamondCut_receipt} | fee(L2)≈${fmtETH(feeL2_real)} ETH`);
    // masukin ke breakdown pakai angka real (bukan estimate)
    costs.push({ kind: "call", name: "diamondCut(+init) — L2 gas (applied)", gas: gasDiamondCut_receipt, feeWei: feeL2_real });
    if (l1FeeDiamondCut > 0n) costs.push({ kind: "call", name: "diamondCut(+init) — L1 data", gas: 0n, feeWei: l1FeeDiamondCut });
  } else {
    // kalau tidak apply, simpan versi estimate supaya tetap ada di breakdown
    costs.push({ kind: "call", name: "diamondCut(+init) — L2 gas (estimate)", gas: gasDiamondCut, feeWei: feeDiamondCutL2_est });
    if (l1FeeDiamondCut > 0n) costs.push({ kind: "call", name: "diamondCut(+init) — L1 data", gas: 0n, feeWei: l1FeeDiamondCut });
  }

  // ===== 4) Estimasi 3 tx setPriceForTier (seperti deploy) =====
  console.log("\n🛠️  Estimating setPriceForTier tx...");
  if (!APPLY_CUT_ON_FORK) {
    console.log("SKIP: APPLY_CUT_ON_FORK=false → fungsi belum ada di Diamond. Set APPLY_CUT_ON_FORK=true untuk mengestimasi tx harga.");
  } else {
    const subMgr = await ethers.getContractAt(FQN.SubscriptionManagerFacet, diamondAddr);
    const priceCalls = [
      { label: "setPriceForTier(0, oneMonth)", args: [0, SUB_PRICES.oneMonth] },
      { label: "setPriceForTier(1, sixMonths)", args: [1, SUB_PRICES.sixMonths] },
      { label: "setPriceForTier(2, oneYear)", args: [2, SUB_PRICES.oneYear] },
    ];

    for (const call of priceCalls) {
      const data = subMgr.interface.encodeFunctionData("setPriceForTier", call.args);

      // L1 fee untuk tiap tx harga
      let l1Fee = 0n;
      try { l1Fee = await GPO.getL1Fee(data); } catch {}

      // L2 gas estimate
      const gas = await ethers.provider.estimateGas({
        from: deployer.address,
        to: diamondAddr,
        data,
        value: 0,
      });

      const feeL2 = gas * gasPrice;
      const total = feeL2 + l1Fee;

      costs.push({ kind: "call", name: call.label + " — L2 gas", gas, feeWei: feeL2 });
      if (l1Fee > 0n) costs.push({ kind: "call", name: call.label + " — L1 data", gas: 0n, feeWei: l1Fee });

      console.log(`- ${call.label}: gas(L2)≈${gas} | fee(L2)≈${fmtETH(feeL2)} ETH${l1Fee > 0n ? ` | L1≈${fmtETH(l1Fee)} ETH` : ""}`);
    }
  }

  // ===== 5) Rekap =====
  const totalGas = costs.reduce((a, c) => a + c.gas, 0n);
  const totalWei = costs.reduce((a, c) => a + c.feeWei, 0n);

  console.log("\n===== BREAKDOWN =====");
  for (const c of costs) {
    console.log(`${c.kind.toUpperCase()} - ${c.name} | gas=${c.gas.toString()} | fee≈${fmtETH(c.feeWei)} ETH`);
  }

  // L2-only subtotal (exclude semua entri "— L1 data")
  const l2OnlyWei = costs
    .filter((c) => !c.name.includes("— L1 data"))
    .reduce((a, c) => a + c.feeWei, 0n);

  console.log("\n===== SUBTOTAL (L2 execution only) =====");
  console.log("Total gas:", totalGas.toString());
  console.log("GasPrice:", fmtGwei(gasPrice), "gwei");
  console.log("Total fee:", fmtETH(l2OnlyWei), "ETH");
  if (ETH_IDR) {
    const idr = Number(fmtETH(l2OnlyWei)) * ETH_IDR;
    console.log("≈", idr.toLocaleString("id-ID"), "IDR (tanpa L1 data fee)");
  }

  console.log("\n===== ESTIMASI TOTAL (L2 + L1 parsial) =====");
  console.log("Total fee (ETH):", fmtETH(totalWei));
  if (ETH_IDR) {
    const idrAll = Number(fmtETH(totalWei)) * ETH_IDR;
    console.log("≈", idrAll.toLocaleString("id-ID"), "IDR");
  }

  console.log("\nCatatan:");
  console.log("- Ini di FORK, tidak broadcast. Aman.");
  console.log("- L1 data fee kontrak deploy individual tidak dihitung (butuh tx nyata). Kita hitung L1 untuk tx ber-calldata (diamondCut & price set).");
  console.log("- Urutan, selector, init, dan 3 tx harga sama persis dengan skrip deploy kamu.");
  console.log("- Simulasi gwei lain: FORCE_GWEI=0.3 ETH_IDR=75000000 npx hardhat run scripts/estimate-diamond.js");
  console.log("- Set APPLY_CUT_ON_FORK=false jika ingin hanya estimasi tanpa apply (estimasi setPrice akan di-skip).");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

