# LoopPay

Recurring payment automation system for Base network.

## Features

- USDC-based recurring payments (daily, weekly, monthly)
- Upgradeable smart contracts (UUPS proxy pattern)
- Pause, resume, and cancel payment loops
- Compatible with Base smart wallets and Account abstraction
- On-chain execution verification
- NFT invoice generation for payment receipts
- Factory contract for easy deployment

## Architecture

Built with Foundry and OpenZeppelin's upgradeable contracts for secure and gas-efficient recurring payments on Base L2.

## Getting Started

```bash
forge install
forge test
```

## Deployment

Contracts are deployed via GitHub Actions to Base Mainnet and Sepolia testnet.

## Testing

```bash
make test
make coverage
```

## Scripts

Create a payment loop:
```bash
forge script script/CreateLoop.s.sol --rpc-url base --broadcast
```

Execute a loop:
```bash
forge script script/ExecuteLoop.s.sol --rpc-url base --broadcast
```

## Security

⚠️ This project has not been audited. Use at your own risk.

## License

MIT License - see LICENSE file
