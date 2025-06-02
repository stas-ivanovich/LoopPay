// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

abstract contract BasePayIntegration {
    event BasePayExecuted(uint256 indexed loopId, bytes32 indexed txHash);

    function _executeViaBasePay(uint256 _loopId, bytes memory _data) internal virtual {
        emit BasePayExecuted(_loopId, keccak256(_data));
    }

    function supportsBasePay() external pure returns (bool) {
        return true;
    }
}
