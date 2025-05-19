// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./PaymentLoop.sol";
import "./PaymentInvoiceNFT.sol";

contract PaymentLoopFactory {
    event PaymentLoopDeployed(address indexed proxy, address indexed owner);

    function deploy(address _paymentToken) external returns (address) {
        PaymentInvoiceNFT nftImpl = new PaymentInvoiceNFT();
        bytes memory nftInitData = abi.encodeWithSelector(PaymentInvoiceNFT.initialize.selector);
        ERC1967Proxy nftProxy = new ERC1967Proxy(address(nftImpl), nftInitData);

        PaymentLoop implementation = new PaymentLoop();
        bytes memory initData = abi.encodeWithSelector(
            PaymentLoop.initialize.selector,
            _paymentToken,
            address(nftProxy)
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        emit PaymentLoopDeployed(address(proxy), msg.sender);

        return address(proxy);
    }
}
