// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MandateV1} from "../../src/v1/MandateV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployMandateV1 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying MandateV1 with deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        MandateV1 implementation = new MandateV1();
        console.log("Implementation deployed at:", address(implementation));

        bytes memory initData = abi.encodeCall(MandateV1.initialize, (deployer));

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        console.log("Proxy deployed at:", address(proxy));

        MandateV1 wrappedProxy = MandateV1(address(proxy));
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
