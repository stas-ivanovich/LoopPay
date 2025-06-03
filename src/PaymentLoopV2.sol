// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PaymentLoop.sol";

contract PaymentLoopV2 is PaymentLoop {
    uint256 public constant VERSION = 2;

    mapping(uint256 => uint256) public loopTotalPaid;

    event LoopTotalUpdated(uint256 indexed loopId, uint256 totalPaid);

    function executeLoop(uint256 _loopId) external override onlyRole(EXECUTOR_ROLE) nonReentrant {
        Loop storage loop = loops[_loopId];
        require(loop.status == Status.Active, "Loop not active");
        require(block.timestamp >= loop.nextExecution, "Too early");

        require(
            paymentToken.transferFrom(owner(), loop.recipient, loop.amount),
            "Transfer failed"
        );

        loop.nextExecution = block.timestamp + _getIntervalSeconds(loop.interval);
        loop.executionCount++;

        loopTotalPaid[_loopId] += loop.amount;

        invoiceNFT.mintInvoice(loop.recipient, _loopId, loop.amount, owner());

        emit LoopExecuted(_loopId, loop.amount, block.timestamp);
        emit LoopTotalUpdated(_loopId, loopTotalPaid[_loopId]);
    }

    function getTotalPaid(uint256 _loopId) external view returns (uint256) {
        return loopTotalPaid[_loopId];
    }
}
