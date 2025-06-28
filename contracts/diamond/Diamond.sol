// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

contract Diamond {

    constructor(address _contractOwner, address _diamondCutFacet) payable {
        LibDiamond.setContractOwner(_contractOwner);

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        (bool success, ) = _diamondCutFacet.delegatecall(
            abi.encodeWithSelector(IDiamondCut.diamondCut.selector, cut, address(0), "")
        );
        require(success, "Diamond: initial diamond cut failed");
    }

    fallback() external payable {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        address facetAddress = ds.facetAddress[msg.sig];
        require(facetAddress != address(0), "Diamond: Function does not exist");
        
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facetAddress, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}
