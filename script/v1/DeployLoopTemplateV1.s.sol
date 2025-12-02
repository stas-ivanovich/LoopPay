// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoopTemplateV1} from "../../src/v1/LoopTemplateV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployLoopTemplateV1 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying LoopTemplateV1 with deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        LoopTemplateV1 implementation = new LoopTemplateV1();
        console.log("Implementation deployed at:", address(implementation));

        bytes memory initData = abi.encodeCall(LoopTemplateV1.initialize, (deployer));

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        console.log("Proxy deployed at:", address(proxy));

        LoopTemplateV1 wrappedProxy = LoopTemplateV1(address(proxy));
        console.log("Owner:", wrappedProxy.owner());
        console.log("Version:", wrappedProxy.version());

        vm.stopBroadcast();

        console.log("\nDeployment Summary:");
        console.log("-------------------");
        console.log("Chain ID:", block.chainid);
        console.log("Implementation:", address(implementation));
        console.log("Proxy:", address(proxy));
        console.log("Owner:", deployer);
    }
}
