# Afa Identity Diamond 💎

[![Build Status](https://img.shields.io/travis/com/bayyubenjamin/afa-identity-diamond.svg?style=flat-square)](https://travis-ci.com/bayyubenjamin/afa-identity-diamond)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![Standard: EIP-2535](https://img.shields.io/badge/Standard-EIP--2535-blue)](https://eips.ethereum.org/EIPS/eip-2535)

**Afa Identity Diamond** is a production-grade decentralized identity (DID) system built on the **EIP-2535 Diamond Standard**. It establishes a secure, modular foundation for digital identity management, featuring **EIP-712 Typed Data Signatures**, **Diamond-Storage Reentrancy Protection**, and a flexible on-chain subscription model.

Designed for the multi-chain ecosystem, this architecture guarantees **Cross-Chain Security**, **Strict Soulbound Enforcement**, and **Self-Sovereign Identity (SSI)** compliance, making it a scalable solution for dApps on Base, Optimism, and high-performance L2s.

## ✨ Key Features

* **🛡️ EIP-712 Typed Security**: Minting utilizes **EIP-712 Structured Data**, providing human-readable signatures in wallets and robust protection against cross-chain replay attacks via Domain Separators.
* **💎 Diamond-Storage Reentrancy Guard**: Custom-built mutex implementation residing in `LibIdentityStorage` to prevent reentrancy attacks without the storage collision risks common in standard proxy inheritance.
* **🔒 Strict Soulbound (SBT)**: The identity token is non-transferable. All transfer logic is overridden to revert efficiently, ensuring true identity persistence.
* **🔥 Self-Sovereign & GDPR Compliant**: Users possess the right to `burn` (delete) their own identity at any time, respecting privacy and "Right to be Forgotten" standards.
* **💰 Auto-Refund Subscription System**: Monetization logic automatically calculates and instantly refunds any excess ETH sent during subscription upgrades.
* **⚡ Gas Optimized**: Replaced expensive string reverts with **Custom Errors** and optimized storage packing to minimize execution costs.

---

## 🛡️ Feature Highlight: `IdentityCoreFacet` (Security)

The core identity logic has been hardened using industry-standard cryptography.

### 1. EIP-712 Advanced Sybil Resistance
Instead of raw hashing, we implement **EIP-712 Typed Structured Data**. This ensures:
* **User Safety**: Users see exactly what they are signing (Recipient Address & Nonce) in their wallet interface, not just a hex string.
* **Cross-Chain Protection**: The `chainid` is embedded in the EIP-712 Domain Separator. A signature signed for Base cannot be replayed on Optimism.
* **Cross-Contract Protection**: The `verifyingContract` address ensures signatures cannot be replayed on other deployments of AFA ID.

### 2. True Soulbound Token (SBT)
Unlike standard NFTs, `AFAID` tokens cannot be transferred, bought, or sold.
* `transferFrom`, `safeTransferFrom`, and `approve` functions are hard-wired to revert with `Identity_SoulboundTokenCannotBeTransferred`.
* This ensures the reputation attached to an ID is strictly bound to the original wallet.

### 3. User-Controlled Lifecycle (Burn)
We implement **Self-Sovereign Identity** principles. Users are not locked in; they can call `burnIdentity(tokenId)` to destroy their token and data association, ensuring full control over their on-chain presence.

---

## 💰 Feature Highlight: `SubscriptionManagerFacet` (Monetization)

Turnkey solution for dApp monetization with financial safety mechanisms.

* **Secure Payments**: Protected by a custom **Diamond-Compatible Reentrancy Guard** to prevent reentrancy during ETH transfers.
* **Auto-Refunds**: Logic calculates the exact tier price and immediately refunds overpayments in the same transaction.
* **Status Verification**: Simple `isPremium(tokenId)` view function for gating content.
* **Secure Treasury**: Implements the "Pull" payment pattern using `call` with return value checks to prevent DoS attacks during revenue withdrawal.

---

## 🔐 Security & Architecture

This project leverages the **EIP-2535 Diamond Standard** to split logic into multiple implementation contracts (*facets*) while maintaining a single storage layout.

### High-Impact Security Measures:
* **Storage-Layout Mutex**: Standard `ReentrancyGuard` from OpenZeppelin can cause storage collisions in Diamonds. We implemented a custom mutex in `LibIdentityStorage` to ensure safe locking across all facets.
* **Signature Validity**: Strict nonce management prevents local replay attacks.
* **Access Control**: Granular permissioning via `LibDiamond` enforcement ensures only the owner can modify critical parameters.

### Gas Optimization Strategy:
* **Custom Errors**: We use defined errors like `Identity_InvalidSignature()` instead of `require(..., "String")`. This saves ~2000 gas per revert.
* **Unchecked Loops**: Used in `DiamondLoupeFacet` for efficient array iteration.
* **Assembly Error Bubbling**: The upgrade logic uses inline Assembly to bubble up the exact revert reason from delegates, aiding debugging.

### Core Facets:

* **`IdentityCoreFacet.sol`**: EIP-712 Minting, SBT enforcement, and Burning logic.
* **`SubscriptionManagerFacet.sol`**: Payments, Subscription validity, and Secure Treasury management.
* **`DiamondCutFacet.sol`**: Standard Diamond upgrade logic.
* **`IdentityEnumerableFacet.sol`**: Enumeration of identity tokens.
* **`DiamondLoupeFacet.sol`**: Introspection / Etherscan compliance.
* **`OwnershipFacet.sol`**: Manages contract ownership.

---

## 🚀 Getting Started

### Prerequisites

* [Node.js](https://nodejs.org/en/) >= 18
* [Yarn](https://yarnpkg.com/) or [npm](https://www.npmjs.com/)
* [Hardhat](https://hardhat.org/)

### Installation

1.  **Clone this repository:**
    ```sh
    git clone [https://github.com/bayyubenjamin/afa-identity-diamond.git](https://github.com/bayyubenjamin/afa-identity-diamond.git)
    cd afa-identity-diamond
    ```

2.  **Install dependencies:**
    ```sh
    npm install
    # or
    yarn install
    ```

3.  **Compile Contracts:**
    ```sh
    npx hardhat compile
    ```

### Configuration

Create a `.env` file in the project root to configure your deployment environment:

```env
PRIVATE_KEY=your_private_key_here
RPC_URL=your_rpc_url_here
ETHERSCAN_API_KEY=your_api_key
