# Afa Identity Diamond 💎

[![Build Status](https://img.shields.io/travis/com/bayyubenjamin/afa-identity-diamond.svg?style=flat-square)](https://travis-ci.com/bayyubenjamin/afa-identity-diamond)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)

**Afa Identity Diamond** is a sophisticated decentralized identity (DID) system built using the **EIP-2535 Diamond Standard**. This project provides a robust foundation for secure digital identity management, ensuring **Cross-Chain Security** and integrating a production-grade **on-chain premium subscription system**.

Designed for the multi-chain era, this contract features **Replay Attack Protection**, **Strict Soulbound Enforcement**, and **Self-Sovereign Identity (SSI)** principles, making it a secure and scalable solution for dApps on Base, Optimism, and beyond.

## ✨ Key Features

* **🛡️ Cross-Chain Replay Protection**: Minting signatures are cryptographically bound to the specific `chainid`. A signature generated for Base cannot be replayed on Optimism or Mainnet.
* **🔒 Strict Soulbound (SBT)**: The identity token is non-transferable. All transfer logic is overridden to revert efficiently, ensuring true identity persistence.
* **🔥 Self-Sovereign & GDPR Compliant**: Users possess the right to `burn` (delete) their own identity at any time, respecting privacy and "Right to be Forgotten" standards.
* **💎 Multi-Tier Premium Subscription**: Monetize your dApp with flexible on-chain subscription tiers (Monthly, Yearly) managed via the `SubscriptionManagerFacet`.
* **⚡ Gas Optimized**: Replaced expensive string reverts with **Custom Errors** (e.g., `Identity_InvalidSignature`) to significantly reduce deployment and runtime costs.
* **🏦 Smart Treasury**: Integrated withdrawal logic ensures secure revenue collection for the project owner.

---

## 🛡️ Feature Highlight: `IdentityCoreFacet` (Security)

The core identity logic has been hardened for production environments.

### 1. Advanced Sybil Resistance
Identity minting requires a cryptographic signature from a trusted Verifier. The hashing algorithm includes:
* `msg.sender` (Recipient)
* `nonce` (Prevent local replay)
* **`block.chainid` (Prevent cross-chain replay)**

### 2. True Soulbound Token (SBT)
Unlike standard NFTs, `AFAID` tokens cannot be transferred, bought, or sold.
* `transferFrom`, `safeTransferFrom`, and `approve` functions are hard-wired to revert with `Identity_SoulboundTokenCannotBeTransferred`.
* This ensures the reputation attached to an ID is strictly bound to the original wallet.

### 3. User-Controlled Lifecycle (Burn)
We implement **Self-Sovereign Identity** principles. Users are not locked in; they can call `burnIdentity(tokenId)` to destroy their token and data association, ensuring full control over their on-chain presence.

---

## 💰 Feature Highlight: `SubscriptionManagerFacet` (Monetization)

Turnkey solution for dApp monetization.

* **Upgrade to Premium**: Handles payments, validity extensions, and **Auto-Refunds** (instantly returns excess ETH to the user).
* **Status Verification**: Simple `isPremium(tokenId)` view function for gating content.
* **Dynamic Pricing**: Admins can update tier prices in real-time.
* **Secure Withdrawal**: Admin-only function to withdraw revenue safely.

---

## 🛠️ Technical Architecture & Optimizations

This project leverages the **EIP-2535 Diamond Standard** to split logic into multiple implementation contracts (*facets*) while maintaining a single storage layout.

### Gas Optimization Strategy:
* **Custom Errors**: We use defined errors like `Identity_InvalidSignature()` instead of `require(..., "String")`. This saves gas during deployment and execution.
* **Unchecked Loops**: Used in `DiamondLoupeFacet` for efficient array iteration.
* **Assembly Error Bubbling**: The upgrade logic (`DiamondCutFacet`) uses inline Assembly to bubble up the exact revert reason from delegates, aiding debugging.

### Core Facets:

* **`IdentityCoreFacet.sol`**: Manages minting, security (replay protection), SBT enforcement, and burning.
* **`SubscriptionManagerFacet.sol`**: Manages payments, refunds, subscription validity, and treasury.
* **`DiamondCutFacet.sol`**: Standard Diamond upgrade logic with assembly error handling.
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
