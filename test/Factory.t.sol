// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/PaymentLoopFactory.sol";
import "../src/PaymentLoop.sol";
import "../src/mocks/MockERC20.sol";

contract FactoryTest is Test {
    PaymentLoopFactory public factory;
    MockERC20 public usdc;

    function setUp() public {
        factory = new PaymentLoopFactory();
        usdc = new MockERC20("USDC", "USDC", 6);
    }

    function testDeployPaymentLoop() public {
        address proxyAddress = factory.deploy(address(usdc));

        assertTrue(proxyAddress != address(0));

        PaymentLoop paymentLoop = PaymentLoop(proxyAddress);
        assertEq(address(paymentLoop.paymentToken()), address(usdc));
    }
}
