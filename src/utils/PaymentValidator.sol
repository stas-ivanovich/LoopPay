// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library PaymentValidator {
    function validateRecipient(address _recipient) internal pure {
        require(_recipient != address(0), "Invalid recipient");
    }

    function validateAmount(uint256 _amount) internal pure {
        require(_amount > 0, "Amount must be positive");
    }

    function validateInterval(uint8 _interval) internal pure {
        require(_interval <= 2, "Invalid interval");
    }
}
