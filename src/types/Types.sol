// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Types {
    enum Interval {
        Daily,
        Weekly,
        Monthly
    }

    enum Status {
        Active,
        Paused,
        Cancelled
    }

    struct LoopData {
        address recipient;
        uint256 amount;
        Interval interval;
        uint256 nextExecution;
        Status status;
        uint256 executionCount;
    }
}
