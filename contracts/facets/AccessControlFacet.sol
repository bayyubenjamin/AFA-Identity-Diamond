// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";

library LibAccessControlStorage {
    bytes32 constant STORAGE_POSITION = keccak256("afa.identity.access.control.storage.v1");

    struct Layout {
        // Role Hash -> Address -> Boolean
        mapping(bytes32 => mapping(address => bool)) roles;
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly { s.slot := position }
    }
}

contract AccessControlFacet {
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    // Default Admin Role
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    // Role khusus untuk mengatur Gamification/Quest
    bytes32 public constant GAME_MASTER_ROLE = keccak256("GAME_MASTER_ROLE");
    // Role khusus untuk update parameter sistem
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");

    modifier onlyRole(bytes32 _role) {
        LibAccessControlStorage.Layout storage s = LibAccessControlStorage.layout();
        // Owner selalu punya akses admin
        if (msg.sender == LibDiamond.contractOwner()) {
            _;
            return;
        }
        require(s.roles[_role][msg.sender], "AccessControl: Missing Role");
        _;
    }

    function grantRole(bytes32 _role, address _account) external {
        // Hanya Owner atau Admin yang bisa kasih role
        LibAccessControlStorage.Layout storage s = LibAccessControlStorage.layout();
        require(
            msg.sender == LibDiamond.contractOwner() || s.roles[DEFAULT_ADMIN_ROLE][msg.sender],
            "AccessControl: Not authorized"
        );
        
        s.roles[_role][_account] = true;
        emit RoleGranted(_role, _account, msg.sender);
    }

    function revokeRole(bytes32 _role, address _account) external {
        LibAccessControlStorage.Layout storage s = LibAccessControlStorage.layout();
        require(
            msg.sender == LibDiamond.contractOwner() || s.roles[DEFAULT_ADMIN_ROLE][msg.sender],
            "AccessControl: Not authorized"
        );

        s.roles[_role][_account] = false;
        emit RoleRevoked(_role, _account, msg.sender);
    }

    function hasRole(bytes32 _role, address _account) external view returns (bool) {
        if (_account == LibDiamond.contractOwner()) return true;
        return LibAccessControlStorage.layout().roles[_role][_account];
    }
}
