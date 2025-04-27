// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/PaymentLoop.sol";

contract CreateLoopScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        address recipient = vm.envAddress("RECIPIENT_ADDRESS");
        uint256 amount = vm.envUint("AMOUNT");
        uint8 intervalType = uint8(vm.envUint("INTERVAL"));

        vm.startBroadcast(deployerPrivateKey);

        PaymentLoop paymentLoop = PaymentLoop(proxyAddress);
        uint256 loopId = paymentLoop.createLoop(
            recipient,
            amount,
            PaymentLoop.Interval(intervalType)
        );

        console.log("Loop created with ID:", loopId);

        vm.stopBroadcast();
    }
}
