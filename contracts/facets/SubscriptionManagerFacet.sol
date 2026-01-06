// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/LibIdentityStorage.sol";
import "../interfaces/IOwnershipFacet.sol";

contract SubscriptionManagerFacet {
    using LibIdentityStorage for LibIdentityStorage.Layout;

    // --- Events ---
    event SubscriptionRenewed(uint256 indexed tokenId, uint256 newExpiration, LibIdentityStorage.SubscriptionTier tier);
    event PriceForTierSet(LibIdentityStorage.SubscriptionTier indexed tier, uint256 newPrice);
    event FundsWithdrawn(address indexed to, uint256 amount);

    // --- Custom Errors (Gas Efficiency) ---
    error NotContractOwner();
    error NotTokenOwner();
    error InvalidTierPrice();
    error InsufficientPayment(uint256 required, uint256 sent);
    error InvalidSubscriptionTier();
    error TransferFailed();
    error InvalidRecipient();

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != IOwnershipFacet(address(this)).owner()) {
            revert NotContractOwner();
        }
        _;
    }

    // --- Admin Functions ---

    /// @notice Mengatur harga untuk tier tertentu
    function setPriceForTier(LibIdentityStorage.SubscriptionTier _tier, uint256 _newPriceInWei) external onlyOwner {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        s.pricePerTierInWei[_tier] = _newPriceInWei;
        emit PriceForTierSet(_tier, _newPriceInWei);
    }

    /// @notice Menarik ETH yang terkumpul di kontrak (PENTING)
    function withdrawFunds(address _to) external onlyOwner {
        if (_to == address(0)) revert InvalidRecipient();
        
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = payable(_to).call{value: balance}("");
            if (!success) revert TransferFailed();
            emit FundsWithdrawn(_to, balance);
        }
    }

    // --- View Functions ---

    function getPriceForTier(LibIdentityStorage.SubscriptionTier _tier) external view returns (uint256) {
        return LibIdentityStorage.layout().pricePerTierInWei[_tier];
    }

    function getPremiumExpiration(uint256 tokenId) external view returns (uint256) {
        return LibIdentityStorage.layout().premiumExpirations[tokenId];
    }

    function isPremium(uint256 tokenId) external view returns (bool) {
        return LibIdentityStorage.layout().premiumExpirations[tokenId] > block.timestamp;
    }

    // --- Core Logic ---

    /// @notice Upgrade atau perpanjang durasi premium
    function upgradeToPremium(uint256 tokenId, LibIdentityStorage.SubscriptionTier tier) external payable {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();

        // 1. Validasi Kepemilikan Token
        if (s._tokenIdToAddress[tokenId] != msg.sender) {
            revert NotTokenOwner();
        }

        // 2. Validasi Harga
        uint256 requiredPrice = s.pricePerTierInWei[tier];
        if (requiredPrice == 0) revert InvalidTierPrice(); // Pastikan harga sudah diset admin
        if (msg.value < requiredPrice) revert InsufficientPayment(requiredPrice, msg.value);

        // 3. Tentukan Durasi
        uint256 duration;
        if (tier == LibIdentityStorage.SubscriptionTier.ONE_MONTH) {
            duration = 30 days;
        } else if (tier == LibIdentityStorage.SubscriptionTier.SIX_MONTHS) {
            duration = 180 days;
        } else if (tier == LibIdentityStorage.SubscriptionTier.ONE_YEAR) {
            duration = 365 days;
        } else {
            revert InvalidSubscriptionTier();
        }

        // 4. Update State (Expirations)
        uint256 currentExpiration = s.premiumExpirations[tokenId];
        // Jika masih aktif, tambah dari waktu expired. Jika sudah mati, tambah dari sekarang.
        uint256 startingPoint = (currentExpiration > block.timestamp) ? currentExpiration : block.timestamp;
        
        uint256 newExpiration = startingPoint + duration;
        s.premiumExpirations[tokenId] = newExpiration;

        emit SubscriptionRenewed(tokenId, newExpiration, tier);

        // 5. Refund Kelebihan Bayar (Best Practice)
        if (msg.value > requiredPrice) {
            uint256 refund = msg.value - requiredPrice;
            (bool success, ) = payable(msg.sender).call{value: refund}("");
            if (!success) revert TransferFailed();
        }
    }
}
