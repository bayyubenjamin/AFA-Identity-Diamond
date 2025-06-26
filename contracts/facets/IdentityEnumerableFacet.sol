// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/LibIdentityStorage.sol";

interface IIdentityEnumerable {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

contract IdentityEnumerableFacet is IIdentityEnumerable {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view override returns (uint256) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        require(index < s._balances[owner], "owner index out of bounds");
        return s._ownedTokens[owner][index];
    }

    function totalSupply() external view override returns (uint256) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        return s._allTokens.length;
    }

    function tokenByIndex(uint256 index) external view override returns (uint256) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        require(index < s._allTokens.length, "global index out of bounds");
        return s._allTokens[index];
    }
}
