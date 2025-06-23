// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/DiamondStorage.sol";

/**
 * @title AttestationFacet
 * @notice Facet untuk mengelola dan memeriksa status premium berdasarkan atestasi.
 */
contract AttestationFacet {
    AppStorage internal s;

    /**
     * @notice Menambahkan atestasi premium ke sebuah tokenId.
     * @dev Hanya boleh dipanggil secara internal oleh facet lain (misal: SubscriptionManagerFacet).
     * @param tokenId ID token yang akan diberi status premium.
     */
    function _addPremiumAttestation(uint256 tokenId) internal {
        require(s._tokenIdToAddress[tokenId] != address(0), "AttestationFacet: Token does not exist");
        
        // Membuat dan menyimpan atestasi baru
        s.premiumStatus[tokenId] = Attestation({
            expirationTimestamp: block.timestamp + 365 days,
            issuer: msg.sender // Sebaiknya diisi oleh alamat yang memanggil, misal facet lain
        });
    }

    /**
     * @notice Memeriksa apakah sebuah tokenId memiliki status premium yang aktif.
     * @param tokenId ID token yang akan diperiksa.
     * @return bool True jika premium dan belum kedaluwarsa, false jika sebaliknya.
     */
    function isPremium(uint256 tokenId) public view returns (bool) {
        Attestation storage att = s.premiumStatus[tokenId];
        
        // Jika belum pernah ada atestasi, issuer akan address(0)
        if (att.issuer == address(0)) {
            return false;
        }

        // Premium jika waktu saat ini belum melewati tanggal kedaluwarsa
        return block.timestamp < att.expirationTimestamp;
    }

    /**
     * @notice Mendapatkan waktu kedaluwarsa dari status premium sebuah tokenId.
     * @param tokenId ID token yang akan diperiksa.
     * @return uint256 Timestamp kedaluwarsa. Mengembalikan 0 jika tidak ada atestasi.
     */
    function getPremiumExpiration(uint256 tokenId) public view returns (uint256) {
        return s.premiumStatus[tokenId].expirationTimestamp;
    }
}
