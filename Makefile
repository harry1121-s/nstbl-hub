# Build and test

profile ?=default

build:
	@FOUNDRY_PROFILE=production forge build

test:
	forge test

testEqLogic:
	forge test --match-path ./tests/unit/eqLogic.t.sol -vvvvv --via-ir

testHub:
	forge test --match-path ./tests/unit/NSTBLHub.t.sol -vvvvv --via-ir

debug: 
	forge test -vvvvv

clean:
	@forge clean