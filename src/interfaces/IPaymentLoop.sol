// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPaymentLoop {
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

    function createLoop(address _recipient, uint256 _amount, Interval _interval) external returns (uint256);
    function executeLoop(uint256 _loopId) external;
    function pauseLoop(uint256 _loopId) external;
    function resumeLoop(uint256 _loopId) external;
    function cancelLoop(uint256 _loopId) external;
    function updateLoop(uint256 _loopId, address _newRecipient, uint256 _newAmount) external;
}
