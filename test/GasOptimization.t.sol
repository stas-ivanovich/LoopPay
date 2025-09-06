// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/PaymentLoop.sol";
import "../src/PaymentInvoiceNFT.sol";
import "../src/mocks/MockERC20.sol";

contract GasOptimizationTest is Test {
    PaymentLoop public paymentLoop;
    MockERC20 public usdc;

    function setUp() public {
        usdc = new MockERC20("USDC", "USDC", 6);

        PaymentInvoiceNFT nftImpl = new PaymentInvoiceNFT();
        bytes memory nftInitData = abi.encodeWithSelector(PaymentInvoiceNFT.initialize.selector);
        ERC1967Proxy nftProxy = new ERC1967Proxy(address(nftImpl), nftInitData);

        PaymentLoop implementation = new PaymentLoop();
        bytes memory initData = abi.encodeWithSelector(
            PaymentLoop.initialize.selector,
            address(usdc),
            address(nftProxy)
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        paymentLoop = PaymentLoop(address(proxy));

        usdc.approve(address(paymentLoop), type(uint256).max);
    }

    function testGasCreateLoop() public {
        uint256 gasBefore = gasleft();
        paymentLoop.createLoop(address(0x123), 100 * 10**6, PaymentLoop.Interval.Daily);
        uint256 gasUsed = gasBefore - gasleft();
        console.log("createLoop gas:", gasUsed);
    }
}
