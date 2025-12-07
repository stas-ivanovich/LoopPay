// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MandateStorage} from "../storage/MandateStorage.sol";

interface IMandateV1 {
    event MandateCreated(
        uint256 indexed mandateId,
        address indexed owner,
        address indexed spender,
        address token,
        uint256 perChargeLimit,
        uint256 totalLimit,
        uint256 startTime,
        uint256 endTime
    );

    event MandateLimitsUpdated(
        uint256 indexed mandateId,
        uint256 newPerChargeLimit,
        uint256 newTotalLimit
    );

    event MandateRevoked(uint256 indexed mandateId, uint256 timestamp);
    event MandatePaused(uint256 indexed mandateId, uint256 timestamp);
    event MandateResumed(uint256 indexed mandateId, uint256 timestamp);

    function createMandate(
        address spender,
        address token,
        uint256 perChargeLimit,
        uint256 totalLimit,
        uint256 cooldownSeconds,
        uint256 startTime,
        uint256 endTime
    ) external returns (uint256);

    function getMandate(uint256 mandateId)
        external
        view
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
            MandateStorage.MandateStatus status,
            uint256 createdAt,
            uint256 updatedAt
        );

    function updateMandateLimits(
        uint256 mandateId,
        uint256 newPerChargeLimit,
        uint256 newTotalLimit
    ) external;

    function revokeMandate(uint256 mandateId) external;
    function pauseMandate(uint256 mandateId) external;
    function resumeMandate(uint256 mandateId) external;
}
