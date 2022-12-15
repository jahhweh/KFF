# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```

# KFF

## Deployment Instructions

### Remix
Easiest way is to deploy with Remix (remix.ethereum.org) <br>
make a new file, name it TheProjectsName.sol <br>
copy/paste the KFF.sol contract <br>
compile the contract using compiler version 0.8.9 <br>

### Variables for Deployment
- name = TheProjectsName <br>
- symbol = TPN <br>
- cost = 100000000000000000 <br>
The cost is determined using wei. 1 eth is equal to 1000000000000000000 (1 with 18 zeros) <br>
- max supply = 10001 <br>
- allow minting on = 0 <br>
This sets the mint date using UNIX/EPOCH time
- baseuri = ipfs://CID/ <br> 
This sets the URI to the projects metadata files

### To Do
- test metadata <br>
- test frontend  <br>
- try tracking time nft is in wallet, hodlTime <br>
- try tracking role id <br>
