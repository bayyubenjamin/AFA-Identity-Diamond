import { HardhatUserConfig } from "hardhat/config";
import "dotenv/config";

// Impor plugin yang dibutuhkan
import "@nomicfoundation/hardhat-verify"; 
import "@nomicfoundation/hardhat-ethers";

// Mengambil variabel dari file .env
const PRIVATE_KEY = process.env.PRIVATE_KEY || "";
const HELIOS_API_KEY = process.env.HELIOS_API_KEY || "";
const PHAROS_API_KEY = process.env.PHAROS_API_KEY || "NO_API_KEY"; // Default jika tidak ada

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
    // --- JARINGAN HELIOS ---
    helios: {
      url: "https://testnet1.helioschainlabs.org",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      chainId: 42000,
    },
    // --- JARINGAN PHAROS TESTNET ---
    pharosTestnet: {
      url: "https://testnet.dplabs-internal.com",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      chainId: 688688,
    },
    // --- JARINGAN PHAROS DEVNET ---
    pharosDevnet: {
      url: "https://devnet.dplabs-internal.com",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      chainId: 50002,
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
      // API Key untuk Helios
      helios: HELIOS_API_KEY,
      // API Key untuk Pharos
      pharosTestnet: PHAROS_API_KEY,
      pharosDevnet: PHAROS_API_KEY,
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
      // Konfigurasi Custom Chain untuk Helios
      {
        network: "helios",
        chainId: 42000,
        urls: {
          apiURL: "https://explorer.helioschainlabs.org/api",
          browserURL: "https://explorer.helioschainlabs.org",
        },
      },
      // Konfigurasi Custom Chain untuk Pharos Testnet
      {
        network: "pharosTestnet",
        chainId: 688688,
        urls: {
          apiURL: "https://testnet.pharosscan.xyz/api",
          browserURL: "https://testnet.pharosscan.xyz/",
        },
      },
      // Konfigurasi Custom Chain untuk Pharos Devnet
      {
        network: "pharosDevnet",
        chainId: 50002,
        urls: {
          apiURL: "https://devnet.pharosscan.xyz/api",
          browserURL: "https://devnet.pharosscan.xyz/",
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
