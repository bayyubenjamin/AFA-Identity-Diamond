#!/usr/bin/env bash
set -euo pipefail

# ========= Setup & guard =========
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if ! [ -d node_modules/hardhat ]; then
  echo "ℹ️  Hardhat lokal belum ada. Menginstall stack minimal v2 (kompatibel CJS) ..."
  npm i -D hardhat@^2.26.3 @nomicfoundation/hardhat-verify@^2.1.1 @nomicfoundation/hardhat-ethers@^3.1.0 typescript ts-node --legacy-peer-deps
fi

echo "🔎 Hardhat versi lokal:"
npx hardhat --version || (echo "❌ Gagal menjalankan Hardhat lokal" && exit 1)

# Compile dulu biar artifacts up-to-date
echo "🧱 Compile contracts..."
npx hardhat compile

OUT_DIR="flattened"
SAN_DIR="flattened_sanitized"
mkdir -p "$OUT_DIR" "$SAN_DIR"

# ========= Helper flatten + sanitize =========
flatten_and_sanitize () {
  local SRC="$1"
  local OUT="$2"
  local SAN="$3"

  if ! [ -f "$SRC" ]; then
    echo "❌ Source tidak ditemukan: $SRC"
    echo "   Periksa struktur repo kamu. (contoh path Diamond: contracts/diamond/Diamond.sol)"
    exit 1
  fi

  echo "• flatten $SRC → $OUT"
  npx hardhat flatten "$SRC" > "$OUT"

  echo "  sanitize headers → $SAN"
  local SPDX PRAGMA
  SPDX=$(grep -m1 -E '^//\s*SPDX-License-Identifier:' "$OUT" || true)
  PRAGMA=$(grep -m1 -E '^pragma\s+solidity\s+' "$OUT" || true)

  awk '!/^\/\/\s*SPDX-License-Identifier:|^pragma\s+solidity\s+/' "$OUT" > "$SAN.tmp"

  {
    if [[ -n "$SPDX" ]]; then echo "$SPDX"; else echo "// SPDX-License-Identifier: MIT"; fi
    if [[ -n "$PRAGMA" ]]; then echo "$PRAGMA"; else echo "pragma solidity ^0.8.24;"; fi
    echo
    cat "$SAN.tmp"
  } > "$SAN"

  rm -f "$SAN.tmp"
}

# ========= Daftar file sesuai struktur proyekmu =========
flatten_and_sanitize "contracts/diamond/Diamond.sol" \
  "$OUT_DIR/Diamond_flattened.sol" \
  "$SAN_DIR/Diamond_flattened.sol"

flatten_and_sanitize "contracts/facets/DiamondCutFacet.sol" \
  "$OUT_DIR/DiamondCutFacet_flattened.sol" \
  "$SAN_DIR/DiamondCutFacet_flattened.sol"

flatten_and_sanitize "contracts/facets/DiamondLoupeFacet.sol" \
  "$OUT_DIR/DiamondLoupeFacet_flattened.sol" \
  "$SAN_DIR/DiamondLoupeFacet_flattened.sol"

flatten_and_sanitize "contracts/facets/OwnershipFacet.sol" \
  "$OUT_DIR/OwnershipFacet_flattened.sol" \
  "$SAN_DIR/OwnershipFacet_flattened.sol"

flatten_and_sanitize "contracts/facets/IdentityEnumerableFacet.sol" \
  "$OUT_DIR/IdentityEnumerableFacet_flattened.sol" \
  "$SAN_DIR/IdentityEnumerableFacet_flattened.sol"

flatten_and_sanitize "contracts/facets/IdentityCoreFacet.sol" \
  "$OUT_DIR/IdentityCoreFacet_flattened.sol" \
  "$SAN_DIR/IdentityCoreFacet_flattened.sol"

flatten_and_sanitize "contracts/facets/AttestationFacet.sol" \
  "$OUT_DIR/AttestationFacet_flattened.sol" \
  "$SAN_DIR/AttestationFacet_flattened.sol"

flatten_and_sanitize "contracts/facets/SubscriptionManagerFacet.sol" \
  "$OUT_DIR/SubscriptionManagerFacet_flattened.sol" \
  "$SAN_DIR/SubscriptionManagerFacet_flattened.sol"

flatten_and_sanitize "contracts/facets/TestingAdminFacet.sol" \
  "$OUT_DIR/TestingAdminFacet_flattened.sol" \
  "$SAN_DIR/TestingAdminFacet_flattened.sol"

echo ""
echo "✅ Selesai flatten. File siap upload manual (jika perlu) ada di: $SAN_DIR"
echo ""
echo "=== Mapping alamat → file flattened (untuk upload manual di Explorer) ==="
cat <<'MAP'
Diamond (proxy)                     0x17388b3f57Ab6188f6f9A88421f770a7A0f70332   →  flattened_sanitized/Diamond_flattened.sol
DiamondCutFacet                     0xd9aB239C897A1595df704124c0bD77560CA3655F   →  flattened_sanitized/DiamondCutFacet_flattened.sol
DiamondLoupeFacet                   0x2e2480Ed093512A1B089A31DcE5Ffbd531Ec16A2   →  flattened_sanitized/DiamondLoupeFacet_flattened.sol
OwnershipFacet                      0x1771Ada0617C59a7feb0D49AA2B2D8c91a593B48   →  flattened_sanitized/OwnershipFacet_flattened.sol
IdentityEnumerableFacet             0x2E386d5Bd09c94aa795b0979BC470E5cAdb9eeDE   →  flattened_sanitized/IdentityEnumerableFacet_flattened.sol
IdentityCoreFacet                   0x48d78F5E5CA178006f1F5F36e5404dfEdc628480   →  flattened_sanitized/IdentityCoreFacet_flattened.sol
AttestationFacet                    0xaE7Eeaa6Ac1DA6346384268996F2044CE8e2f8C1   →  flattened_sanitized/AttestationFacet_flattened.sol
SubscriptionManagerFacet            0x27C94d767245a20A0EEA4299eFcB279b1b7aeA02   →  flattened_sanitized/SubscriptionManagerFacet_flattened.sol
TestingAdminFacet                   0xaCfC87E78C2582674fDABdDBc966CBFce7805566   →  flattened_sanitized/TestingAdminFacet_flattened.sol
MAP

echo ""
echo "ℹ️  Setting compiler untuk verifikasi: Solidity 0.8.24, optimizer enabled, runs 200."
echo "ℹ️  DIAMOND constructor args:"
echo '    owner           = 0xC25F0BFc89859C7076C5400968A900323b48005d'
echo '    diamondCutFacet = 0xd9aB239C897A1595df704124c0bD77560CA3655F'

