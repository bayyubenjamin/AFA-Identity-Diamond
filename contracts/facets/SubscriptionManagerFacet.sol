// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/LibIdentityStorage.sol";
import "../diamond/libraries/LibDiamond.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

library LibSubscriptionStorage {
    bytes32 constant STORAGE_POSITION = keccak256("afa.identity.subscription.storage.v1");
    struct Layout {
        uint256 monthlyPrice;  // Harga per 30 hari dalam Wei
        address treasury;      // Wallet penampung dana
    }
    function layout() internal pure returns (Layout storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly { s.slot := position }
    }
}

contract SubscriptionManagerFacet {
    event SubscriptionPurchased(uint256 indexed tokenId, uint256 daysAdded, uint256 newExpiration);
    event PriceUpdated(uint256 newPrice);
    
    // --- Admin ---

    function setSubscriptionConfig(uint256 _monthlyPrice, address _treasury) external {
        LibDiamond.enforceIsOwner();
        LibSubscriptionStorage.Layout storage ss = LibSubscriptionStorage.layout();
        ss.monthlyPrice = _monthlyPrice;
        ss.treasury = _treasury;
        emit PriceUpdated(_monthlyPrice);
    }

    // --- User Actions ---

    /// @notice Beli premium 1 bulan (30 hari)
    function buyPremium() external payable {
        LibIdentityStorage.Layout storage ids = LibIdentityStorage.layout();
        LibSubscriptionStorage.Layout storage ss = LibSubscriptionStorage.layout();
        
        uint256 tokenId = ids._addressToTokenId[msg.sender];
        require(tokenId != 0, "No Identity");
        require(msg.value >= ss.monthlyPrice, "Insufficient payment");

        // Kirim dana ke treasury
        if (ss.treasury != address(0)) {
            (bool success, ) = payable(ss.treasury).call{value: msg.value}("");
            require(success, "Transfer failed");
        }

        // Hitung durasi
        uint256 currentExp = ids.premiumExpirations[tokenId];
        uint256 nowTime = block.timestamp;
        
        // Jika masih aktif, tambah dari expiration lama. Jika mati, mulai dari sekarang.
        uint256 newExp;
        if (currentExp > nowTime) {
            newExp = currentExp + 30 days;
        } else {
            newExp = nowTime + 30 days;
        }

        ids.premiumExpirations[tokenId] = newExp;
        
        emit SubscriptionPurchased(tokenId, 30, newExp);
    }

    // --- View ---

    function getSubscriptionPrice() external view returns (uint256) {
        return LibSubscriptionStorage.layout().monthlyPrice;
    }
}
