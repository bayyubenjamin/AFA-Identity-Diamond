// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Sources flattened with hardhat v2.26.3 https://hardhat.org

// SPDX-License-Identifier: MIT

// File contracts/interfaces/IOwnershipFacet.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.24;

interface IOwnershipFacet {
    function owner() external view returns (address owner_);
}


// File contracts/libraries/LibIdentityStorage.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.24;

library LibIdentityStorage {
    enum SubscriptionTier {
        ONE_MONTH,
        SIX_MONTHS,
        ONE_YEAR
    }

    struct Layout {
        mapping(address => uint256) _addressToTokenId;
        mapping(uint256 => address) _tokenIdToAddress;
        address verifierAddress;
        string baseURI;
        mapping(address => uint256) nonce;
        mapping(uint256 => uint256) premiumExpirations;
        
        mapping(SubscriptionTier => uint256) pricePerTierInWei;

        mapping(address => mapping(uint256 => uint256)) _ownedTokens;
        mapping(uint256 => uint256) _ownedTokensIndex;
        uint256[] _allTokens;
        mapping(uint256 => uint256) _allTokensIndex;
        mapping(uint256 => address) _owners;
        mapping(address => uint256) _balances;
        uint256 _tokenIdTracker;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("identity.storage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function _mint(Layout storage s, address to) internal returns (uint256 tokenId) {
        require(to != address(0), "mint to zero address");
        require(s._addressToTokenId[to] == 0, "AFA: Address already has an identity");

        tokenId = ++s._tokenIdTracker;
        s._tokenIdToAddress[tokenId] = to;
        s._addressToTokenId[to] = tokenId;
        s._owners[tokenId] = to;
        s._balances[to] += 1;

        uint256 len = s._balances[to] - 1;
        s._ownedTokens[to][len] = tokenId;
        s._ownedTokensIndex[tokenId] = len;
        s._allTokensIndex[tokenId] = s._allTokens.length;
        s._allTokens.push(tokenId);
    }
}


// File contracts/facets/TestingAdminFacet.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.24;


contract TestingAdminFacet {
    // Start token IDs from 1
    uint256 private _nextTokenId;

    event AdminIdentityMinted(address indexed recipient, uint256 indexed tokenId);

    /**
     * @notice Mints a new identity for a user, bypassing payment and signature checks.
     * @dev Only the contract owner can call this function.
     * @param _recipient The address that will receive the new identity NFT.
     */
    function adminMint(address _recipient) external {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();

        require(msg.sender == IOwnershipFacet(address(this)).owner(), "AFA: Must be admin");
        require(_recipient != address(0), "AFA: Cannot mint to zero address");
        require(s._addressToTokenId[_recipient] == 0, "AFA: User already has an identity");

        if (_nextTokenId == 0) {
            _nextTokenId = 1;
        }

        uint256 tokenId = _nextTokenId;
        _nextTokenId++;

        s._addressToTokenId[_recipient] = tokenId;
        s._tokenIdToAddress[tokenId] = _recipient;

        s.premiumExpirations[tokenId] = block.timestamp + 365 days;

        emit AdminIdentityMinted(_recipient, tokenId);
    }
}
