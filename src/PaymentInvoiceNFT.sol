// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract PaymentInvoiceNFT is Initializable, ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 private _tokenIdCounter;

    struct Invoice {
        uint256 loopId;
        uint256 amount;
        uint256 timestamp;
        address payer;
        address recipient;
    }

    mapping(uint256 => Invoice) public invoices;

    event InvoiceMinted(uint256 indexed tokenId, uint256 indexed loopId, address indexed recipient);

    function initialize() public initializer {
        __ERC721_init("LoopPay Invoice", "LPINV");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function mintInvoice(
        address _recipient,
        uint256 _loopId,
        uint256 _amount,
        address _payer
    ) external onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter++;

        invoices[tokenId] = Invoice({
            loopId: _loopId,
            amount: _amount,
            timestamp: block.timestamp,
            payer: _payer,
            recipient: _recipient
        });

        _safeMint(_recipient, tokenId);

        emit InvoiceMinted(tokenId, _loopId, _recipient);

        return tokenId;
    }

    function getInvoice(uint256 _tokenId)
        external
        view
        returns (
            uint256 loopId,
            uint256 amount,
            uint256 timestamp,
            address payer,
            address recipient
        )
    {
        Invoice memory invoice = invoices[_tokenId];
        return (invoice.loopId, invoice.amount, invoice.timestamp, invoice.payer, invoice.recipient);
    }
}
