// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/PaymentLoop.sol";
import "../src/PaymentInvoiceNFT.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address usdcAddress = vm.envAddress("USDC_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        PaymentInvoiceNFT nftImplementation = new PaymentInvoiceNFT();
        bytes memory nftInitData = abi.encodeWithSelector(
            PaymentInvoiceNFT.initialize.selector
        );
        ERC1967Proxy nftProxy = new ERC1967Proxy(
            address(nftImplementation),
            nftInitData
        );

        PaymentLoop implementation = new PaymentLoop();
        bytes memory initData = abi.encodeWithSelector(
            PaymentLoop.initialize.selector,
            usdcAddress,
            address(nftProxy)
        );

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );

        console.log("NFT Implementation deployed at:", address(nftImplementation));
        console.log("NFT Proxy deployed at:", address(nftProxy));
        console.log("PaymentLoop Implementation deployed at:", address(implementation));
        console.log("PaymentLoop Proxy deployed at:", address(proxy));

        vm.stopBroadcast();
    }
}
