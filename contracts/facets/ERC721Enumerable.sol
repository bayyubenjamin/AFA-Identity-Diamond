// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IMPORTANT: Pastikan storage layout sama dengan facet utama (kamu harus sesuaikan bagian storage jika berbeda).
// Di bawah ini contoh storage layout OpenZeppelin. Jika kamu custom, sesuaikan!

library IdentityEnumerableStorage {
    struct Layout {
        // Mapping from owner to list of owned token IDs
        mapping(address => mapping(uint256 => uint256)) _ownedTokens;
        // Mapping from token ID to index of the owner tokens list
        mapping(uint256 => uint256) _ownedTokensIndex;
        // Array with all token ids, used for enumeration
        uint256[] _allTokens;
        // Mapping from token id to position in the allTokens array
        mapping(uint256 => uint256) _allTokensIndex;
        // Token owner mapping
        mapping(uint256 => address) _owners;
        // Token count mapping
        mapping(address => uint256) _balances;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("identity.enumerable.storage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

interface IIdentityEnumerable {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

contract IdentityEnumerableFacet is IIdentityEnumerable {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
        require(index < IdentityEnumerableStorage.layout()._balances[owner], "owner index out of bounds");
        return IdentityEnumerableStorage.layout()._ownedTokens[owner][index];
    }

    function totalSupply() external view returns (uint256) {
        return IdentityEnumerableStorage.layout()._allTokens.length;
    }

    function tokenByIndex(uint256 index) external view returns (uint256) {
        require(index < IdentityEnumerableStorage.layout()._allTokens.length, "global index out of bounds");
        return IdentityEnumerableStorage.layout()._allTokens[index];
    }
}
