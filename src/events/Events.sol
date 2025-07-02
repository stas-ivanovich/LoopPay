// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPaymentLoopEvents {
    event LoopCreated(uint256 indexed loopId, address indexed recipient, uint256 amount, uint8 interval);
    event LoopExecuted(uint256 indexed loopId, uint256 amount, uint256 timestamp);
    event LoopUpdated(uint256 indexed loopId, address newRecipient, uint256 newAmount);
    event LoopPaused(uint256 indexed loopId);
    event LoopResumed(uint256 indexed loopId);
    event LoopCancelled(uint256 indexed loopId);
}
