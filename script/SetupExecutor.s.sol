// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/PaymentLoop.sol";

contract SetupExecutorScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        address executorAddress = vm.envAddress("EXECUTOR_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        PaymentLoop paymentLoop = PaymentLoop(proxyAddress);
        paymentLoop.grantRole(paymentLoop.EXECUTOR_ROLE(), executorAddress);

        console.log("Granted EXECUTOR_ROLE to:", executorAddress);

        vm.stopBroadcast();
    }
}
