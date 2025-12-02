// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {LoopTemplateStorage} from "./storage/LoopTemplateStorage.sol";
import {ILoopTemplateV1} from "./interfaces/ILoopTemplateV1.sol";
import {LoopTemplateErrors} from "./errors/LoopTemplateErrors.sol";

contract LoopTemplateV1 is
    UUPSUpgradeable,
    OwnableUpgradeable,
    LoopTemplateStorage,
    ILoopTemplateV1,
    LoopTemplateErrors
{
    function initialize(address initialOwner) external initializer {
        __Ownable_init(initialOwner);
    }

    function createLoopTemplate(
        address merchant,
        uint256 baseAmount,
        uint256 periodSeconds,
        string calldata metadataRef
    ) external override onlyOwner returns (uint256) {
        if (merchant == address(0)) revert InvalidMerchant();
        if (baseAmount == 0) revert InvalidAmount();
        if (periodSeconds == 0) revert InvalidPeriod();

        uint256 templateId = ++_templateCounter;
        uint256 timestamp = block.timestamp;

        _templates[templateId] = LoopTemplate({
            merchant: merchant,
            baseAmount: baseAmount,
            periodSeconds: periodSeconds,
            metadataRef: metadataRef,
            createdAt: timestamp,
            lastUpdatedAt: timestamp,
            active: true
        });

        emit LoopTemplateCreated(templateId, merchant, baseAmount, periodSeconds);

        return templateId;
    }

    function getLoopTemplate(uint256 templateId)
        external
        view
        override
        returns (
            address merchant,
            uint256 baseAmount,
            uint256 periodSeconds,
            string memory metadataRef,
            uint256 createdAt,
            uint256 lastUpdatedAt,
            bool active
        )
    {
        LoopTemplate memory template = _templates[templateId];
        if (template.createdAt == 0) revert TemplateNotFound();

        return (
            template.merchant,
            template.baseAmount,
            template.periodSeconds,
            template.metadataRef,
            template.createdAt,
            template.lastUpdatedAt,
            template.active
        );
    }

    function pauseLoop(uint256 templateId) external override onlyOwner {
        LoopTemplate storage template = _templates[templateId];
        if (template.createdAt == 0) revert TemplateNotFound();
        if (!template.active) revert TemplateAlreadyPaused();

        template.active = false;
        template.lastUpdatedAt = block.timestamp;

        emit LoopTemplatePaused(templateId, block.timestamp);
    }

    function resumeLoop(uint256 templateId) external override onlyOwner {
        LoopTemplate storage template = _templates[templateId];
        if (template.createdAt == 0) revert TemplateNotFound();
        if (template.active) revert TemplateAlreadyActive();

        template.active = true;
        template.lastUpdatedAt = block.timestamp;

        emit LoopTemplateResumed(templateId, block.timestamp);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function version() external pure returns (string memory) {
        return "1.0.0";
    }
}
