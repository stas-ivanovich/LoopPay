// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/PaymentLoop.sol";

contract CancelLoopScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        uint256 loopId = vm.envUint("LOOP_ID");

        vm.startBroadcast(deployerPrivateKey);

        PaymentLoop(proxyAddress).cancelLoop(loopId);
        console.log("Loop cancelled:", loopId);

        vm.stopBroadcast();
    }
}
