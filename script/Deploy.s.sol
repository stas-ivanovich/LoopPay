// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/PaymentLoop.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address usdcAddress = vm.envAddress("USDC_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        PaymentLoop implementation = new PaymentLoop();

        bytes memory initData = abi.encodeWithSelector(
            PaymentLoop.initialize.selector,
            usdcAddress
        );

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );

        console.log("Implementation deployed at:", address(implementation));
        console.log("Proxy deployed at:", address(proxy));

        vm.stopBroadcast();
    }
}
