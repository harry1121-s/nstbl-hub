# Build and test

profile ?=default

build:
	@FOUNDRY_PROFILE=production forge build

test:
	forge test

testEqLogic:
	forge test --match-path ./tests/NstblHubMock/unit/eqLogic.t.sol -vvvvv --via-ir

testHubMock:
	forge test --match-path ./tests/NstblHubMock/unit/NSTBLHubMock.t.sol -vvvvv --via-ir

testHub:
	forge test --match-path ./tests/NstblHub/unit/NSTBLHub.t.sol -vvvvv --via-ir

debug: 
	forge test -vvvvv

clean:
	@forge clean