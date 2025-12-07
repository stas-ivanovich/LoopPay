// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

abstract contract MandateStorage {
    enum MandateStatus {
        Active,
        Paused,
        Revoked,
        Expired
    }

    struct Mandate {
        address owner;
        address spender;
        address token;
        uint256 perChargeLimit;
        uint256 totalLimit;
        uint256 spent;
        uint256 cooldownSeconds;
        uint256 lastDebitAt;
        uint256 startTime;
        uint256 endTime;
        MandateStatus status;
        uint256 createdAt;
        uint256 updatedAt;
    }

    mapping(uint256 => Mandate) internal _mandates;
    uint256 internal _mandateCounter;

    uint256[47] private __gap;
}
