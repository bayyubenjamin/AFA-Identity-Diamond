// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IDiamondLoupe {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /**
     * @notice Gets all facets and their selectors.
     * @return facets_ The facets and their selectors.
     */
    function facets() external view returns (Facet[] memory facets_);

    /**
     * @notice Gets all the function selectors supported by a specific facet.
     * @param _facet The facet address.
     * @return facetFunctionSelectors_ The selectors.
     */
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /**
     * @notice Get all the facet addresses used by the diamond.
     * @return facetAddresses_ The facet addresses.
     */
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /**
     * @notice Gets the facet that supports the given selector.
     * @dev If selector is not supported return address(0).
     * @param _functionSelector The selector.
     * @return facetAddress_ The facet address.
     */
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}
