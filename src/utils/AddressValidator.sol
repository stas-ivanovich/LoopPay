// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library AddressValidator {
    function isContract(address _addr) internal view returns (bool) {
        return _addr.code.length > 0;
    }

    function isZeroAddress(address _addr) internal pure returns (bool) {
        return _addr == address(0);
    }

    function requireNonZero(address _addr) internal pure {
        require(_addr != address(0), "Zero address");
    }
}
