// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../PaymentInvoiceNFT.sol";

abstract contract LoopStorage {
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

    struct Loop {
        address recipient;
        uint256 amount;
        Interval interval;
        uint256 nextExecution;
        Status status;
        uint256 executionCount;
    }

    IERC20 public paymentToken;
    PaymentInvoiceNFT public invoiceNFT;
    mapping(uint256 => Loop) public loops;
    uint256 public loopCounter;

    uint256[50] private __gap;
}
