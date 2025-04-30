.PHONY: install test build deploy-testnet deploy-mainnet

install:
	forge install

test:
	forge test -vvv

build:
	forge build

coverage:
	forge coverage

deploy-testnet:
	forge script script/Deploy.s.sol --rpc-url base_sepolia --broadcast --verify

deploy-mainnet:
	forge script script/Deploy.s.sol --rpc-url base --broadcast --verify
