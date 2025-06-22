// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { AppStorage } from "../../storage/AppStorage.sol";

/// @title LibDiamond
/// @author Nick Mudge <nick@moodge.dev> (modified for AFA)
/// @notice Library for diamond storage and events, based on EIP-2535.
library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        mapping(bytes4 => bytes32) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => uint256) selectorIndices;
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    bytes32 constant APP_STORAGE_POSITION = keccak256("afa.identity.app.storage");

    function appStorage() internal pure returns (AppStorage storage s) {
        bytes32 position = APP_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
    
    // CORRECT ORDER: Define enum and struct BEFORE they are used in the event.
    enum Action { Add, Replace, Remove }

    struct FacetCut {
        address facetAddress;
        Action action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    modifier enforceIsOwner() {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
        _;
    }
}
