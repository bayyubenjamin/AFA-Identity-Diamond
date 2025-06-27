// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/LibIdentityStorage.sol";
import "../interfaces/IOwnershipFacet.sol";

contract SubscriptionManagerFacet {
    using LibIdentityStorage for LibIdentityStorage.Layout;

    event SubscriptionRenewed(uint256 indexed tokenId, uint256 newExpiration);

    /**
     * PERUBAHAN: Mengatur harga dalam satuan WEI (misal: 1000000000000000 = 0.001 ETH)
     * Pemilik kontrak memanggil fungsi ini untuk menetapkan harga baru.
     */
    function setPriceInWei(uint256 _newPriceInWei) external {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        require(msg.sender == IOwnershipFacet(address(this)).owner(), "AFA: Must be admin");
        // Variabel penyimpanan sekarang menyimpan harga dalam Wei
        s.priceInWei = _newPriceInWei;
    }

    /**
     * PERUBAHAN: Mengambil harga premium dalam satuan WEI.
     * Website Anda akan memanggil fungsi ini untuk mengetahui harga.
     */
    function priceInWei() external view returns (uint256) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        return s.priceInWei;
    }

    /**
     * Upgrade NFT ke premium. Fungsi lain tidak diubah, hanya logika pengecekan harga.
     */
    function upgradeToPremium(uint256 tokenId) external payable {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        require(s._tokenIdToAddress[tokenId] == msg.sender, "Not token owner");

        // PERUBAHAN: Logika pengecekan harga sekarang langsung menggunakan Wei
        uint256 requiredPrice = s.priceInWei; // Mengambil harga dalam Wei
        require(requiredPrice > 0, "Premium price not set");
        require(msg.value >= requiredPrice, "Insufficient ETH payment"); // Membandingkan dengan ETH yang dikirim

        s.premiumExpirations[tokenId] = block.timestamp + 30 days;

        emit SubscriptionRenewed(tokenId, s.premiumExpirations[tokenId]);
    }

    /**
     * (TIDAK BERUBAH) Cek kapan masa premium habis.
     */
    function getPremiumExpiration(uint256 tokenId) external view returns (uint256) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        return s.premiumExpirations[tokenId];
    }

    /**
     * (TIDAK BERUBAH) Apakah tokenId masih premium.
     */
    function isPremium(uint256 tokenId) external view returns (bool) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        return s.premiumExpirations[tokenId] > block.timestamp;
    }
}
