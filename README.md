# Afa Identity Diamond 💎

[![Build Status](https://img.shields.io/travis/com/bayyubenjamin/afa-identity-diamond.svg?style=flat-square)](https://travis-ci.com/bayyubenjamin/afa-identity-diamond)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![Standard: EIP-2535](https://img.shields.io/badge/Standard-EIP--2535-blue)](https://eips.ethereum.org/EIPS/eip-2535)
[![Network: Base](https://img.shields.io/badge/Network-Base-0052FF)](https://base.org)

**Afa Identity Diamond** is a production-grade **Gamified Social Identity Protocol** built on the **EIP-2535 Diamond Standard**. It transforms static decentralized identifiers (DID) into dynamic, secure, and interactive "Web3 Profiles."

Beyond standard Identity Management, this protocol introduces **Social Graphs (Follows)**, **P2P Endorsements**, **Social Recovery**, and **On-Chain Gamification**, making it a robust foundation for SocialFi, DAO Governance, and Metaverse applications on Base, Optimism, and high-performance L2s.

## ✨ Key Features

### 🆔 Core Identity & Security
* **🛡️ EIP-712 Typed Security**: Minting utilizes **EIP-712 Structured Data** for human-readable signatures and protection against cross-chain replay attacks.
* **💎 Diamond-Storage Architecture**: Modular "Facet" system with isolated storage pointers guarantees 0% storage collision risk.
* **🔒 Strict Soulbound (SBT)**: The identity token is non-transferable by default, ensuring reputation stays bound to the user.

### 📢 Social & Reputation Layer
* **👥 Social Graph**: Native **Follow/Unfollow** system allowing users to build on-chain networks.
* **🌟 Peer-to-Peer Endorsements**: Users can endorse others for specific skills (e.g., "Solidity", "Design"), boosting their reputation.
* **@ Handle System**: Users can claim unique usernames (e.g., `@satoshi`) backed by an on-chain registry.
* **🚑 Social Recovery**: "Lost Keys" solution. Users can appoint **Guardians** to rescue their Identity if their wallet is compromised.

### 🎮 Engagement Engine
* **⚔️ Quest System**: Admin or external contracts can trigger "Quest Completion" to reward users.
* **📈 On-Chain Leveling**: Built-in XP system tracking user activity.
* **📅 Retention Mechanics**: `dailyCheckIn()` function to incentivize Daily Active Users (DAU).
* **💰 Subscription Model**: Monetization logic for Premium status using native tokens (ETH).

---

## 🏗️ Module Breakdown

The logic is split into specific Facets to ensure modularity and upgradeability.

### 1. Social Profile Facet (`SocialProfileFacet.sol`)
Turns the NFT into a full Social Profile.
* **Profile Management**: Handle, Display Name, Bio, Avatar, and Links.
* **Social Graph**: Manages `isFollowing`, `followerCount`, and `followingCount`.
* **Privacy**: Toggles for Public/Private profile visibility.

### 2. Reputation Facet (`ReputationFacet.sol`)
* **Endorsements**: Logic for users to endorse specific skills of other users.
* **Scoring**: Calculates dynamic reputation scores based on activity and endorsements.
* **Badges**: Storage for achievement badges (IDs) awarded to users.

### 3. Social Recovery Facet (`SocialRecoveryFacet.sol`)
**A "Safety Net" for Web3 Users.**
* **Guardian Logic**: Users appoint trusted wallets as Guardians.
* **Secure Rescue**: If a private key is lost, Guardians can sign a multi-sig request to migrate the Identity Profile to a new address.
* **SBT Exception**: This is the *only* strictly controlled pathway where an SBT can be transferred.

### 4. Gamification Facet (`GamificationFacet.sol`)
**Native User Retention System.**
* **XP & Levels**: Calculates user Level based on stored XP (e.g., `Level = XP / 100 + 1`).
* **Quests**: Functionality to complete specific tasks (`completeQuest`) and earn rewards.
* **Daily Rewards**: Time-based cooldowns for daily check-ins.

### 5. Developer Tools (`IdentityEnumerableFacet.sol`)
* **Frontend Lens**: Provides `getFullProfile(address)` to fetch Profile, Social Stats, Reputation, and Premium status in a **single RPC call**.
* **Enumeration**: Standard ERC721Enumerable support for indexing.

---

## 🔐 Security & Architecture

This project leverages the **EIP-2535 Diamond Standard** to split logic into multiple implementation contracts (*facets*) while maintaining a single storage layout.

### Advanced Security Measures:
* **Storage Isolation**: Every feature set (Social, Recovery, Game) has its own Library with a unique storage slot hash. This prevents data corruption during upgrades.
* **Domain Separators**: Signatures include `chainid` and `verifyingContract` address.
* **Strict Authorization**: `onlyIdentityOwner` and `onlyAdmin` modifiers secure critical write paths.

### Core Facets List:

* **`IdentityCoreFacet`**: Mint/Burn & SBT Logic.
* **`SocialProfileFacet`**: Handles, Bio, Follow/Unfollow.
* **`ReputationFacet`**: Endorsements & Badges.
* **`SocialRecoveryFacet`**: Guardian management.
* **`GamificationFacet`**: XP, Quests, Check-ins.
* **`SubscriptionManagerFacet`**: Payments & Treasury.
* **`AttestationFacet`**: On-chain verified credentials.
* **`IdentityEnumerableFacet`**: View helpers.
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
