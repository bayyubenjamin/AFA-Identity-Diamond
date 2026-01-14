// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { LibIdentityStorage } from "../libraries/LibIdentityStorage.sol";
import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract SubscriptionManagerFacet {
    using Address for address payable;

    // --- Custom Errors (Gas Saving: ~2000 gas per revert) ---
    error Subscription_PaymentFailed();
    error Subscription_InvalidTier();
    error Subscription_InsufficientPayment();
    error Subscription_TransferFailed();
    error Subscription_ReentrancyDetected();
    error Subscription_NotAuthorized();
    error Subscription_NoRevenueToWithdraw();

    // --- Events ---
    event SubscriptionPurchased(uint256 indexed tokenId, uint256 tierId, uint256 expiration);
    event SubscriptionPriceUpdated(uint256 indexed tierId, uint256 newPrice);
    event RevenueWithdrawn(address indexed to, uint256 amount);

    // --- Constants ---
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    // --- Modifiers ---

    /// @dev Manual Reentrancy Guard khusus Diamond Storage
    /// Mencegah serangan reentrancy tanpa risiko tabrakan storage slot 0
    modifier nonReentrant() {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        
        // Inisialisasi jika belum pernah dipakai
        if (s.reentrancyStatus == 0) {
             s.reentrancyStatus = _NOT_ENTERED;
        }

        if (s.reentrancyStatus == _ENTERED) revert Subscription_ReentrancyDetected();
        
        s.reentrancyStatus = _ENTERED;
        _;
        s.reentrancyStatus = _NOT_ENTERED;
    }

    // --- Core Logic ---

    /// @notice User membeli/memperpanjang langganan Premium
    /// @param tierId ID paket (misal: 1 = Bulanan, 2 = Tahunan)
    function buySubscription(uint256 tierId) external payable nonReentrant {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        
        uint256 price = s.subscriptionPrices[tierId];
        if (price == 0) revert Subscription_InvalidTier(); // Tier belum diset
        
        if (msg.value < price) revert Subscription_InsufficientPayment();

        // Cari TokenID user (User harus punya Identity dulu)
        uint256 tokenId = s._addressToTokenId[msg.sender];
        if (tokenId == 0) revert Subscription_NotAuthorized();

        // Kalkulasi durasi (Contoh sederhana: Tier 1 = 30 hari, Tier 2 = 365 hari)
        uint256 duration = (tierId == 1) ? 30 days : 365 days;
        
        // Perpanjang durasi
        if (s.premiumExpirations[tokenId] < block.timestamp) {
            s.premiumExpirations[tokenId] = block.timestamp + duration;
        } else {
            s.premiumExpirations[tokenId] += duration;
        }

        emit SubscriptionPurchased(tokenId, tierId, s.premiumExpirations[tokenId]);

        // Auto-Refund sisa ETH (UX Best Practice)
        if (msg.value > price) {
            uint256 refund = msg.value - price;
            (bool success, ) = msg.sender.call{value: refund}("");
            if (!success) revert Subscription_TransferFailed();
        }
    }

    // --- Admin Logic ---

    function setSubscriptionPrice(uint256 tierId, uint256 price) external {
        LibDiamond.enforceIsOwner();
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        s.subscriptionPrices[tierId] = price;
        emit SubscriptionPriceUpdated(tierId, price);
    }

    function setTreasury(address _newTreasury) external {
        LibDiamond.enforceIsOwner();
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        s.treasuryAddress = _newTreasury;
    }

    /// @notice Tarik pendapatan protokol dengan aman
    /// @dev Menggunakan pattern .call value daripada .transfer untuk kompatibilitas Smart Wallet
    function withdrawRevenue() external nonReentrant {
        LibDiamond.enforceIsOwner();
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        
        uint256 balance = address(this).balance;
        if (balance == 0) revert Subscription_NoRevenueToWithdraw();

        address recipient = s.treasuryAddress == address(0) ? msg.sender : s.treasuryAddress;

        // [SECURE] Menggunakan call + check return value
        (bool success, ) = recipient.call{value: balance}("");
        if (!success) revert Subscription_TransferFailed();

        emit RevenueWithdrawn(recipient, balance);
    }

    // --- View ---
    
    function getSubscriptionPrice(uint256 tierId) external view returns (uint256) {
        return LibIdentityStorage.layout().subscriptionPrices[tierId];
    }
}
