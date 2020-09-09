const LedgerState = artifacts.require("LedgerState");

contract('LedgerState', (accounts) => {
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
    const fixAccs = [accounts[1], accounts[2]];
    const fixPks = ["akjsdf90asdfafdakfja09dfa", "asdfjasd90f8asdjfasjdfiaj"];

    const lsInstance = await LedgerState.deployed();

    await lsInstance.setManagementCommittee(fixAccs, fixPks);
    const res = await lsInstance.getManagementCommittee.call();

    expect(res[0], "stored addresses for the committee did not match expected").to.eql(fixAccs)
    expect(res[1], "stored DLT public keys for the committee did not match expected").to.eql(fixPks)

    // TODO:
    // 1. check failure scenarios (only admin can set committee, address and public key array size doesn't match)
    // 3. ensure that an event is thrown when the committee is changed
  });

  it('should create a new candidate committment correctly', async () => {
    const fixAccs = [accounts[0]];
    const fixPks = ["akjsdf90asdfafdakfja09dfa"];

    const fixComm = toBytes("some committment");
    const fixSign = toBytes("some signatuer");
    const fixHeight = 1;

    const lsInstance = await LedgerState.deployed();
    await lsInstance.setManagementCommittee(fixAccs, fixPks);

    await lsInstance.postCommittment(fixComm, fixSign, 1);
    const candAcc = await lsInstance.getCandidateCommittment.call();

    expect(candAcc[0], "stored candidate committment does not match expected").to.have.string(fixComm);
    expect(candAcc[1].toNumber(), "stored candidate height does not match expected").to.equal(fixHeight);

    // TODO:
    // 1. check failure scenarios (non-committee member invoking, quorum not set, committee not set, old snapshot acc being proposed)
    // 2. check relevant event is emitted
  });

  it('should accept votes on a existing candidate committment correctly', async () => {
    // todo if addresses dont match, complain
    // check that the management committee is asigned
  });

  it('should ratify a candidate committment if enough votes are received', async () => {
    // todo if addresses dont match, complain
    // check that the management committee is asigned
  });

  it('should reject votes on a ratified committments', async () => {
    // todo if addresses dont match, complain
    // check that the management committee is asigned
  });

  it('should detect conflicting committment votes', async () => {
    // todo if addresses dont match, complain
    // check that the management committee is asigned
  });

  it('should raise conflicts correctly', async () => {
    // todo if addresses dont match, complain
    // check that the management committee is asigned
  });

});

function fromBytes(bytes) {
  return web3.utils.hexToAscii(str)
}

function toBytes(str) {
  return web3.utils.asciiToHex(str)
}