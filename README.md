# Afa Identity Diamond 💎

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen?style=flat-square)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![Standard: EIP-2535](https://img.shields.io/badge/Standard-EIP--2535-blue)](https://eips.ethereum.org/EIPS/eip-2535)
[![Network: Base](https://img.shields.io/badge/Network-Base-0052FF)](https://base.org)

**Afa Identity Diamond** is a production-grade **Gamified Social Identity Protocol** built on the **EIP-2535 Diamond Standard**. It transforms static decentralized identifiers (DID) into dynamic, secure, and interactive "Web3 Profiles."

Unlike traditional monolithic contracts, AFA Identity utilizes a modular architecture where storage logic is decoupled from business logic, allowing for infinite upgradeability and specialized features like **Social Graphs**, **P2P Endorsements**, and **Social Recovery**.

---

## ✨ Key Features

### 🆔 Core Identity & Security
* **🛡️ EIP-712 Typed Security**: Minting utilizes **EIP-712 Structured Data** for human-readable signatures and protection against cross-chain replay attacks.
* **🔒 Strict Soulbound (SBT)**: The identity token is non-transferable by default, ensuring reputation stays bound to the user.
* **🚑 Social Recovery**: A "Lost Keys" solution allowing users to appoint **Guardians** to securely migrate their identity profile to a new wallet in emergencies.

### 📢 Social Graph & Reputation
* **👥 Follow/Unfollow System**: Native social graph logic stored efficiently on-chain.
* **🌟 P2P Endorsements**: Users can endorse others for specific skills (e.g., "Solidity", "Design"), boosting their reputation score.
* **@ Handle Registry**: Unique username system backed by an on-chain registry with character validation.

### 🎮 Gamification & Monetization
* **⚔️ Quest System**: Admin or external contracts can trigger "Quest Completion" to reward users.
* **📈 XP & Leveling**: Built-in experience points system that calculates user levels dynamically.
* **💰 Subscription Model**: Monetization logic allowing users to pay (ETH/BaseETH) for Premium status.

---

## 🏗️ Technical Architecture

This project strictly adheres to the **Diamond Storage Pattern** to prevent storage collisions and enable modular extensions.

### 1. The Diamond (Proxy)
The main contract (`Diamond.sol`) holds the state and delegates logic execution to Facets via `delegatecall`.

### 2. The Facets (Logic Layer)
Modular contracts containing specific business logic:
* **`IdentityCoreFacet`**: Minting, Burning, and SBT enforcement.
* **`SocialProfileFacet`**: Managing profiles, handles, and social actions.
* **`SocialRecoveryFacet`**: Guardian management and emergency account migration.
* **`GamificationFacet`**: Handling XP, Quests, and Daily Rewards.
* **`SubscriptionManagerFacet`**: Managing pricing, payments, and treasury.
* **`IdentityEnumerableFacet`**: A view-only facet that aggregates data from multiple storage libraries for efficient frontend fetching.

### 3. The Libraries (Storage Layer)
To ensure safety and reusability, state variables are encapsulated in dedicated libraries using distinct storage slots (Namespaced Storage):

| Library | Description |
| :--- | :--- |
| **`LibIdentityStorage`** | Core ERC721 state, token owners, balances, and verifier config. |
| **`LibSocialGraphStorage`** | Stores the heavy social graph data: `isFollowing`, `followerCount`, `followingCount`. |
| **`LibGamificationStorage`** | Encapsulates game state: `xp`, `level`, `questCompleted`, `dailyRewards`. |
| **`LibSubscriptionStorage`** | Manages monetization configuration: `monthlyPrice`, `treasuryAddress`. |
| **`LibRecoveryStorage`** | Secures guardian lists and recovery thresholds. |

---

## 📂 Directory Structure

```plaintext
contracts/
├── diamond/                # Diamond Proxy & Core Logic
│   ├── Diamond.sol
│   └── libraries/LibDiamond.sol
├── facets/                 # Implementation Contracts (Logic)
│   ├── IdentityCoreFacet.sol
│   ├── SocialProfileFacet.sol
│   ├── GamificationFacet.sol
│   ├── SocialRecoveryFacet.sol
│   └── ...
├── libraries/              # Storage Pointers (State)
│   ├── LibIdentityStorage.sol
│   ├── LibSocialGraphStorage.sol  <-- [NEW] Social Data
│   ├── LibGamificationStorage.sol <-- [NEW] Game State
│   └── LibSubscriptionStorage.sol <-- [NEW] Payment Config
└── interfaces/             # Standard Interfaces

## 🚀 Getting Started

### Prerequisites

* [Node.js](https://nodejs.org/en/) >= 18
* [Yarn](https://yarnpkg.com/) or [npm](https://www.npmjs.com/)
* [Hardhat](https://hardhat.org/)

### Installation

1.  **Clone this repository:**
    ```sh
    git clone https://github.com/bayyubenjamin/afa-identity-diamond.git
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
```

### Deployment

To deploy the full Diamond on Base Sepolia:

```sh
npx hardhat run scripts/deployDiamondFull.js --network base-sepolia
```
