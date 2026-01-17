// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Sources flattened with hardhat v2.26.3 https://hardhat.org

// SPDX-License-Identifier: MIT

// File contracts/interfaces/IDiamondCut.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.24;

interface IDiamondCut {
    enum FacetCutAction { Add, Replace, Remove }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}


// File contracts/diamond/libraries/LibDiamond.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.24;

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        mapping(bytes4 => address) facetAddress;
        bytes4[] selectors;
        mapping(bytes4 => uint256) selectorPosition;
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);
    
    function setContractOwner(address _owner) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.contractOwner = _owner;
    }

    function contractOwner() internal view returns (address owner_) {
        owner_ = diamondStorage().contractOwner;
    }

    function enforceIsOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }
}


// File contracts/diamond/Diamond.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.24;


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
