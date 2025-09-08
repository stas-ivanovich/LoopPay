// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/PaymentLoop.sol";

contract UpdateLoopScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        uint256 loopId = vm.envUint("LOOP_ID");
        address newRecipient = vm.envAddress("NEW_RECIPIENT");
        uint256 newAmount = vm.envUint("NEW_AMOUNT");

        vm.startBroadcast(deployerPrivateKey);

        PaymentLoop(proxyAddress).updateLoop(loopId, newRecipient, newAmount);
        console.log("Loop updated:", loopId);

        vm.stopBroadcast();
    }
}
