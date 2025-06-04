// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/PaymentLoop.sol";
import "../src/PaymentLoopV2.sol";
import "../src/PaymentInvoiceNFT.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {
        _mint(msg.sender, 1000000 * 10**6);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

contract UpgradeTest is Test {
    PaymentLoop public paymentLoopV1;
    PaymentLoopV2 public paymentLoopV2;
    MockUSDC public usdc;
    PaymentInvoiceNFT public invoiceNFT;
    ERC1967Proxy public proxy;
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

        proxy = new ERC1967Proxy(address(implementation), initData);
        paymentLoopV1 = PaymentLoop(address(proxy));

        usdc.approve(address(paymentLoopV1), type(uint256).max);
    }

    function testUpgrade() public {
        uint256 loopId = paymentLoopV1.createLoop(recipient, 100 * 10**6, PaymentLoop.Interval.Daily);

        PaymentLoopV2 newImplementation = new PaymentLoopV2();
        paymentLoopV1.upgradeToAndCall(address(newImplementation), "");

        paymentLoopV2 = PaymentLoopV2(address(proxy));

        assertEq(paymentLoopV2.VERSION(), 2);

        (address loopRecipient, , , , , ) = paymentLoopV2.loops(loopId);
        assertEq(loopRecipient, recipient);
    }
}
