const LedgerState = artifacts.require("LedgerState");
const ManagementCommittee = artifacts.require("ManagementCommittee");
const truffleAssert = require('truffle-assertions');

contract('LedgerState', (accounts) => {
  const fixAccs = [accounts[0], accounts[1], accounts[2]];
  const fixPks = ["akjsdf90asdfafdakfja09dfa", "asdfjasd90f8asdjfasjdfiaj", "asdfjasd90f8asdjfasjdfiaj"];
  let lsInstance, mcInstance;

  before(async function () {
    lsInstance = await LedgerState.deployed();
    const mcInstanceAdd = await lsInstance.committee.call();
    mcInstance = await ManagementCommittee.at(mcInstanceAdd);
    await mcInstance.setCommittee(fixPks, fixAccs);
  });

  it('should assign the admin to the initiator of the contract', async () => {
    const admin = await lsInstance.admin.call();
    assert.equal(admin.valueOf(), accounts[0], "Admin account does not match expected");
  });

  it('should set the policy correctly', async () => {
    const updateTx = await lsInstance.setPolicy(10);
    const quorum = (await lsInstance.getPolicy.call()).toNumber();

    assert.equal(quorum.valueOf(), 10, "The voting quorum policy was not configured correctly");
    // ensure the relevant event was emitted
    truffleAssert.eventEmitted(updateTx, 'PolicyUpdated');
  });

  it('should not allow posting of a commitment by non-committee members', async () => {
    const fixComm = toBytes("some commitment");
    const fixSign = toBytes("some signatuer");
    const fixHeight = 9;

    await truffleAssert.reverts(lsInstance.postCommitment(fixComm, fixSign, fixHeight, { from: accounts[4] }));
  });

  it('should post a candidate commitment correctly', async () => {
    const fixComm = toBytes("some commitment");
    const fixSign = toBytes("some signatuer");
    const fixHeight = 1;

    const updateTx = await lsInstance.postCommitment(fixComm, fixSign, fixHeight);
    const candAcc = await lsInstance.getCandidateCommitment.call();

    expect(candAcc[0], "stored candidate commitment does not match expected").to.have.string(fixComm);
    expect(candAcc[1].toNumber(), "stored candidate height does not match expected").to.equal(fixHeight);
    expect(candAcc[2].toNumber(), "stored candidate votes does not match expected").to.equal(1);

    // ensure the relevant event was emitted
    truffleAssert.eventEmitted(updateTx, 'CommitmentProposed');
    truffleAssert.eventEmitted(updateTx, 'VoteReceived');
  });

  it('should handle votes on a candidate commitment correctly', async () => {
    const fixComm = toBytes("some commitment");
    const fixSign = toBytes("some signatuer");
    const fixHeight = 2;

    await lsInstance.setPolicy(5);

    const updateTx1 = await lsInstance.postCommitment(fixComm, fixSign, fixHeight);
    const updateTx2 = await lsInstance.postCommitment(fixComm, fixSign, fixHeight, { from: accounts[1] });
    const updateTx3 = await lsInstance.postCommitment(fixComm, fixSign, fixHeight, { from: accounts[2] });
    const candAcc = await lsInstance.getCandidateCommitment.call();

    expect(candAcc[0], "stored candidate commitment does not match expected").to.have.string(fixComm);
    expect(candAcc[1].toNumber(), "stored candidate height does not match expected").to.equal(fixHeight);
    expect(candAcc[2].toNumber(), "stored candidate votes does not match expected").to.equal(3);

    truffleAssert.eventEmitted(updateTx1, 'VoteReceived');
    truffleAssert.eventEmitted(updateTx2, 'VoteReceived');
    truffleAssert.eventEmitted(updateTx3, 'VoteReceived');
  });

  it('should ratify a candidate commitment if enough votes are received', async () => {
    const fixComm = toBytes("some commitment");
    const fixSign = toBytes("some signatuer");
    const fixHeight = 3;

    await lsInstance.setPolicy(3);

    await lsInstance.postCommitment(fixComm, fixSign, fixHeight);
    await lsInstance.postCommitment(fixComm, fixSign, fixHeight, { from: accounts[1] });
    const lastVote = await lsInstance.postCommitment(fixComm, fixSign, fixHeight, { from: accounts[2] });

    truffleAssert.eventEmitted(lastVote, 'CommitmentRatified');

    const currentCommit = await lsInstance.getCommitment();
    expect(currentCommit[0], "current state commitment was not replaced with ratified candidate").to.have.string(fixComm);
    expect(currentCommit[2].toNumber(), "current commitment height does not match expected").to.equal(fixHeight);

    // TODO:
    // 1. check current accumulator value
    // 2. check failure scenarios
  });

  it('should detect conflicting commitment during voting', async () => {
    const fixComm = toBytes("some commitment");
    const fixBadComm = toBytes("some other commitment");
    const fixSign = toBytes("some signatuer");
    const fixHeight = 4;

    const lsInstance = await LedgerState.deployed();
    await lsInstance.setPolicy(3);

    await lsInstance.postCommitment(fixComm, fixSign, fixHeight)
    const badCommit = await lsInstance.postCommitment(fixBadComm, fixSign, fixHeight)
    truffleAssert.eventEmitted(badCommit, 'CommitmentConflictDetected');
  });

  it('should handle reporting of conflicts correctly', async () => {
    const fixComm = toBytes("some commitment");
    const fixBadComm = toBytes("some other commitment");
    const fixSign = toBytes("some signatuer");
    const fixHeight = 5;

    await lsInstance.setPolicy(3);

    await lsInstance.postCommitment(fixComm, fixSign, fixHeight)
    const conflictReport = await lsInstance.reportConflictingCommitment(fixHeight, fixBadComm, fixSign)
    truffleAssert.eventEmitted(conflictReport, 'CommitmentConflictDetected');
  });

});

function toBytes(str) {
  return web3.utils.asciiToHex(str)
}