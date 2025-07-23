import { HardhatUserConfig } from "hardhat/config";
import "dotenv/config";

// Impor plugin yang dibutuhkan
import "@nomicfoundation/hardhat-verify"; 
import "@nomicfoundation/hardhat-ethers";

// Mengambil variabel dari file .env
const PRIVATE_KEY = process.env.PRIVATE_KEY || "";
const HELIOS_API_KEY = process.env.HELIOS_API_KEY || "";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL || "",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      chainId: 11155111,
    },
    baseSepolia: {
      url: process.env.BASE_SEPOLIA_RPC_URL || "",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      chainId: 84532,
    },
    base: {
      url: process.env.BASE_MAINNET_RPC_URL || "",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      chainId: 8453,
    },
    optimismSepolia: {
      url: process.env.OPTIMISM_SEPOLIA_RPC_URL || "https://sepolia.optimism.io",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      chainId: 11155420,
    },
    // --- PENAMBAHAN JARINGAN HELIOS ---
    helios: {
      url: "https://testnet1.helioschainlabs.org",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      chainId: 42000,
    },
  },
  etherscan: {
    apiKey: {
      // API Keys untuk jaringan yang sudah ada
      mainnet: process.env.ETHERSCAN_API_KEY || "",
      sepolia: process.env.ETHERSCAN_API_KEY || "",
      base: process.env.BASESCAN_API_KEY || "",
      baseSepolia: process.env.BASESCAN_API_KEY || "",
      optimismSepolia: process.env.OPTIMISTIC_ETHERSCAN_API_KEY || "",
      // --- PENAMBAHAN API KEY HELIOS ---
      helios: HELIOS_API_KEY,
    },
    customChains: [
      {
        network: "base",
        chainId: 8453,
        urls: {
          apiURL: "https://api.basescan.org/api",
          browserURL: "https://basescan.org",
        },
      },
      {
        network: "baseSepolia",
        chainId: 84532,
        urls: {
          apiURL: "https://api-sepolia.basescan.org/api",
          browserURL: "https://sepolia.basescan.org",
        },
      },
      {
        network: "optimismSepolia",
        chainId: 11155420,
        urls: {
          apiURL: "https://api-sepolia-optimism.etherscan.io/api",
          browserURL: "https://sepolia-optimism.etherscan.io",
        },
      },
      // --- PENAMBAHAN CUSTOM CHAIN HELIOS ---
      {
        network: "helios",
        chainId: 42000,
        urls: {
          apiURL: "https://explorer.helioschainlabs.org/api", // URL untuk verifikasi
          browserURL: "https://explorer.helioschainlabs.org", // URL block explorer
        },
      },
    ],
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
};

export default config;
