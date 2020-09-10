# Ethereum Bulletin Board

The bulletin board is an Ethereum smart contract responsible for managing state commitments coming from a permissioned network. It has two elements:

- **Management Committee**: Which represent the set of parties that are a part of the permissioned network and responsible for maintaining its state. The contract maintains a pair of identities for each committee member consisting of their ethereum account address and their permissioned ledger public key. The former is used for access control during smart contract invocation while the latter is used for validing that votes on state commitments are valid.

- **State Commitments**: Which is a commitment of a snapshot of the state of a permissioned ledger at a specific ledger height. The contract is agnostic of the specific scheme employed to generate the commitment (e.g. RSA Accumulator). The contract enforces a lifecycle for how commitments are managed as shown in the diagram below. Essentially, commitments for a ledger height (which is higher than any ledger height currently submitted or ratified) can be nominated by a party and that commitment will only be ratified and activated when a configurable *quorum* of votes from other committee members is received for that committmment. Members can dispute a committment at any stage with a conflicting committment value.

![commitment lifecycle](./docs/commitment-lifecycle.png)

## Setup
### Prerequsites
- [*Truffle*](https://www.trufflesuite.com/): A development and testing framework for Ethereum.

- [*Solc*](https://solidity.readthedocs.io/en/v0.6.4/installing-solidity.html): The solidity compiler.
### Network Configuration and Deployment
Todo: details to be added here

## TODOs

- Signature verification on committment votes
- Handling more failure and edge cases
- More BDD tests
- Refactoring and cleanup (separate committee management to `LedgerCommitee.sol`)
- Basic optimisation of code
