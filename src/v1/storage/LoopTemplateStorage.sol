// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

abstract contract LoopTemplateStorage {
    struct LoopTemplate {
        address merchant;
        uint256 baseAmount;
        uint256 periodSeconds;
        string metadataRef;
        uint256 createdAt;
        uint256 lastUpdatedAt;
        bool active;
    }

    mapping(uint256 => LoopTemplate) internal _templates;
    uint256 internal _templateCounter;

    uint256[47] private __gap;
}
