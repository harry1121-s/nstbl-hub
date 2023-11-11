# Build and test

profile ?=default

update:
	cd modules && \
	git submodule update --remote nstbl-acl-manager nstbl-token nstbl-stake-pool nstbl-loan-manager && \
	cd ..
build:
	@FOUNDRY_PROFILE=production forge build

test:
	forge test

testEqLogic:
	forge test --match-path ./tests/NstblHubMock/unit/eqLogic.t.sol -vvvvv --via-ir

testHubMock:
	forge test --match-path ./tests/NstblHubMock/unit/NSTBLHubMock.t.sol -vvv --gas-report 

testHub:
	forge test --match-path ./tests/NstblHub/unit/NSTBLHub.t.sol -vvvvv --via-ir

debug: 
	forge test -vvvvv

clean:
	@forge clean