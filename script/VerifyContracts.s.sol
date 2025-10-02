// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";

contract VerifyContractsScript is Script {
    function run() external view {
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        console.log("Verifying contracts for proxy:", proxyAddress);
        console.log("Run: forge verify-contract <address> <contract> --chain-id <id>");
    }
}
