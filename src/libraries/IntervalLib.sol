// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library IntervalLib {
    enum Interval {
        Daily,
        Weekly,
        Monthly
    }

    function toSeconds(Interval _interval) internal pure returns (uint256) {
        if (_interval == Interval.Daily) return 1 days;
        if (_interval == Interval.Weekly) return 7 days;
        if (_interval == Interval.Monthly) return 30 days;
        revert("Invalid interval");
    }

    function toString(Interval _interval) internal pure returns (string memory) {
        if (_interval == Interval.Daily) return "Daily";
        if (_interval == Interval.Weekly) return "Weekly";
        if (_interval == Interval.Monthly) return "Monthly";
        return "Unknown";
    }
}
