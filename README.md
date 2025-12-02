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

## Network Deployments

**Base Mainnet (Chain ID: 8453)**
- Coming soon

**Base Sepolia (Chain ID: 84532)**
- Coming soon

## Integration Example

```solidity
// Create a monthly subscription loop
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
