# Build and test

profile ?=default

update:
	cd modules && \
	git submodule update --remote --recursive nstbl-acl-manager nstbl-token nstbl-stake-pool nstbl-loan-manager && \
	cd ..
build:
	@FOUNDRY_PROFILE=production forge build

test:
	forge test

testHub:
	forge test --match-path ./tests/NstblHub/unit/NSTBLHub.t.sol -vvv --gas-report 

git:
	@git add .
	git commit -m "$m"
	git push

debug: 
	forge test -vvvvv

coverage:
	@forge coverage --report lcov && genhtml lcov.info --branch-coverage --output-dir coverage

clean:
	@forge clean