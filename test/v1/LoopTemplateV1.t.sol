// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {LoopTemplateV1} from "../../src/v1/LoopTemplateV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract LoopTemplateV1Test is Test {
    LoopTemplateV1 public implementation;
    LoopTemplateV1 public proxy;

    address public owner = address(0x1);
    address public merchant = address(0x2);
    address public notOwner = address(0x3);

    event LoopTemplateCreated(
        uint256 indexed templateId,
        address indexed merchant,
        uint256 baseAmount,
        uint256 periodSeconds
    );
    event LoopTemplatePaused(uint256 indexed templateId, uint256 timestamp);
    event LoopTemplateResumed(uint256 indexed templateId, uint256 timestamp);

    function setUp() public {
        implementation = new LoopTemplateV1();

        bytes memory initData = abi.encodeCall(LoopTemplateV1.initialize, (owner));
        ERC1967Proxy proxyContract = new ERC1967Proxy(address(implementation), initData);
        proxy = LoopTemplateV1(address(proxyContract));
    }

    function test_Initialize() public view {
        assertEq(proxy.owner(), owner);
        assertEq(proxy.version(), "1.0.0");
    }

    function test_CreateLoopTemplate() public {
        vm.startPrank(owner);

        uint256 baseAmount = 100e6;
        uint256 periodSeconds = 30 days;
        string memory metadataRef = "ipfs://QmTest";

        vm.expectEmit(true, true, false, true);
        emit LoopTemplateCreated(1, merchant, baseAmount, periodSeconds);

        uint256 templateId = proxy.createLoopTemplate(merchant, baseAmount, periodSeconds, metadataRef);

        assertEq(templateId, 1);

        (
            address retMerchant,
            uint256 retAmount,
            uint256 retPeriod,
            string memory retMetadata,
            uint256 retCreatedAt,
            uint256 retUpdatedAt,
            bool retActive
        ) = proxy.getLoopTemplate(templateId);

        assertEq(retMerchant, merchant);
        assertEq(retAmount, baseAmount);
        assertEq(retPeriod, periodSeconds);
        assertEq(retMetadata, metadataRef);
        assertEq(retCreatedAt, block.timestamp);
        assertEq(retUpdatedAt, block.timestamp);
        assertTrue(retActive);

        vm.stopPrank();
    }

    function test_RevertWhen_CreateWithZeroMerchant() public {
        vm.startPrank(owner);

        vm.expectRevert(abi.encodeWithSignature("InvalidMerchant()"));
        proxy.createLoopTemplate(address(0), 100e6, 30 days, "ipfs://test");

        vm.stopPrank();
    }

    function test_RevertWhen_CreateWithZeroAmount() public {
        vm.startPrank(owner);

        vm.expectRevert(abi.encodeWithSignature("InvalidAmount()"));
        proxy.createLoopTemplate(merchant, 0, 30 days, "ipfs://test");

        vm.stopPrank();
    }

    function test_RevertWhen_CreateWithZeroPeriod() public {
        vm.startPrank(owner);

        vm.expectRevert(abi.encodeWithSignature("InvalidPeriod()"));
        proxy.createLoopTemplate(merchant, 100e6, 0, "ipfs://test");

        vm.stopPrank();
    }

    function test_RevertWhen_CreateByNonOwner() public {
        vm.startPrank(notOwner);

        vm.expectRevert();
        proxy.createLoopTemplate(merchant, 100e6, 30 days, "ipfs://test");

        vm.stopPrank();
    }

    function test_PauseLoop() public {
        vm.startPrank(owner);

        uint256 templateId = proxy.createLoopTemplate(merchant, 100e6, 30 days, "ipfs://test");

        vm.expectEmit(true, false, false, true);
        emit LoopTemplatePaused(templateId, block.timestamp);

        proxy.pauseLoop(templateId);

        (,,,,,, bool active) = proxy.getLoopTemplate(templateId);
        assertFalse(active);

        vm.stopPrank();
    }

    function test_RevertWhen_PauseAlreadyPaused() public {
        vm.startPrank(owner);

        uint256 templateId = proxy.createLoopTemplate(merchant, 100e6, 30 days, "ipfs://test");
        proxy.pauseLoop(templateId);

        vm.expectRevert(abi.encodeWithSignature("TemplateAlreadyPaused()"));
        proxy.pauseLoop(templateId);

        vm.stopPrank();
    }

    function test_ResumeLoop() public {
        vm.startPrank(owner);

        uint256 templateId = proxy.createLoopTemplate(merchant, 100e6, 30 days, "ipfs://test");
        proxy.pauseLoop(templateId);

        vm.expectEmit(true, false, false, true);
        emit LoopTemplateResumed(templateId, block.timestamp);

        proxy.resumeLoop(templateId);

        (,,,,,, bool active) = proxy.getLoopTemplate(templateId);
        assertTrue(active);

        vm.stopPrank();
    }

    function test_RevertWhen_ResumeAlreadyActive() public {
        vm.startPrank(owner);

        uint256 templateId = proxy.createLoopTemplate(merchant, 100e6, 30 days, "ipfs://test");

        vm.expectRevert(abi.encodeWithSignature("TemplateAlreadyActive()"));
        proxy.resumeLoop(templateId);

        vm.stopPrank();
    }

    function test_RevertWhen_GetNonExistentTemplate() public {
        vm.expectRevert(abi.encodeWithSignature("TemplateNotFound()"));
        proxy.getLoopTemplate(999);
    }

    function test_MultipleTemplates() public {
        vm.startPrank(owner);

        uint256 template1 = proxy.createLoopTemplate(merchant, 100e6, 30 days, "ipfs://1");
        uint256 template2 = proxy.createLoopTemplate(merchant, 200e6, 7 days, "ipfs://2");

        assertEq(template1, 1);
        assertEq(template2, 2);

        (address m1,,,,,, bool a1) = proxy.getLoopTemplate(template1);
        (address m2,,,,,, bool a2) = proxy.getLoopTemplate(template2);

        assertEq(m1, merchant);
        assertEq(m2, merchant);
        assertTrue(a1);
        assertTrue(a2);

        vm.stopPrank();
    }

    function testFuzz_CreateLoopTemplate(
        uint256 baseAmount,
        uint256 periodSeconds
    ) public {
        vm.assume(baseAmount > 0 && baseAmount < type(uint128).max);
        vm.assume(periodSeconds > 0 && periodSeconds < 365 days);

        vm.startPrank(owner);

        uint256 templateId = proxy.createLoopTemplate(
            merchant,
            baseAmount,
            periodSeconds,
            "ipfs://fuzz"
        );

        (, uint256 retAmount, uint256 retPeriod,,,, bool retActive) = proxy.getLoopTemplate(templateId);

        assertEq(retAmount, baseAmount);
        assertEq(retPeriod, periodSeconds);
        assertTrue(retActive);

        vm.stopPrank();
    }
}
