// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/PaymentLoop.sol";

contract ExecuteLoopScript is Script {
    function run() external {
        uint256 executorPrivateKey = vm.envUint("EXECUTOR_PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        uint256 loopId = vm.envUint("LOOP_ID");

        vm.startBroadcast(executorPrivateKey);

        PaymentLoop paymentLoop = PaymentLoop(proxyAddress);
        paymentLoop.executeLoop(loopId);

        console.log("Loop executed:", loopId);

        vm.stopBroadcast();
    }
}
