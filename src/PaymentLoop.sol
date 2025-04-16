// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PaymentLoop is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    enum Interval {
        Daily,
        Weekly,
        Monthly
    }

    enum Status {
        Active,
        Paused,
        Cancelled
    }

    struct Loop {
        address recipient;
        uint256 amount;
        Interval interval;
        uint256 nextExecution;
        Status status;
        uint256 executionCount;
    }

    IERC20 public paymentToken;
    mapping(uint256 => Loop) public loops;
    uint256 public loopCounter;

    event LoopCreated(uint256 indexed loopId, address indexed recipient, uint256 amount, Interval interval);
    event LoopExecuted(uint256 indexed loopId, uint256 amount, uint256 timestamp);
    event LoopUpdated(uint256 indexed loopId, address newRecipient, uint256 newAmount);
    event LoopPaused(uint256 indexed loopId);
    event LoopResumed(uint256 indexed loopId);
    event LoopCancelled(uint256 indexed loopId);

    function initialize(address _paymentToken) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        paymentToken = IERC20(_paymentToken);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function createLoop(
        address _recipient,
        uint256 _amount,
        Interval _interval
    ) external onlyOwner returns (uint256) {
        require(_recipient != address(0), "Invalid recipient");
        require(_amount > 0, "Amount must be positive");

        uint256 loopId = loopCounter++;
        uint256 nextExecution = block.timestamp + _getIntervalSeconds(_interval);

        loops[loopId] = Loop({
            recipient: _recipient,
            amount: _amount,
            interval: _interval,
            nextExecution: nextExecution,
            status: Status.Active,
            executionCount: 0
        });

        emit LoopCreated(loopId, _recipient, _amount, _interval);
        return loopId;
    }

    function executeLoop(uint256 _loopId) external {
        Loop storage loop = loops[_loopId];
        require(loop.status == Status.Active, "Loop not active");
        require(block.timestamp >= loop.nextExecution, "Too early");

        require(
            paymentToken.transferFrom(owner(), loop.recipient, loop.amount),
            "Transfer failed"
        );

        loop.nextExecution = block.timestamp + _getIntervalSeconds(loop.interval);
        loop.executionCount++;

        emit LoopExecuted(_loopId, loop.amount, block.timestamp);
    }

    function pauseLoop(uint256 _loopId) external onlyOwner {
        require(loops[_loopId].status == Status.Active, "Not active");
        loops[_loopId].status = Status.Paused;
        emit LoopPaused(_loopId);
    }

    function resumeLoop(uint256 _loopId) external onlyOwner {
        require(loops[_loopId].status == Status.Paused, "Not paused");
        loops[_loopId].status = Status.Active;
        emit LoopResumed(_loopId);
    }

    function updateLoop(uint256 _loopId, address _newRecipient, uint256 _newAmount) external onlyOwner {
        require(loops[_loopId].status != Status.Cancelled, "Loop cancelled");
        require(_newRecipient != address(0), "Invalid recipient");
        require(_newAmount > 0, "Amount must be positive");

        loops[_loopId].recipient = _newRecipient;
        loops[_loopId].amount = _newAmount;

        emit LoopUpdated(_loopId, _newRecipient, _newAmount);
    }

    function cancelLoop(uint256 _loopId) external onlyOwner {
        require(loops[_loopId].status != Status.Cancelled, "Already cancelled");
        loops[_loopId].status = Status.Cancelled;
        emit LoopCancelled(_loopId);
    }

    function _getIntervalSeconds(Interval _interval) internal pure returns (uint256) {
        if (_interval == Interval.Daily) return 1 days;
        if (_interval == Interval.Weekly) return 7 days;
        if (_interval == Interval.Monthly) return 30 days;
        revert("Invalid interval");
    }
}
