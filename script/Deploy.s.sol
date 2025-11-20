// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/PaymentLoop.sol";
import "../src/PaymentInvoiceNFT.sol";
import "../src/constants/Constants.sol";

contract DeployScript is Script {
    function getUSDCAddress() internal view returns (address) {
        uint256 chainId = block.chainid;
        if (chainId == 8453) {
            return Constants.BASE_USDC_MAINNET;
        } else if (chainId == 84532) {
            return Constants.BASE_USDC_SEPOLIA;
        } else {
            revert("Unsupported network");
        }
    }

    function run() external {
        // Get private key as string to handle both formats (with or without 0x prefix)
        string memory pkString = vm.envString("PRIVATE_KEY");

        // Add 0x prefix if not present
        if (bytes(pkString).length >= 2) {
            if (!(bytes(pkString)[0] == 0x30 && bytes(pkString)[1] == 0x78)) { // Check for '0x'
                pkString = string(abi.encodePacked("0x", pkString));
            }
        }

        uint256 deployerPrivateKey = vm.parseUint(pkString);
        address usdcAddress = getUSDCAddress();

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

        console.log("Network Chain ID:", block.chainid);
        console.log("Using USDC at:", usdcAddress);
        console.log("NFT Implementation deployed at:", address(nftImplementation));
        console.log("NFT Proxy deployed at:", address(nftProxy));
        console.log("PaymentLoop Implementation deployed at:", address(implementation));
        console.log("PaymentLoop Proxy deployed at:", address(proxy));

        vm.stopBroadcast();
    }
}
