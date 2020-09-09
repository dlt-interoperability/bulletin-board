const LedgerState = artifacts.require("LedgerState");
const truffleAssert = require('truffle-assertions');

contract('LedgerState', (accounts) => {
  const fixAccs = [accounts[0], accounts[1], accounts[2]];
  const fixPks = ["akjsdf90asdfafdakfja09dfa", "asdfjasd90f8asdjfasjdfiaj", "asdfjasd90f8asdjfasjdfiaj"];

  it('should assign the admin to the initiator of the contract', async () => {
    const lsInstance = await LedgerState.deployed();
    const admin = await lsInstance.getAdmin.call();

    assert.equal(admin.valueOf(), accounts[0], "Admin account does not match expected");
  });

  it('should set the policy correctly', async () => {
    const lsInstance = await LedgerState.deployed();
    await lsInstance.setPolicy(10);
    const quorum = (await lsInstance.getPolicy.call()).toNumber();

    assert.equal(quorum.valueOf(), 10, "The voting quorum policy was not configured correctly");

    // TODO:
    // 1. check failure scenarios (only admin can set policy, quorum is being set to 0)
    // 2. check that a corresponding event was emited
  });

  it('should assign the management committee correctly', async () => {
    const lsInstance = await LedgerState.deployed();
    await lsInstance.setManagementCommittee(fixAccs, fixPks);
    const res = await lsInstance.getManagementCommittee.call();

    expect(res[0], "stored addresses for the committee did not match expected").to.eql(fixAccs)
    expect(res[1], "stored DLT public keys for the committee did not match expected").to.eql(fixPks)

    // TODO:
    // 1. check failure scenarios (only admin can set committee, address and public key array size doesn't match)
    // 3. ensure that an event is thrown when the committee is changed
  });

  it('should post a candidate committment correctly', async () => {
    const fixComm = toBytes("some committment");
    const fixSign = toBytes("some signatuer");
    const fixHeight = 1;

    const lsInstance = await LedgerState.deployed();
    await lsInstance.setManagementCommittee(fixAccs, fixPks);

    await lsInstance.postCommittment(fixComm, fixSign, fixHeight);
    const candAcc = await lsInstance.getCandidateCommittment.call();

    expect(candAcc[0], "stored candidate committment does not match expected").to.have.string(fixComm);
    expect(candAcc[1].toNumber(), "stored candidate height does not match expected").to.equal(fixHeight);
    expect(candAcc[2].toNumber(), "stored candidate votes does not match expected").to.equal(1);

    // TODO:
    // 1. check failure scenarios (non-committee member invoking, quorum not set, committee not set, old snapshot acc being proposed)
    // 2. check relevant event is emitted
  });

  it('should handle votes on a candidate committment correctly', async () => {
    const fixComm = toBytes("some committment");
    const fixSign = toBytes("some signatuer");
    const fixHeight = 2;

    const lsInstance = await LedgerState.deployed();
    await lsInstance.setManagementCommittee(fixAccs, fixPks);
    await lsInstance.setPolicy(5);

    await lsInstance.postCommittment(fixComm, fixSign, fixHeight);
    await lsInstance.postCommittment(fixComm, fixSign, fixHeight, { from: accounts[1] });
    await lsInstance.postCommittment(fixComm, fixSign, fixHeight, { from: accounts[2] });
    const candAcc = await lsInstance.getCandidateCommittment.call();

    expect(candAcc[0], "stored candidate committment does not match expected").to.have.string(fixComm);
    expect(candAcc[1].toNumber(), "stored candidate height does not match expected").to.equal(fixHeight);
    expect(candAcc[2].toNumber(), "stored candidate votes does not match expected").to.equal(3);

    // TODO:
    // 1. check failure scenarios  
  });
  it('should ratify a candidate committment if enough votes are received', async () => {
    const fixComm = toBytes("some committment");
    const fixSign = toBytes("some signatuer");
    const fixHeight = 3;

    const lsInstance = await LedgerState.deployed();
    await lsInstance.setManagementCommittee(fixAccs, fixPks);
    await lsInstance.setPolicy(3);

    await lsInstance.postCommittment(fixComm, fixSign, fixHeight);
    await lsInstance.postCommittment(fixComm, fixSign, fixHeight, { from: accounts[1] });
    const lastVote = await lsInstance.postCommittment(fixComm, fixSign, fixHeight, { from: accounts[2] });

    truffleAssert.eventEmitted(lastVote, 'CommittmentRatified');

    const currentCommit = await lsInstance.getCommittment();
    expect(currentCommit[0], "current state committment was not replaced with ratified candidate").to.have.string(fixComm);
    expect(currentCommit[1].toNumber(), "current committment height does not match expected").to.equal(fixHeight);

    // TODO:
    // 1. check current accumulator value
    // 2. check failure scenarios  
  });

  it('should detect conflicting committment during voting', async () => {
    const fixComm = toBytes("some committment");
    const fixBadComm = toBytes("some other committment");
    const fixSign = toBytes("some signatuer");
    const fixHeight = 4;

    const lsInstance = await LedgerState.deployed();
    await lsInstance.setManagementCommittee(fixAccs, fixPks);
    await lsInstance.setPolicy(3);

    await lsInstance.postCommittment(fixComm, fixSign, fixHeight)
    const badCommit = await lsInstance.postCommittment(fixBadComm, fixSign, fixHeight)
    truffleAssert.eventEmitted(badCommit, 'CommittmentConflictDetected');
  });

  it('should handle reporting of conflicts correctly', async () => {
    const fixComm = toBytes("some committment");
    const fixBadComm = toBytes("some other committment");
    const fixSign = toBytes("some signatuer");
    const fixHeight = 5;

    const lsInstance = await LedgerState.deployed();
    await lsInstance.setManagementCommittee(fixAccs, fixPks);
    await lsInstance.setPolicy(3);

    await lsInstance.postCommittment(fixComm, fixSign, fixHeight)
    const conflictReport = await lsInstance.reportConflictingCommittment(fixHeight, fixBadComm, fixSign)
    truffleAssert.eventEmitted(conflictReport, 'CommittmentConflictDetected');
  });

});

function fromBytes(bytes) {
  return web3.utils.hexToAscii(str)
}

function toBytes(str) {
  return web3.utils.asciiToHex(str)
}
