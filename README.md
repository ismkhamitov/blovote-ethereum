# blovote-ethereum

Implementation of Ethereum smart-contracts for Blovote application.

## Project structure 

Project uses [Truffle structure](http://truffleframework.com/docs/getting_started/project). 
If you do not have Truffle installed on your computer simply run:
* `npm install -g truffle`

Corresponding Truffle commands are executable from root directory: 
* `truffle compile` - project compilation
* `truffle test` - running tests from `test/` directory


## Test running

For test running: 
* Ethereum node is needed (e.g. [Ganache](http://truffleframework.com/ganache/))
* check connection config in `truffle.js` file

## Smart-contracts wrappers on Java

For smart-contracts compiling to `*.bin` and `*.abi` files `solc` tool is needed: 
* `npm install -g solc` (command-line tool is named `solcjs`)

For wrapping with Java-classes [web3j](https://web3j.io/) is needed:
* `brew tap web3j/web3j`
* `brew install web3j`

Script for compiling contracts and wrapping them is implemented and can be called from root directory through command:
* `./compile` (change script according to yours OS if OS X is not used)
