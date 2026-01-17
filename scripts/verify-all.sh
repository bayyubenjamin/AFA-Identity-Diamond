#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

NET="monadTestnet"

# ===== Alamat hasil deploy kamu =====
DIAMOND_ADDR="0x17388b3f57Ab6188f6f9A88421f770a7A0f70332"
CUT_ADDR="0xd9aB239C897A1595df704124c0bD77560CA3655F"
LOUPE_ADDR="0x2e2480Ed093512A1B089A31DcE5Ffbd531Ec16A2"
OWN_ADDR="0x1771Ada0617C59a7feb0D49AA2B2D8c91a593B48"
ENUM_ADDR="0x2E386d5Bd09c94aa795b0979BC470E5cAdb9eeDE"
CORE_ADDR="0x48d78F5E5CA178006f1F5F36e5404dfEdc628480"
ATTEST_ADDR="0xaE7Eeaa6Ac1DA6346384268996F2044CE8e2f8C1"
SUB_ADDR="0x27C94d767245a20A0EEA4299eFcB279b1b7aeA02"
ADMIN_ADDR="0xaCfC87E78C2582674fDABdDBc966CBFce7805566"

OWNER_ADDR="0xC25F0BFc89859C7076C5400968A900323b48005d"

# ===== Guard: pastikan Hardhat lokal ada =====
if ! [ -d node_modules/hardhat ]; then
  echo "ℹ️  Hardhat lokal belum ada. Menginstall stack minimal v2 (kompatibel CJS) ..."
  npm i -D hardhat@^2.26.3 @nomicfoundation/hardhat-verify@^2.1.1 @nomicfoundation/hardhat-ethers@^3.1.0 typescript ts-node --legacy-peer-deps
fi

echo "🔎 Hardhat versi lokal:"
npx hardhat --version || (echo "❌ Gagal menjalankan Hardhat lokal" && exit 1)

# ===== Info penting untuk Sourcify =====
echo "ℹ️  Pastikan di hardhat.config.ts:"
echo "    sourcify.enabled = true (apiUrl: sourcify-api-monad.blockvision.org, browserUrl: testnet.monadexplorer.com)"
echo "    etherscan.enabled = false"
echo

# ===== Helper verifikasi yang tidak menghentikan proses jika satu gagal =====
verify () {
  local address="$1"
  shift || true
  echo "🔐 Verifying $address ..."
  if npx hardhat verify --network "$NET" "$address" "$@" ; then
    echo "✅ Verified $address"
  else
    echo "⚠️  Verify gagal/skip untuk $address (lanjut yang lain)."
  fi
  echo
}

# ===== Compile dulu biar metadata sama =====
npx hardhat compile

# ===== Diamond (constructor: owner, diamondCutFacet) =====
verify "$DIAMOND_ADDR" "$OWNER_ADDR" "$CUT_ADDR"

# ===== Facets (tanpa constructor args) =====
verify "$CUT_ADDR"
verify "$LOUPE_ADDR"
verify "$OWN_ADDR"
verify "$ENUM_ADDR"
verify "$CORE_ADDR"
verify "$ATTEST_ADDR"
verify "$SUB_ADDR"
verify "$ADMIN_ADDR"

# ===== Explorer helper =====
echo "🔗 Explorer:"
echo "  Diamond:                https://testnet.monadexplorer.com/address/$DIAMOND_ADDR"
echo "  DiamondCutFacet:        https://testnet.monadexplorer.com/address/$CUT_ADDR"
echo "  DiamondLoupeFacet:      https://testnet.monadexplorer.com/address/$LOUPE_ADDR"
echo "  OwnershipFacet:         https://testnet.monadexplorer.com/address/$OWN_ADDR"
echo "  IdentityEnumerableFacet:https://testnet.monadexplorer.com/address/$ENUM_ADDR"
echo "  IdentityCoreFacet:      https://testnet.monadexplorer.com/address/$CORE_ADDR"
echo "  AttestationFacet:       https://testnet.monadexplorer.com/address/$ATTEST_ADDR"
echo "  SubscriptionManager:    https://testnet.monadexplorer.com/address/$SUB_ADDR"
echo "  TestingAdminFacet:      https://testnet.monadexplorer.com/address/$ADMIN_ADDR"

echo "🎉 Selesai: cek status di tab Contracts (Sourcify) pada masing-masing halaman."

