install:
	@mkdir modules && \
	cd modules && \
	git submodule add https://github.com/foundry-rs/forge-std.git && \
	git submodule add https://github.com/OpenZeppelin/openzeppelin-contracts.git && \
	git submodule add https://github.com/LayerZero-Labs/solidity-examples.git && \
	git submodule add https://github.com/smartcontractkit/chainlink.git && \
	git submodule add https://github.com/nealthy-labs/nSTBL_V1_ACLManager.git && \
	git submodule add https://github.com/nealthy-labs/nSTBL_V1_LoanManager.git && \
	git submodule add https://github.com/nealthy-labs/nSTBL_V1_nSTBLToken.git && \
	git submodule add https://github.com/nealthy-labs/nSTBL_V1_StakePool.git && \
	cd ..

update:
	cd modules && \
	git submodule update --remote --recursive nSTBL_V1_ACLManager nSTBL_V1_LoanManager nSTBL_V1_nSTBLToken nSTBL_V1_StakePool && \
	cd ..

build:
	@forge build --sizes

test:
	forge test

testHub:
	forge test --match-path ./tests/NstblHub/unit/NSTBLHub.t.sol -vvv --gas-report 

debug: 
	forge test -vvvvv

clean:
	@forge clean && \
	rm -rf coverage && \
	rm lcov.info

git:
	@git add .
	git commit -m "$m"
	git push

coverage:
	@forge coverage --report lcov && genhtml lcov.info --branch-coverage --output-dir coverage

slither:
	@solc-select use 0.8.21 && \
	slither . 

.PHONY: install build test debug clean git coverage slither