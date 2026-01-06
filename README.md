# Afa Identity Diamond 💎

[![Build Status](https://img.shields.io/travis/com/bayyubenjamin/afa-identity-diamond.svg?style=flat-square)](https://travis-ci.com/bayyubenjamin/afa-identity-diamond)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)

**Afa Identity Diamond** is a sophisticated decentralized identity (DID) system built using the **EIP-2535 Diamond Standard**. This project provides a robust foundation for secure digital identity management and integrates a powerful, production-grade **on-chain premium subscription system**.

Designed for scalability and gas efficiency, this contract utilizes **Custom Errors**, **Assembly-based Error Bubbling**, and strict security checks, making it a complete, out-of-the-box solution for dApps looking to monetize services securely on the blockchain.

## ✨ Key Features

* **Decentralized Identity Management**: Securely manage digital identities on-chain through the `IdentityCoreFacet` and `IdentityEnumerableFacet`.
* **Multi-Tier Premium Subscription**: Users can subscribe to flexible tiers (1 Month, 6 Months, 1 Year).
* **Smart Treasury Management**: Integrated **Withdrawal Logic** ensures project owners can securely retrieve revenue.
* **Auto-Refund Mechanism**: The contract automatically refunds excess ETH if a user overpays, ensuring a superior User Experience (UX).
* **Gas Optimized**: Utilizes Solidity **Custom Errors** instead of string revert messages to significantly reduce deployment and execution costs.
* **EIP-2535 Architecture**: Infinitely upgradeable without data migration.

---

## 💎 Feature Highlight: `SubscriptionManagerFacet`

The `SubscriptionManagerFacet.sol` has been engineered for production use, focusing on security, economy, and fairness.

### Core Capabilities:

* **🚀 Upgrade to Premium (`upgradeToPremium`)** Users pay in ETH to upgrade. The system handles logic for:
  * **Validity Extension**: Adds time to existing expiration if active, or starts fresh if expired.
  * **Auto-Refund**: If the price is 0.1 ETH and the user sends 0.15 ETH, **0.05 ETH is instantly refunded**.
  * **Security**: Validates token ownership and tier existence before processing.

* **💰 Treasury Withdrawal (`withdrawFunds`)** A secure, admin-only function to withdraw accumulated ETH revenue to a specified address. Includes safety checks against zero-address transfers and failed calls.

* **🔍 Status Verification (`isPremium`)** A lightweight `view` function for dApps to instantly gate content based on valid subscription status.

* **⚙️ Dynamic Pricing (`setPriceForTier`)** Admins can adjust subscription costs in real-time to respond to market conditions.

---

## 🛠️ Technical Architecture & Optimizations

This project leverages the **EIP-2535 Diamond Standard** to split logic into multiple implementation contracts (*facets*) while maintaining a single storage layout.

### Advanced Improvements:

* **Custom Errors (Gas Efficiency)**:  
  Replaced expensive string requires (e.g., `require(cond, "Long Error Message")`) with custom errors (e.g., `error InsufficientPayment()`). This saves gas for users and reduces contract bytecode size.
  
* **Assembly Error Bubbling (`DiamondCutFacet`)**:  
  The upgrade logic now uses inline Assembly to bubble up the *exact* revert reason from initialization delegates. This makes debugging upgrade failures significantly easier compared to standard implementations.

### Core Facets:

* **`SubscriptionManagerFacet.sol`**: Manages payments, refunds, validity logic, and revenue withdrawal.
* **`DiamondCutFacet.sol`**: Standard Diamond upgrade logic, enhanced with strict `address(0)` checks for removals and assembly error handling.
* **`IdentityCoreFacet.sol`**: Core identity creation and management.
* **`IdentityEnumerableFacet.sol`**: Enumeration of identity tokens.
* **`OwnershipFacet.sol`**: Manages contract ownership and permissions.

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
