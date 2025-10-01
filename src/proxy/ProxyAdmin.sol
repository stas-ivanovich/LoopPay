// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ProxyAdmin is Ownable {
    constructor() Ownable(msg.sender) {}

    function getProxyImplementation(address proxy) external view returns (address) {
        bytes32 slot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        bytes32 value;
        assembly {
            value := sload(slot)
        }
        return address(uint160(uint256(value)));
    }
}
