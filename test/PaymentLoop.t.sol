// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/PaymentLoop.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {
        _mint(msg.sender, 1000000 * 10**6);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

contract PaymentLoopTest is Test {
    PaymentLoop public paymentLoop;
    MockUSDC public usdc;
    address public owner;
    address public recipient;

    function setUp() public {
        owner = address(this);
        recipient = address(0x123);

        usdc = new MockUSDC();

        PaymentLoop implementation = new PaymentLoop();
        bytes memory initData = abi.encodeWithSelector(
            PaymentLoop.initialize.selector,
            address(usdc)
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        paymentLoop = PaymentLoop(address(proxy));

        usdc.approve(address(paymentLoop), type(uint256).max);
    }

    function testCreateLoop() public {
        uint256 loopId = paymentLoop.createLoop(recipient, 100 * 10**6, PaymentLoop.Interval.Daily);

        (
            address loopRecipient,
            uint256 amount,
            PaymentLoop.Interval interval,
            uint256 nextExecution,
            PaymentLoop.Status status,
            uint256 executionCount
        ) = paymentLoop.loops(loopId);

        assertEq(loopRecipient, recipient);
        assertEq(amount, 100 * 10**6);
        assertEq(uint256(interval), uint256(PaymentLoop.Interval.Daily));
        assertEq(uint256(status), uint256(PaymentLoop.Status.Active));
        assertEq(executionCount, 0);
    }

    function testExecuteLoop() public {
        uint256 loopId = paymentLoop.createLoop(recipient, 100 * 10**6, PaymentLoop.Interval.Daily);

        vm.warp(block.timestamp + 1 days);

        uint256 balanceBefore = usdc.balanceOf(recipient);
        paymentLoop.executeLoop(loopId);
        uint256 balanceAfter = usdc.balanceOf(recipient);

        assertEq(balanceAfter - balanceBefore, 100 * 10**6);
    }

    function testCannotExecuteBeforeTime() public {
        uint256 loopId = paymentLoop.createLoop(recipient, 100 * 10**6, PaymentLoop.Interval.Daily);

        vm.expectRevert("Too early");
        paymentLoop.executeLoop(loopId);
    }

    function testPauseAndResumeLoop() public {
        uint256 loopId = paymentLoop.createLoop(recipient, 100 * 10**6, PaymentLoop.Interval.Daily);

        paymentLoop.pauseLoop(loopId);
        (, , , , PaymentLoop.Status status, ) = paymentLoop.loops(loopId);
        assertEq(uint256(status), uint256(PaymentLoop.Status.Paused));

        paymentLoop.resumeLoop(loopId);
        (, , , , status, ) = paymentLoop.loops(loopId);
        assertEq(uint256(status), uint256(PaymentLoop.Status.Active));
    }
}
