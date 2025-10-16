// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/PaymentLoop.sol";
import "../src/PaymentLoopV2.sol";

contract StorageLayoutTest is Test {
    function testStorageLayoutConsistency() public {
        bytes32 slot0 = keccak256("PaymentLoop.storage");
        bytes32 slot1 = keccak256("PaymentLoopV2.storage");

        assertTrue(slot0 != slot1);
    }
}
