# Afa Identity Diamond 💎

[![Build Status](https://img.shields.io/travis/com/your-username/afa-identity-diamond.svg?style=flat-square)](https://travis-ci.com/your-username/afa-identity-diamond)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)

**Afa Identity Diamond** is a sophisticated decentralized identity (DID) system built using the **EIP-2535 Diamond Standard**. This project not only provides a robust foundation for secure digital identity management but also integrates a powerful **on-chain premium subscription system** through its `SubscriptionManagerFacet`.

It is a complete, out-of-the-box solution for dApps looking to monetize their services by offering flexible and fully verifiable subscription tiers on the blockchain.

## ✨ Key Features

* **Decentralized Identity Management**: Securely manage digital identities on-chain through the `IdentityCoreFacet` and `IdentityEnumerableFacet`.
* **Multi-Tier Premium Subscription System**: The `SubscriptionManagerFacet` allows users to subscribe to different tiers (e.g., monthly, yearly) and enables dApps to verify premium status on-chain.
* **EIP-2535 Diamond Architecture**: The contract is highly modular and infinitely upgradeable, allowing for future functionality to be added without requiring a full contract migration.
* **Decentralized Access Control**: dApps can easily restrict access to specific features, granting them only to users with an active premium subscription.
* **Admin-Managed Pricing**: The contract owner can easily set the price for each subscription tier.

---

## 💎 Feature Highlight: `SubscriptionManagerFacet`

The core innovation of this project is **`SubscriptionManagerFacet.sol`**, a dedicated module designed for end-to-end management of premium subscriptions. It provides a turnkey solution for dApp developers to build sustainable business models.

### Core Capabilities:

* **Upgrade to Premium (`upgradeToPremium`)**: Users can pay in ETH to upgrade their identity status to a premium tier (e.g., 1 Month, 6 Months, 1 Year). The function automatically calculates and extends the subscription's validity.
* **Status Verification (`isPremium`)**: A simple `view` function that can be called by any dApp to instantly check if an identity (token ID) has an active premium subscription. This is the key to unlocking exclusive features.
* **Dynamic Pricing (`setPriceForTier`)**: The contract owner or an admin can easily set and update the price for each subscription package, providing full commercial flexibility.
* **On-Chain Transparency**: All subscription details, including the expiration date (`getPremiumExpiration`), are transparently recorded on the blockchain.

With `SubscriptionManagerFacet`, the once-complex process of dApp monetization is now straightforward and secure.

---

## 🛠️ Technical & Architecture

This project uses the **EIP-2535 Diamond Standard**, which allows a single contract address to proxy logic from multiple implementation contracts (called *facets*).

### Core Facets:

* **`SubscriptionManagerFacet.sol`**: **Core Component.** Manages all logic related to premium subscriptions, including payments, renewals, and status verification.
* **`IdentityCoreFacet.sol`**: Manages the basic logic for creating and managing core identity data.
* **`IdentityEnumerableFacet.sol`**: Adds the ability to enumerate and track all existing identity tokens.
* **`AttestationFacet.sol`**: Manages attestations or verified claims related to an identity.
* **`DiamondCutFacet.sol`**: A standard Diamond function for upgrading functionality by adding/replacing/removing facets.
* **`DiamondLoupeFacet.sol`**: A standard Diamond function for introspecting which facets and functions are attached to the Diamond.
* **`OwnershipFacet.sol`**: Manages the ownership of the Diamond contract.

---

## 🚀 Getting Started

### Prerequisites

* [Node.js](https://nodejs.org/en/)
* [Yarn](https://yarnpkg.com/) or [npm](https://www.npmjs.com/)
* [Hardhat](https://hardhat.org/)

### Installation

1.  **Clone this repository:**
    ```sh
    git clone [https://github.com/your-username/afa-identity-diamond.git](https://github.com/your-username/afa-identity-diamond.git)
    cd afa-identity-diamond
    ```

2.  **Install dependencies:**
    ```sh
    npm install
    ```

### Configuration

Create a `.env` file in the project root and add the necessary variables, such as your private key for deployment and an RPC node URL. You can copy from `.env.example` if it exists.
