# nstbl-hub

Tasks for Today: 18-OCT
1. Add staking to the same repo (done)
2. Complete internal functions : (done)
3. rewrite UA functions (decouple staking and redemption) (done)
4. Chainlink: 1 function to return all prices (done)
5. Add dynamic adjustment of dt, ub, lb (to be called before UA function)
6. (!!Important): Test cases for staker redemption (1asset failing, 2, 3 + variation of stable balances) (done: fuzz pending)
7. Refactor params in redeemUnstake (post testing) (pending)

Tasks (19th Oct)
1. ATVL burning with tests
2. ATVL removing profits 
3. Receive NSTBL into ATVL
4. Setter functions for ATVL params

8200 USDC ; CR(1.025) l=8000
900 USDT : (0.9), l=1000
900 DAI : (0.9), l=1000

eq: 0.225/3 = 0.075

if DAI depegs

8200 USDC ; CR(0.91111) l=9000
900 USDT : (0.9), l=1000
900 DAI : (0.9), l=1000 //not included

neqEq = 0.18889/3 = 0.06296


if DAI depegs (case 2)

8200 USDC ; CR(1.00122) l=8190
900 USDT : (0.989), l=910
900 DAI : (0.9), l=0 //not included

newEq = 0.0122/3 = 0.004066

