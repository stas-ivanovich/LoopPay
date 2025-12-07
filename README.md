# LoopPay

Recurring billing and auto-debit engine for Base network. LoopPay enables merchants to set up automated USDC payment loops with user-approved mandates and strict on-chain safety controls.

## Overview

LoopPay is a direct-debit style system where payers grant reusable on-chain mandates with limits, and the protocol issues recurring invoices and executes charges automatically as long as the mandate remains valid and within constraints.

**Key Concepts:**
- **Loop Templates** - Recurring billing configurations (frequency, amount, merchant)
- **Mandates** - User-approved permissions with spending limits and expiry
- **Invoices** - On-chain payment records (optionally minted as NFTs)
- **Auto-debit** - Automated USDC charges via Base Pay integration

## Use Cases

### SaaS & Subscriptions
Set up monthly or weekly recurring payments for subscription services with automatic USDC billing.

### Membership Programs
Create daily, weekly, or custom-interval payments for tiered membership access with on-chain proof of payment.

### Payroll & Recurring Payouts
Automate recurring payouts to contractors or employees with transparent on-chain records.

### DeFi Protocols
Enable recurring deposits, staking rewards distribution, or automated DCA (Dollar Cost Averaging) strategies.

## Features

- **Multi-interval Support** - Daily, weekly, monthly recurring payments
- **Upgradeable Architecture** - UUPS proxy pattern for safe contract upgrades
- **Lifecycle Management** - Pause, resume, and cancel payment loops
- **Safety Controls** - Per-mandate limits, expiration dates, and revocation
- **NFT Invoices** - Optional on-chain invoice receipts as ERC-721 tokens
- **Base Network Native** - Optimized for Base L2 with low fees and fast finality

## Smart Contracts

### MandateV1
User-controlled permission system for granting time-limited, revocable payment authorizations to apps and protocols. Built with UUPS upgradeability and comprehensive safety controls.

**Key Functions:**
- `createMandate(spender, token, perChargeLimit, totalLimit, cooldownSeconds, startTime, endTime)` - Grant payment permission with limits
- `getMandate(mandateId)` - Query mandate details and status
- `updateMandateLimits(mandateId, newPerChargeLimit, newTotalLimit)` - Adjust spending limits mid-life
- `pauseMandate(mandateId)` / `resumeMandate(mandateId)` - Temporarily suspend permissions
- `revokeMandate(mandateId)` - Permanently cancel a mandate

**Mandate Properties:**
- Per-charge and total spending limits
- Cooldown period between debits
- Start/end time bounds
- Dynamic status (Active, Paused, Revoked, Expired)
- Non-reentrancy protection
- Owner-only access control

[📖 Full Mandate Specification →](docs/MANDATE_SPEC.md)

### LoopTemplateV1
Core billing loop contract with UUPS upgradeability. Defines recurring payment schedules with merchant, amount, and period configuration.

**Key Functions:**
- `createLoopTemplate(merchant, baseAmount, periodSeconds, metadataRef)` - Define a new billing loop
- `getLoopTemplate(templateId)` - Retrieve loop configuration
- `pauseLoop(templateId)` / `resumeLoop(templateId)` - Control loop state

### PaymentLoop (Legacy)
Original payment loop implementation with executor role model and USDC integration.

### PaymentInvoiceNFT
ERC-721 contract for minting payment receipts as NFTs. Each invoice contains loop ID, amount, timestamp, payer, and recipient data.

## Deployment

### Automated Deployment via GitHub Actions

1. **Configure GitHub Secrets** at `Settings > Secrets and variables > Actions`:
   - `PRIVATE_KEY` - Deployer wallet private key
   - `BASESCAN_API_KEY` - BaseScan API key for verification
   - `BASE_SEPOLIA_RPC_URL` - (Optional) Base Sepolia RPC (default: https://sepolia.base.org)
   - `BASE_RPC_URL` - (Optional) Base Mainnet RPC (default: https://mainnet.base.org)

2. **Run Deployment**:
   - Go to Actions → Deploy workflow
   - Select network: `base_sepolia` (testnet) or `base` (mainnet)
   - Click "Run workflow"

Deployment automatically verifies contracts on BaseScan and commits addresses to `deployments/<network>.json`.

### Network Deployments

**Base Mainnet (Chain ID: 8453)**
- Deployment pending

**Base Sepolia (Chain ID: 84532)**
- Deployment pending

## Integration Examples

### Creating a Mandate

```solidity
// User grants a subscription service permission to charge monthly
uint256 mandateId = mandate.createMandate({
    spender: subscriptionServiceAddress,
    token: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913,  // USDC on Base Mainnet
    perChargeLimit: 10e6,        // $10 USDC max per charge
    totalLimit: 120e6,           // $120 total budget (12 months)
    cooldownSeconds: 28 days,    // Minimum 28 days between charges
    startTime: block.timestamp,
    endTime: block.timestamp + 365 days
});
```

### Managing Mandates

```solidity
// Check mandate status
(address owner, address spender,, uint256 perCharge, uint256 total,
 uint256 spent,,,,,, MandateStatus status,,) = mandate.getMandate(mandateId);

// Pause temporarily
mandate.pauseMandate(mandateId);

// Resume later
mandate.resumeMandate(mandateId);

// Adjust limits
mandate.updateMandateLimits(mandateId, 15e6, 180e6);

// Revoke permanently
mandate.revokeMandate(mandateId);
```

### Creating a Loop Template

```solidity
// Merchant creates a monthly subscription loop
uint256 templateId = loopTemplate.createLoopTemplate(
    merchantAddress,
    100e6,  // 100 USDC
    30 days,
    "ipfs://subscription-metadata"
);

// Retrieve loop details
(address merchant, uint256 amount, uint256 period,,,) =
    loopTemplate.getLoopTemplate(templateId);
```

## Security

This protocol is in active development. Smart contracts have not been audited. Use at your own risk.

**Safety Features:**
- Owner-controlled loop creation
- Pausable functionality for emergency stops
- Upgradeable contracts for critical fixes
- Custom error types for clear failure modes

## License

MIT License
