// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library TimeCalculator {
    function addDays(uint256 timestamp, uint256 days) internal pure returns (uint256) {
        return timestamp + (days * 1 days);
    }

    function addWeeks(uint256 timestamp, uint256 weeks) internal pure returns (uint256) {
        return timestamp + (weeks * 7 days);
    }

    function addMonths(uint256 timestamp, uint256 months) internal pure returns (uint256) {
        return timestamp + (months * 30 days);
    }

    function isAfter(uint256 timestamp1, uint256 timestamp2) internal pure returns (bool) {
        return timestamp1 > timestamp2;
    }
}
