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

  it('should post a candidate commitment correctly', async () => {
    const fixComm = toBytes("some commitment");
    const fixSign = toBytes("some signatuer");
    const fixHeight = 1;

    await lsInstance.postCommitment(fixComm, fixSign, fixHeight);
    const candAcc = await lsInstance.getCandidateCommitment.call();

    expect(candAcc[0], "stored candidate commitment does not match expected").to.have.string(fixComm);
    expect(candAcc[1].toNumber(), "stored candidate height does not match expected").to.equal(fixHeight);
    expect(candAcc[2].toNumber(), "stored candidate votes does not match expected").to.equal(1);

    // TODO:
    // 1. check failure scenarios(non - committee member invoking, quorum not set, committee not set, old snapshot acc being proposed)
    // 2. check relevant event is emitted
  });

  it('should handle votes on a candidate commitment correctly', async () => {
    const fixComm = toBytes("some commitment");
    const fixSign = toBytes("some signatuer");
    const fixHeight = 2;

    await lsInstance.setPolicy(5);

    await lsInstance.postCommitment(fixComm, fixSign, fixHeight);
    await lsInstance.postCommitment(fixComm, fixSign, fixHeight, { from: accounts[1] });
    await lsInstance.postCommitment(fixComm, fixSign, fixHeight, { from: accounts[2] });
    const candAcc = await lsInstance.getCandidateCommitment.call();

    expect(candAcc[0], "stored candidate commitment does not match expected").to.have.string(fixComm);
    expect(candAcc[1].toNumber(), "stored candidate height does not match expected").to.equal(fixHeight);
    expect(candAcc[2].toNumber(), "stored candidate votes does not match expected").to.equal(3);

    // TODO:
    // 1. check failure scenarios
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