// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {MandateStorage} from "./storage/MandateStorage.sol";
import {IMandateV1} from "./interfaces/IMandateV1.sol";
import {MandateErrors} from "./errors/MandateErrors.sol";

contract MandateV1 is
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    MandateStorage,
    IMandateV1,
    MandateErrors
{
    function initialize(address initialOwner) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        if (initialOwner != msg.sender) {
            _transferOwnership(initialOwner);
        }
    }

    function createMandate(
        address spender,
        address token,
        uint256 perChargeLimit,
        uint256 totalLimit,
        uint256 cooldownSeconds,
        uint256 startTime,
        uint256 endTime
    ) external override nonReentrant returns (uint256) {
        if (msg.sender == address(0)) revert InvalidOwner();
        if (spender == address(0)) revert InvalidSpender();
        if (token == address(0)) revert InvalidToken();
        if (msg.sender == spender) revert OwnerCannotBeSpender();
        if (perChargeLimit == 0 || totalLimit == 0) revert InvalidLimits();
        if (perChargeLimit > totalLimit) revert PerChargeLimitExceedsTotalLimit();
        if (startTime >= endTime) revert InvalidTimeRange();
        if (startTime < block.timestamp) startTime = block.timestamp;

        uint256 mandateId = ++_mandateCounter;
        uint256 timestamp = block.timestamp;

        _mandates[mandateId] = Mandate({
            owner: msg.sender,
            spender: spender,
            token: token,
            perChargeLimit: perChargeLimit,
            totalLimit: totalLimit,
            spent: 0,
            cooldownSeconds: cooldownSeconds,
            lastDebitAt: 0,
            startTime: startTime,
            endTime: endTime,
            status: MandateStatus.Active,
            createdAt: timestamp,
            updatedAt: timestamp
        });

        emit MandateCreated(
            mandateId,
            msg.sender,
            spender,
            token,
            perChargeLimit,
            totalLimit,
            startTime,
            endTime
        );

        return mandateId;
    }

    function getMandate(uint256 mandateId)
        external
        view
        override
        returns (
            address owner,
            address spender,
            address token,
            uint256 perChargeLimit,
            uint256 totalLimit,
            uint256 spent,
            uint256 cooldownSeconds,
            uint256 lastDebitAt,
            uint256 startTime,
            uint256 endTime,
            MandateStatus status,
            uint256 createdAt,
            uint256 updatedAt
        )
    {
        Mandate memory mandate = _mandates[mandateId];
        if (mandate.createdAt == 0) revert MandateNotFound();

        MandateStatus currentStatus = mandate.status;
        if (currentStatus != MandateStatus.Revoked && block.timestamp > mandate.endTime) {
            currentStatus = MandateStatus.Expired;
        }

        return (
            mandate.owner,
            mandate.spender,
            mandate.token,
            mandate.perChargeLimit,
            mandate.totalLimit,
            mandate.spent,
            mandate.cooldownSeconds,
            mandate.lastDebitAt,
            mandate.startTime,
            mandate.endTime,
            currentStatus,
            mandate.createdAt,
            mandate.updatedAt
        );
    }

    function updateMandateLimits(
        uint256 mandateId,
        uint256 newPerChargeLimit,
        uint256 newTotalLimit
    ) external override nonReentrant {
        Mandate storage mandate = _mandates[mandateId];
        if (mandate.createdAt == 0) revert MandateNotFound();
        if (mandate.owner != msg.sender) revert NotMandateOwner();
        if (mandate.status == MandateStatus.Revoked) revert MandateAlreadyRevoked();
        if (block.timestamp > mandate.endTime) revert MandateExpired();

        if (newPerChargeLimit == 0 || newTotalLimit == 0) revert InvalidLimits();
        if (newPerChargeLimit > newTotalLimit) revert PerChargeLimitExceedsTotalLimit();
        if (newTotalLimit < mandate.spent) revert NewTotalLimitBelowSpent();

        mandate.perChargeLimit = newPerChargeLimit;
        mandate.totalLimit = newTotalLimit;
        mandate.updatedAt = block.timestamp;

        emit MandateLimitsUpdated(mandateId, newPerChargeLimit, newTotalLimit);
    }

    function revokeMandate(uint256 mandateId) external override nonReentrant {
        Mandate storage mandate = _mandates[mandateId];
        if (mandate.createdAt == 0) revert MandateNotFound();
        if (mandate.owner != msg.sender) revert NotMandateOwner();
        if (mandate.status == MandateStatus.Revoked) revert MandateAlreadyRevoked();

        mandate.status = MandateStatus.Revoked;
        mandate.updatedAt = block.timestamp;

        emit MandateRevoked(mandateId, block.timestamp);
    }

    function pauseMandate(uint256 mandateId) external override nonReentrant {
        Mandate storage mandate = _mandates[mandateId];
        if (mandate.createdAt == 0) revert MandateNotFound();
        if (mandate.owner != msg.sender) revert NotMandateOwner();
        if (mandate.status == MandateStatus.Revoked) revert MandateAlreadyRevoked();
        if (block.timestamp > mandate.endTime) revert MandateExpired();
        if (mandate.status == MandateStatus.Paused) revert MandateAlreadyPaused();
        if (mandate.status != MandateStatus.Active) revert MandateNotActive();

        mandate.status = MandateStatus.Paused;
        mandate.updatedAt = block.timestamp;

        emit MandatePaused(mandateId, block.timestamp);
    }

    function resumeMandate(uint256 mandateId) external override nonReentrant {
        Mandate storage mandate = _mandates[mandateId];
        if (mandate.createdAt == 0) revert MandateNotFound();
        if (mandate.owner != msg.sender) revert NotMandateOwner();
        if (mandate.status == MandateStatus.Revoked) revert MandateAlreadyRevoked();
        if (block.timestamp > mandate.endTime) revert MandateExpired();
        if (mandate.status == MandateStatus.Active) revert MandateAlreadyActive();
        if (mandate.status != MandateStatus.Paused) revert MandateNotActive();

        mandate.status = MandateStatus.Active;
        mandate.updatedAt = block.timestamp;

        emit MandateResumed(mandateId, block.timestamp);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function version() external pure returns (string memory) {
        return "1.0.0";
    }
}
