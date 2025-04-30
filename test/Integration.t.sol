// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/PaymentLoop.sol";
import "../src/PaymentInvoiceNFT.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {
        _mint(msg.sender, 1000000 * 10**6);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

contract IntegrationTest is Test {
    PaymentLoop public paymentLoop;
    PaymentInvoiceNFT public invoiceNFT;
    MockUSDC public usdc;
    address public owner;
    address public recipient;

    function setUp() public {
        owner = address(this);
        recipient = address(0x123);

        usdc = new MockUSDC();

        PaymentInvoiceNFT nftImpl = new PaymentInvoiceNFT();
        bytes memory nftInitData = abi.encodeWithSelector(PaymentInvoiceNFT.initialize.selector);
        ERC1967Proxy nftProxy = new ERC1967Proxy(address(nftImpl), nftInitData);
        invoiceNFT = PaymentInvoiceNFT(address(nftProxy));

        PaymentLoop implementation = new PaymentLoop();
        bytes memory initData = abi.encodeWithSelector(
            PaymentLoop.initialize.selector,
            address(usdc),
            address(invoiceNFT)
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        paymentLoop = PaymentLoop(address(proxy));

        usdc.approve(address(paymentLoop), type(uint256).max);
    }

    function testFullPaymentFlow() public {
        uint256 loopId = paymentLoop.createLoop(recipient, 100 * 10**6, PaymentLoop.Interval.Daily);

        vm.warp(block.timestamp + 1 days);

        uint256 balanceBefore = usdc.balanceOf(recipient);
        paymentLoop.executeLoop(loopId);
        uint256 balanceAfter = usdc.balanceOf(recipient);

        assertEq(balanceAfter - balanceBefore, 100 * 10**6);

        uint256 nftBalance = invoiceNFT.balanceOf(recipient);
        assertEq(nftBalance, 1);
    }
}
