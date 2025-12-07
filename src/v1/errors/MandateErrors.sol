// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface MandateErrors {
    error InvalidOwner();
    error InvalidSpender();
    error InvalidToken();
    error InvalidLimits();
    error InvalidTimeRange();
    error OwnerCannotBeSpender();
    error MandateNotFound();
    error MandateNotActive();
    error MandateAlreadyPaused();
    error MandateAlreadyActive();
    error MandateAlreadyRevoked();
    error MandateExpired();
    error NotMandateOwner();
    error PerChargeLimitExceedsTotalLimit();
    error NewTotalLimitBelowSpent();
}
