# LoopPay Mandate Specification

## Overview

A **Mandate** in LoopPay is a user-controlled permission that authorizes a specific app or protocol (the "spender") to pull funds from the user's wallet (the "owner") under predefined limits and constraints. Mandates enable secure, transparent, and revocable recurring payments on Base L2.

## Core Guarantees

### For Users (Mandate Owners)

LoopPay Mandates provide the following guarantees to users:

1. **Spending Limits**: No single transaction can exceed `perChargeLimit`, and total cumulative spending cannot exceed `totalLimit`
2. **Time Bounds**: Mandates are only active between `startTime` and `endTime`
3. **Cooldown Protection**: Minimum time of `cooldownSeconds` must elapse between consecutive debits
4. **Revocability**: Users can revoke mandates at any time, immediately stopping all future debits
5. **Pausability**: Users can temporarily pause mandates without revoking them
6. **Limit Adjustments**: Users can reduce or increase limits mid-life (but not below already-spent amounts)
7. **Non-Reentrancy**: All state-changing operations are protected against reentrancy attacks

### For Apps/Protocols (Spenders)

Mandates provide the following guarantees to apps and protocols:

1. **Permission Verification**: On-chain verification that a user has granted specific spending permissions
2. **Predictable Limits**: Clear upper bounds on what can be charged per transaction and in total
3. **Status Visibility**: Transparent mandate status (Active, Paused, Revoked, Expired)
4. **Lifecycle Tracking**: Access to created/updated timestamps and usage history
5. **Token Specification**: Explicit token address for multi-token support

## Mandate Lifecycle

```
┌─────────┐
│ Created │ (status: Active)
└────┬────┘
     │
     ├──→ Pause ──→ Resume ──→ (back to Active)
     │
     ├──→ Revoke ──→ (status: Revoked, permanent)
     │
     └──→ Time Expires ──→ (status: Expired, computed dynamically)
```

### State Transitions

| Current State | Action | New State | Reversible? |
|--------------|--------|-----------|-------------|
| Active | Pause | Paused | Yes (Resume) |
| Paused | Resume | Active | Yes |
| Active/Paused | Revoke | Revoked | No |
| Active | Time Expires | Expired | No |
| Paused | Time Expires | Expired | No |

## Mandate Structure

```solidity
struct Mandate {
    address owner;              // User granting the mandate
    address spender;            // App/protocol authorized to pull funds
    address token;              // ERC-20 token address (e.g., USDC on Base)
    uint256 perChargeLimit;     // Max amount per single debit
    uint256 totalLimit;         // Cumulative spending cap
    uint256 spent;              // Amount already pulled
    uint256 cooldownSeconds;    // Minimum time between debits
    uint256 lastDebitAt;        // Timestamp of last successful pull
    uint256 startTime;          // Mandate activation timestamp
    uint256 endTime;            // Mandate expiration timestamp
    MandateStatus status;       // Current status (Active/Paused/Revoked/Expired)
    uint256 createdAt;          // Creation timestamp
    uint256 updatedAt;          // Last modification timestamp
}
```

## Key Operations

### Create Mandate

```solidity
function createMandate(
    address spender,
    address token,
    uint256 perChargeLimit,
    uint256 totalLimit,
    uint256 cooldownSeconds,
    uint256 startTime,
    uint256 endTime
) external returns (uint256 mandateId)
```

**Requirements**:
- `msg.sender` (owner) and `spender` must be non-zero and different
- `token` must be non-zero
- `perChargeLimit > 0` and `totalLimit > 0`
- `perChargeLimit <= totalLimit`
- `startTime < endTime`
- If `startTime` is in the past, it is automatically adjusted to `block.timestamp`

### Update Limits

```solidity
function updateMandateLimits(
    uint256 mandateId,
    uint256 newPerChargeLimit,
    uint256 newTotalLimit
) external
```

**Requirements**:
- Only the mandate owner can update limits
- Mandate must not be revoked or expired
- `newPerChargeLimit <= newTotalLimit`
- `newTotalLimit >= spent` (cannot reduce total limit below already-spent amount)

### Pause/Resume

```solidity
function pauseMandate(uint256 mandateId) external
function resumeMandate(uint256 mandateId) external
```

**Requirements**:
- Only the mandate owner can pause/resume
- Cannot pause a revoked or expired mandate
- Cannot pause an already-paused mandate
- Cannot resume an already-active mandate

### Revoke

```solidity
function revokeMandate(uint256 mandateId) external
```

**Requirements**:
- Only the mandate owner can revoke
- Cannot revoke an already-revoked mandate
- Revocation is permanent and irreversible

### Query Mandate

```solidity
function getMandate(uint256 mandateId) external view returns (...)
```

Returns all mandate details. The `status` field is computed dynamically:
- If `block.timestamp > endTime` and status is not Revoked, returns `Expired`
- Otherwise, returns the stored status

