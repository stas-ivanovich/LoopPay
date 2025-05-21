// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/PaymentLoop.sol";

contract QueryLoopScript is Script {
    function run() external view {
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        uint256 loopId = vm.envUint("LOOP_ID");

        PaymentLoop paymentLoop = PaymentLoop(proxyAddress);

        (
            address recipient,
            uint256 amount,
            PaymentLoop.Interval interval,
            uint256 nextExecution,
            PaymentLoop.Status status,
            uint256 executionCount
        ) = paymentLoop.getLoopDetails(loopId);

        console.log("Loop ID:", loopId);
        console.log("Recipient:", recipient);
        console.log("Amount:", amount);
        console.log("Next Execution:", nextExecution);
        console.log("Execution Count:", executionCount);
    }
}
