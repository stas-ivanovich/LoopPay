// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library TimeCalculator {
    function addDays(uint256 timestamp, uint256 numDays) internal pure returns (uint256) {
        return timestamp + (numDays * 1 days);
    }

    function addWeeks(uint256 timestamp, uint256 numWeeks) internal pure returns (uint256) {
        return timestamp + (numWeeks * 7 days);
    }

    function addMonths(uint256 timestamp, uint256 numMonths) internal pure returns (uint256) {
        return timestamp + (numMonths * 30 days);
    }

    function isAfter(uint256 timestamp1, uint256 timestamp2) internal pure returns (bool) {
        return timestamp1 > timestamp2;
    }
}
