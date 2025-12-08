// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MandateV1} from "../../src/v1/MandateV1.sol";
import {MandateStorage} from "../../src/v1/storage/MandateStorage.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract MandateV1Test is Test {
    MandateV1 public implementation;
    MandateV1 public proxy;

    address public owner = address(0x1);
    address public user = address(0x2);
    address public spender = address(0x3);
    address public token = address(0x4);

    event MandateCreated(
        uint256 indexed mandateId,
        address indexed owner,
        address indexed spender,
        address token,
        uint256 perChargeLimit,
        uint256 totalLimit,
        uint256 startTime,
        uint256 endTime
    );
    event MandateLimitsUpdated(
        uint256 indexed mandateId,
        uint256 newPerChargeLimit,
        uint256 newTotalLimit
    );
    event MandateRevoked(uint256 indexed mandateId, uint256 timestamp);
    event MandatePaused(uint256 indexed mandateId, uint256 timestamp);
    event MandateResumed(uint256 indexed mandateId, uint256 timestamp);

    function setUp() public {
        implementation = new MandateV1();

        bytes memory initData = abi.encodeCall(MandateV1.initialize, (owner));
        ERC1967Proxy proxyContract = new ERC1967Proxy(address(implementation), initData);
        proxy = MandateV1(address(proxyContract));
    }

    function test_Initialize() public view {
        assertEq(proxy.owner(), owner);
        assertEq(proxy.version(), "1.0.0");
    }

    function test_CreateMandate() public {
        vm.startPrank(user);

        uint256 perChargeLimit = 10e6;
        uint256 totalLimit = 100e6;
        uint256 cooldownSeconds = 1 hours;
        uint256 startTime = block.timestamp;
        uint256 endTime = block.timestamp + 30 days;

        vm.expectEmit(true, true, true, true);
        emit MandateCreated(
            1,
            user,
            spender,
            token,
            perChargeLimit,
            totalLimit,
            startTime,
            endTime
        );

        uint256 mandateId = proxy.createMandate(
            spender,
            token,
            perChargeLimit,
            totalLimit,
            cooldownSeconds,
            startTime,
            endTime
        );

        assertEq(mandateId, 1);

        (
            address retOwner,
            address retSpender,
            address retToken,
            uint256 retPerCharge,
            uint256 retTotal,
            uint256 retSpent,
            uint256 retCooldown,
            uint256 retLastDebit,
            uint256 retStart,
            uint256 retEnd,
            MandateStorage.MandateStatus retStatus,
            uint256 retCreated,
            uint256 retUpdated
        ) = proxy.getMandate(mandateId);

        assertEq(retOwner, user);
        assertEq(retSpender, spender);
        assertEq(retToken, token);
        assertEq(retPerCharge, perChargeLimit);
        assertEq(retTotal, totalLimit);
        assertEq(retSpent, 0);
        assertEq(retCooldown, cooldownSeconds);
        assertEq(retLastDebit, 0);
        assertEq(retStart, startTime);
        assertEq(retEnd, endTime);
        assertTrue(retStatus == MandateStorage.MandateStatus.Active);
        assertEq(retCreated, block.timestamp);
        assertEq(retUpdated, block.timestamp);

        vm.stopPrank();
    }

    function test_CreateMandateWithPastStartTime() public {
        vm.startPrank(user);

        vm.warp(100 days);
        uint256 pastStart = block.timestamp - 1 days;
        uint256 endTime = block.timestamp + 30 days;

        uint256 mandateId = proxy.createMandate(
            spender,
            token,
            10e6,
            100e6,
            1 hours,
            pastStart,
            endTime
        );

        (,,,,,,,, uint256 retStart,,,,) = proxy.getMandate(mandateId);
        assertEq(retStart, block.timestamp);

        vm.stopPrank();
    }

    function test_RevertWhen_CreateWithZeroSpender() public {
        vm.startPrank(user);

        vm.expectRevert(abi.encodeWithSignature("InvalidSpender()"));
        proxy.createMandate(
            address(0),
            token,
            10e6,
            100e6,
            1 hours,
            block.timestamp,
            block.timestamp + 30 days
        );

        vm.stopPrank();
    }

    function test_RevertWhen_CreateWithZeroToken() public {
        vm.startPrank(user);

        vm.expectRevert(abi.encodeWithSignature("InvalidToken()"));
        proxy.createMandate(
            spender,
            address(0),
            10e6,
            100e6,
            1 hours,
            block.timestamp,
            block.timestamp + 30 days
        );

        vm.stopPrank();
    }

    function test_RevertWhen_CreateWithOwnerAsSpender() public {
        vm.startPrank(user);

        vm.expectRevert(abi.encodeWithSignature("OwnerCannotBeSpender()"));
        proxy.createMandate(
            user,
            token,
            10e6,
            100e6,
            1 hours,
            block.timestamp,
            block.timestamp + 30 days
        );

        vm.stopPrank();
    }

    function test_RevertWhen_CreateWithZeroLimits() public {
        vm.startPrank(user);

        vm.expectRevert(abi.encodeWithSignature("InvalidLimits()"));
        proxy.createMandate(
            spender,
            token,
            0,
            100e6,
            1 hours,
            block.timestamp,
            block.timestamp + 30 days
        );

        vm.expectRevert(abi.encodeWithSignature("InvalidLimits()"));
        proxy.createMandate(
            spender,
            token,
            10e6,
            0,
            1 hours,
            block.timestamp,
            block.timestamp + 30 days
        );

        vm.stopPrank();
    }

    function test_RevertWhen_CreateWithPerChargeExceedsTotal() public {
        vm.startPrank(user);

        vm.expectRevert(abi.encodeWithSignature("PerChargeLimitExceedsTotalLimit()"));
        proxy.createMandate(
            spender,
            token,
            200e6,
            100e6,
            1 hours,
            block.timestamp,
            block.timestamp + 30 days
        );

        vm.stopPrank();
    }

    function test_RevertWhen_CreateWithInvalidTimeRange() public {
        vm.startPrank(user);

        uint256 startTime = block.timestamp + 30 days;
        uint256 endTime = block.timestamp + 15 days;

        vm.expectRevert(abi.encodeWithSignature("InvalidTimeRange()"));
        proxy.createMandate(
            spender,
            token,
            10e6,
            100e6,
            1 hours,
            startTime,
            endTime
        );

        vm.stopPrank();
    }

    function test_UpdateMandateLimits() public {
        vm.startPrank(user);

        uint256 mandateId = proxy.createMandate(
            spender,
            token,
            10e6,
            100e6,
            1 hours,
            block.timestamp,
            block.timestamp + 30 days
        );

        uint256 newPerCharge = 20e6;
        uint256 newTotal = 200e6;

        vm.expectEmit(true, false, false, true);
        emit MandateLimitsUpdated(mandateId, newPerCharge, newTotal);

        proxy.updateMandateLimits(mandateId, newPerCharge, newTotal);

        (,,, uint256 retPerCharge, uint256 retTotal,,,,,,,,) = proxy.getMandate(mandateId);
        assertEq(retPerCharge, newPerCharge);
        assertEq(retTotal, newTotal);

        vm.stopPrank();
    }

    function test_RevertWhen_UpdateLimitsNotOwner() public {
        vm.startPrank(user);

        uint256 mandateId = proxy.createMandate(
            spender,
            token,
            10e6,
            100e6,
            1 hours,
            block.timestamp,
            block.timestamp + 30 days
        );

        vm.stopPrank();

        vm.startPrank(spender);

        vm.expectRevert(abi.encodeWithSignature("NotMandateOwner()"));
        proxy.updateMandateLimits(mandateId, 20e6, 200e6);

        vm.stopPrank();
    }

    function test_RevertWhen_UpdateLimitsPerChargeExceedsTotal() public {
        vm.startPrank(user);

        uint256 mandateId = proxy.createMandate(
            spender,
            token,
            10e6,
            100e6,
            1 hours,
            block.timestamp,
            block.timestamp + 30 days
        );

        vm.expectRevert(abi.encodeWithSignature("PerChargeLimitExceedsTotalLimit()"));
        proxy.updateMandateLimits(mandateId, 200e6, 100e6);

        vm.stopPrank();
    }

    function test_RevokeMandate() public {
        vm.startPrank(user);

        uint256 mandateId = proxy.createMandate(
            spender,
            token,
            10e6,
            100e6,
            1 hours,
            block.timestamp,
            block.timestamp + 30 days
        );

        vm.expectEmit(true, false, false, true);
        emit MandateRevoked(mandateId, block.timestamp);

        proxy.revokeMandate(mandateId);

        (,,,,,,,,,, MandateStorage.MandateStatus retStatus,,) = proxy.getMandate(mandateId);
        assertTrue(retStatus == MandateStorage.MandateStatus.Revoked);

        vm.stopPrank();
    }

    function test_RevertWhen_RevokeNotOwner() public {
        vm.startPrank(user);

        uint256 mandateId = proxy.createMandate(
            spender,
            token,
            10e6,
            100e6,
            1 hours,
            block.timestamp,
            block.timestamp + 30 days
        );

        vm.stopPrank();

        vm.startPrank(spender);

        vm.expectRevert(abi.encodeWithSignature("NotMandateOwner()"));
        proxy.revokeMandate(mandateId);

        vm.stopPrank();
    }

    function test_RevertWhen_RevokeAlreadyRevoked() public {
        vm.startPrank(user);

        uint256 mandateId = proxy.createMandate(
            spender,
            token,
            10e6,
            100e6,
            1 hours,
            block.timestamp,
            block.timestamp + 30 days
        );

        proxy.revokeMandate(mandateId);

        vm.expectRevert(abi.encodeWithSignature("MandateAlreadyRevoked()"));
        proxy.revokeMandate(mandateId);

        vm.stopPrank();
    }

    function test_PauseMandate() public {
        vm.startPrank(user);

        uint256 mandateId = proxy.createMandate(
            spender,
            token,
            10e6,
            100e6,
            1 hours,
            block.timestamp,
            block.timestamp + 30 days
        );

        vm.expectEmit(true, false, false, true);
        emit MandatePaused(mandateId, block.timestamp);

        proxy.pauseMandate(mandateId);

        (,,,,,,,,,, MandateStorage.MandateStatus retStatus,,) = proxy.getMandate(mandateId);
        assertTrue(retStatus == MandateStorage.MandateStatus.Paused);

        vm.stopPrank();
    }

    function test_RevertWhen_PauseAlreadyPaused() public {
        vm.startPrank(user);

        uint256 mandateId = proxy.createMandate(
            spender,
            token,
            10e6,
            100e6,
            1 hours,
            block.timestamp,
            block.timestamp + 30 days
        );

        proxy.pauseMandate(mandateId);

        vm.expectRevert(abi.encodeWithSignature("MandateAlreadyPaused()"));
        proxy.pauseMandate(mandateId);

        vm.stopPrank();
    }

    function test_ResumeMandate() public {
        vm.startPrank(user);

        uint256 mandateId = proxy.createMandate(
            spender,
            token,
            10e6,
            100e6,
            1 hours,
            block.timestamp,
            block.timestamp + 30 days
        );

        proxy.pauseMandate(mandateId);

        vm.expectEmit(true, false, false, true);
        emit MandateResumed(mandateId, block.timestamp);

        proxy.resumeMandate(mandateId);

        (,,,,,,,,,, MandateStorage.MandateStatus retStatus,,) = proxy.getMandate(mandateId);
        assertTrue(retStatus == MandateStorage.MandateStatus.Active);

        vm.stopPrank();
    }

    function test_RevertWhen_ResumeAlreadyActive() public {
        vm.startPrank(user);

        uint256 mandateId = proxy.createMandate(
            spender,
            token,
            10e6,
            100e6,
            1 hours,
            block.timestamp,
            block.timestamp + 30 days
        );

        vm.expectRevert(abi.encodeWithSignature("MandateAlreadyActive()"));
        proxy.resumeMandate(mandateId);

        vm.stopPrank();
    }

    function test_RevertWhen_UpdateRevokedMandate() public {
        vm.startPrank(user);

        uint256 mandateId = proxy.createMandate(
            spender,
            token,
            10e6,
            100e6,
            1 hours,
            block.timestamp,
            block.timestamp + 30 days
        );

        proxy.revokeMandate(mandateId);

        vm.expectRevert(abi.encodeWithSignature("MandateAlreadyRevoked()"));
        proxy.updateMandateLimits(mandateId, 20e6, 200e6);

        vm.stopPrank();
    }

    function test_RevertWhen_PauseRevokedMandate() public {
        vm.startPrank(user);

        uint256 mandateId = proxy.createMandate(
            spender,
            token,
            10e6,
            100e6,
            1 hours,
            block.timestamp,
            block.timestamp + 30 days
        );

        proxy.revokeMandate(mandateId);

        vm.expectRevert(abi.encodeWithSignature("MandateAlreadyRevoked()"));
        proxy.pauseMandate(mandateId);

        vm.stopPrank();
    }

    function test_MandateExpiration() public {
        vm.startPrank(user);

        uint256 endTime = block.timestamp + 7 days;

        uint256 mandateId = proxy.createMandate(
            spender,
            token,
            10e6,
            100e6,
            1 hours,
            block.timestamp,
            endTime
        );

        vm.warp(endTime + 1);

        (,,,,,,,,,, MandateStorage.MandateStatus retStatus,,) = proxy.getMandate(mandateId);
        assertTrue(retStatus == MandateStorage.MandateStatus.Expired);

        vm.stopPrank();
    }

    function test_RevertWhen_UpdateExpiredMandate() public {
        vm.startPrank(user);

        uint256 endTime = block.timestamp + 7 days;

        uint256 mandateId = proxy.createMandate(
            spender,
            token,
            10e6,
            100e6,
            1 hours,
            block.timestamp,
            endTime
        );

        vm.warp(endTime + 1);

        vm.expectRevert(abi.encodeWithSignature("MandateExpired()"));
        proxy.updateMandateLimits(mandateId, 20e6, 200e6);

        vm.stopPrank();
    }

    function test_RevertWhen_PauseExpiredMandate() public {
        vm.startPrank(user);

        uint256 endTime = block.timestamp + 7 days;

        uint256 mandateId = proxy.createMandate(
            spender,
            token,
            10e6,
            100e6,
            1 hours,
            block.timestamp,
            endTime
        );

        vm.warp(endTime + 1);

        vm.expectRevert(abi.encodeWithSignature("MandateExpired()"));
        proxy.pauseMandate(mandateId);

        vm.stopPrank();
    }

    function test_RevertWhen_GetNonExistentMandate() public {
        vm.expectRevert(abi.encodeWithSignature("MandateNotFound()"));
        proxy.getMandate(999);
    }

    function test_MultipleMandates() public {
        vm.startPrank(user);

        uint256 mandate1 = proxy.createMandate(
            spender,
            token,
            10e6,
            100e6,
            1 hours,
            block.timestamp,
            block.timestamp + 30 days
        );

        uint256 mandate2 = proxy.createMandate(
            address(0x5),
            token,
            20e6,
            200e6,
            2 hours,
            block.timestamp,
            block.timestamp + 60 days
        );

        assertEq(mandate1, 1);
        assertEq(mandate2, 2);

        (address owner1, address spender1,,,,,,,,,,,) = proxy.getMandate(mandate1);
        (address owner2, address spender2,,,,,,,,,,,) = proxy.getMandate(mandate2);

        assertEq(owner1, user);
        assertEq(owner2, user);
        assertEq(spender1, spender);
        assertEq(spender2, address(0x5));

        vm.stopPrank();
    }

    function testFuzz_CreateMandate(
        uint256 perChargeLimit,
        uint256 totalLimit,
        uint256 cooldownSeconds,
        uint256 duration
    ) public {
        vm.assume(perChargeLimit > 0 && perChargeLimit < type(uint128).max);
        vm.assume(totalLimit >= perChargeLimit && totalLimit < type(uint128).max);
        vm.assume(cooldownSeconds < 365 days);
        vm.assume(duration > 0 && duration < 365 days);

        vm.startPrank(user);

        uint256 mandateId = proxy.createMandate(
            spender,
            token,
            perChargeLimit,
            totalLimit,
            cooldownSeconds,
            block.timestamp,
            block.timestamp + duration
        );

        (,,, uint256 retPerCharge, uint256 retTotal, uint256 retSpent,,,,,,,) = proxy.getMandate(mandateId);

        assertEq(retPerCharge, perChargeLimit);
        assertEq(retTotal, totalLimit);
        assertEq(retSpent, 0);

        vm.stopPrank();
    }
}