## Security Properties

### Access Control

- **Owner-Only Operations**: `updateMandateLimits`, `pauseMandate`, `resumeMandate`, `revokeMandate` can only be called by the mandate owner
- **Admin-Only Operations**: UUPS upgrade authorization restricted to contract owner
- **Public Read Access**: `getMandate` is publicly accessible for transparency

### Reentrancy Protection

All state-changing functions (`createMandate`, `updateMandateLimits`, `revokeMandate`, `pauseMandate`, `resumeMandate`) are protected by OpenZeppelin's `ReentrancyGuardUpgradeable`.

### Storage Safety

- Uses `__gap` storage slots to allow for future upgrades without storage collisions
- UUPS proxy pattern ensures implementation logic can be upgraded while preserving state

## Example Use Cases

### Monthly Subscription

```solidity
// User grants SubscriptionService permission to charge $10 USDC monthly
createMandate({
    spender: subscriptionServiceAddress,
    token: USDC_BASE_MAINNET,  // 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
    perChargeLimit: 10e6,       // $10 USDC (6 decimals)
    totalLimit: 120e6,          // $120 total (12 months)
    cooldownSeconds: 28 days,   // Minimum 28 days between charges
    startTime: block.timestamp,
    endTime: block.timestamp + 365 days
});
```

### Usage-Based Billing

```solidity
// User grants CloudService permission for flexible usage charges
createMandate({
    spender: cloudServiceAddress,
    token: USDC_BASE_MAINNET,
    perChargeLimit: 50e6,       // Max $50 per charge
    totalLimit: 500e6,          // $500 total budget
    cooldownSeconds: 1 hours,   // Can charge hourly
    startTime: block.timestamp,
    endTime: block.timestamp + 90 days
});
```

### One-Time Multi-Payment

```solidity
// User grants Escrow permission for 3 milestone payments
createMandate({
    spender: escrowAddress,
    token: USDC_BASE_MAINNET,
    perChargeLimit: 1000e6,     // $1000 per milestone
    totalLimit: 3000e6,         // $3000 total (3 milestones)
    cooldownSeconds: 7 days,    // Minimum 7 days between milestones
    startTime: block.timestamp,
    endTime: block.timestamp + 180 days
});
```

## Integration Guide

### For App Developers

1. **User Authorization Flow**:
   - Present user with clear mandate parameters (limits, duration, cooldown)
   - User calls `createMandate()` from their wallet
   - Store `mandateId` in your backend for future reference

2. **Executing Charges** (future functionality in Block 2):
   - Verify mandate is active: `getMandate(mandateId)` returns status == Active
   - Check spending limits: `spent + chargeAmount <= totalLimit`
   - Check cooldown: `block.timestamp >= lastDebitAt + cooldownSeconds`
   - Execute debit transaction

3. **Handling Edge Cases**:
   - Always check mandate status before attempting a charge
   - Handle `MandateExpired`, `MandatePaused`, `MandateRevoked` errors gracefully
   - Notify users when mandates are approaching limits or expiration

### For Frontend Integrations

1. **Display Mandate Details**:
   ```javascript
   const mandate = await contract.getMandate(mandateId);
   const remaining = mandate.totalLimit - mandate.spent;
   const daysLeft = (mandate.endTime - Date.now() / 1000) / 86400;
   ```

2. **User Controls**:
   - Provide UI for pausing/resuming mandates
   - Show revoke button with clear warning about irreversibility
   - Display usage history and remaining limits

3. **Status Indicators**:
   - Active: Green indicator, show next charge availability
   - Paused: Yellow indicator, offer resume action
   - Expired/Revoked: Gray indicator, mark as inactive

## Gas Optimization Notes

- Mandate data is stored in a single `mapping(uint256 => Mandate)` for efficient lookup
- Status computation for expiration is done in view functions (no gas cost)
- Uses `via_ir` compilation for stack depth optimization
- Events emitted for all state changes to enable efficient off-chain indexing

## Upgrade Path

The MandateV1 contract uses the UUPS (Universal Upgradeable Proxy Standard) pattern:

- Implementation can be upgraded by contract owner
- Storage layout preserved via `__gap` arrays
- All upgrades must maintain backward compatibility with existing mandate data

## Network Support

**Base Sepolia (Testnet)**: Chain ID 84532
**Base Mainnet**: Chain ID 8453

Mandates are designed specifically for Base L2, leveraging low gas costs and fast finality for optimal recurring payment experiences.

## Compliance & Safety

- **User Sovereignty**: Users retain full control over their mandates
- **Transparent Limits**: All constraints are enforced on-chain and publicly auditable
- **Immutable History**: All mandate actions emit events for permanent record
- **No Custody**: LoopPay mandates are permission layers only; no funds are held in escrow
