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

contract AccessControlTest is Test {
    PaymentLoop public paymentLoop;
    MockUSDC public usdc;
    address public owner;
    address public executor;
    address public user;

    function setUp() public {
        owner = address(this);
        executor = address(0x456);
        user = address(0x789);

        usdc = new MockUSDC();

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

    function testOnlyOwnerCanCreateLoop() public {
        vm.prank(user);
        vm.expectRevert();
        paymentLoop.createLoop(user, 100 * 10**6, PaymentLoop.Interval.Daily);
    }

    function testOnlyExecutorCanExecute() public {
        uint256 loopId = paymentLoop.createLoop(user, 100 * 10**6, PaymentLoop.Interval.Daily);
        vm.warp(block.timestamp + 1 days);

        vm.prank(user);
        vm.expectRevert();
        paymentLoop.executeLoop(loopId);
    }
}
