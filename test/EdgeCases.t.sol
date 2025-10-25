// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/PaymentLoop.sol";
import "../src/PaymentInvoiceNFT.sol";
import "../src/mocks/MockERC20.sol";

contract EdgeCasesTest is Test {
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
    }

    function testCannotCreateLoopWithZeroAddress() public {
        vm.expectRevert("Invalid recipient");
        paymentLoop.createLoop(address(0), 100 * 10**6, PaymentLoop.Interval.Daily);
    }

    function testCannotCreateLoopWithZeroAmount() public {
        vm.expectRevert("Amount must be positive");
        paymentLoop.createLoop(address(0x123), 0, PaymentLoop.Interval.Daily);
    }
}
