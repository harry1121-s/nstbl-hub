# Build and test

profile ?=default

build:
	@FOUNDRY_PROFILE=production forge build

test:
	forge test

testToken:
	forge test --match-path ./tests/unit/Token.t.sol

testHub:
	forge test --match-path ./tests/unit/NSTBLHub.t.sol -vvvvv --via-ir

debug: 
	forge test -vvvvv

clean:
	@forge clean