// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/PaymentInvoiceNFT.sol";

contract PaymentInvoiceNFTTest is Test {
    PaymentInvoiceNFT public nft;
    address public owner;
    address public recipient;

    function setUp() public {
        owner = address(this);
        recipient = address(0x123);

        PaymentInvoiceNFT implementation = new PaymentInvoiceNFT();
        bytes memory initData = abi.encodeWithSelector(PaymentInvoiceNFT.initialize.selector);

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        nft = PaymentInvoiceNFT(address(proxy));
    }

    function testMintInvoice() public {
        uint256 tokenId = nft.mintInvoice(recipient, 1, 100 * 10**6, owner);

        assertEq(nft.ownerOf(tokenId), recipient);

        (uint256 loopId, uint256 amount, uint256 timestamp, address payer, address invoiceRecipient) = nft.getInvoice(tokenId);

        assertEq(loopId, 1);
        assertEq(amount, 100 * 10**6);
        assertEq(payer, owner);
        assertEq(invoiceRecipient, recipient);
    }

    function testOnlyOwnerCanMint() public {
        vm.prank(address(0x999));
        vm.expectRevert();
        nft.mintInvoice(recipient, 1, 100 * 10**6, owner);
    }
}
