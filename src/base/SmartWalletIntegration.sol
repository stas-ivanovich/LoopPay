// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

abstract contract SmartWalletIntegration {
    event SmartWalletUsed(address indexed wallet, uint256 indexed loopId);

    function _verifySmartWallet(address _wallet) internal view virtual returns (bool) {
        return _wallet.code.length > 0;
    }

    function supportsSmartWallets() external pure returns (bool) {
        return true;
    }
}
