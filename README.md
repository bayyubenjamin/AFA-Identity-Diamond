# Afa Identity Diamond 💎

[![Build Status](https://img.shields.io/travis/com/bayyubenjamin/afa-identity-diamond.svg?style=flat-square)](https://travis-ci.com/bayyubenjamin/afa-identity-diamond)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![Standard: EIP-2535](https://img.shields.io/badge/Standard-EIP--2535-blue)](https://eips.ethereum.org/EIPS/eip-2535)

**Afa Identity Diamond** is a production-grade **Gamified Social Identity Protocol** built on the **EIP-2535 Diamond Standard**. It transforms static decentralized identifiers (DID) into dynamic, secure, and interactive "Web3 Profiles."

Beyond standard Identity Management, this protocol introduces **Social Recovery (Guardians)**, **On-Chain Gamification**, and a **Universal Handle System**, making it a robust foundation for SocialFi, DAO Governance, and Metaverse applications on Base, Optimism, and high-performance L2s.

## ✨ Key Features

### 🆔 Core Identity & Security
* **🛡️ EIP-712 Typed Security**: Minting utilizes **EIP-712 Structured Data** for human-readable signatures and protection against cross-chain replay attacks.
* **💎 Diamond-Storage Architecture**: Modular "Facet" system with isolated storage pointers (`LibIdentity`, `LibSocial`, `LibRecovery`) guarantees 0% storage collision risk.
* **🔒 Strict Soulbound (SBT)**: The identity token is non-transferable by default, ensuring reputation stays bound to the user.

### 📢 Social & Reputation Layer **(NEW)**
* **@ Handle System**: Users can claim unique usernames (e.g., `@satoshi`) backed by on-chain registry.
* **Dynamic Profile**: Update Bio, Avatar, and Links without needing to burn/remint the NFT.
* **🚑 Social Recovery**: "Lost Keys" solution. Users can appoint **Guardians** to rescue their Identity if their wallet is compromised.

### 🎮 Engagement Engine **(NEW)**
* **📈 On-Chain Leveling**: Built-in XP system tracking user activity.
* **📅 Retention Mechanics**: `dailyCheckIn()` function to incentivize Daily Active Users (DAU).
* **💰 Auto-Refund Subscriptions**: Monetization logic with automatic ETH overpayment protection.

---

## 🏗️ Module Breakdown

The logic is split into specific Facets to ensure modularity and upgradeability.

### 1. Social Profile Facet (`SocialProfileFacet.sol`)
Turns the NFT into a full Social Profile.
* **Unique Handles**: Enforces uniqueness for usernames. Includes validation logic (length, allowed characters).
* **Metadata Management**: Users can toggle privacy (Public/Private) and update profile data efficiently.
* **Storage**: Uses `LibSocialStorage` to separate social data from core identity data.

### 2. Social Recovery Facet (`SocialRecoveryFacet.sol`)
**A "Safety Net" for Web3 Users.**
* **Guardian Logic**: Users appoint trusted wallets (friends/hardware wallets) as Guardians.
* **Secure Rescue**: If a private key is lost, Guardians can vote to migrate the Identity Profile to a new address.
* **SBT Exception**: This is the *only* strictly controlled pathway where an SBT can be transferred, implementing a Timelock and Threshold mechanism for security.

### 3. Gamification Facet (`GamificationFacet.sol`)
**Native User Retention System.**
* **XP & Levels**: Calculates user Level based on stored XP (e.g., `Level = sqrt(XP)`).
* **Activity Tracking**: Contracts can integrate to reward users with XP for specific actions.
* **Daily Rewards**: Prevents spam while rewarding consistent interaction via time-based cooldowns.

### 4. Identity Core (`IdentityCoreFacet.sol`)
* **Minting**: Validates EIP-712 signatures from a centralized Verifier (Gasless minting ready).
* **Burning**: GDPR-compliant "Right to be Forgotten" allowing users to self-destruct their identity.

---

## 🔐 Security & Architecture

This project leverages the **EIP-2535 Diamond Standard** to split logic into multiple implementation contracts (*facets*) while maintaining a single storage layout.

### Advanced Security Measures:
* **Custom Mutex**: Instead of standard `ReentrancyGuard` which causes storage clashes in Diamonds, we use a custom mutex implementation in `LibIdentityStorage`.
* **Storage Isolation**: Every feature set (Social, Recovery, Game) has its own Library with a unique storage slot hash. This prevents data corruption during upgrades.
* **Domain Separators**: Signatures include `chainid` and `verifyingContract` address, preventing replay attacks across different networks (e.g., Base vs Optimism).

### Gas Optimization:
* **Custom Errors**: Replaced string reverts with Custom Errors (e.g., `Social_HandleAlreadyTaken()`), saving ~2000 gas per revert.
* **Bitpacking**: Boolean flags and timestamps are packed tightly in structs where possible.

### Core Facets List:

* **`IdentityCoreFacet`**: Mint/Burn & SBT Logic.
* **`SocialProfileFacet`**: Handles, Bio, Links.
* **`SocialRecoveryFacet`**: Guardian management & Account rescue.
* **`GamificationFacet`**: XP, Leveling, Check-ins.
* **`SubscriptionManagerFacet`**: Payments & Treasury.
* **`DiamondCutFacet`**: Upgradeability.
* **`DiamondLoupeFacet`**: Introspection.
* **`OwnershipFacet`**: Admin control.

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

4.  **Test:**
    ```sh
    npx hardhat test
    ```

### Configuration

Create a `.env` file in the project root to configure your deployment environment:

```env
PRIVATE_KEY=your_private_key_here
RPC_URL=your_rpc_url_here
ETHERSCAN_API_KEY=your_api_key
