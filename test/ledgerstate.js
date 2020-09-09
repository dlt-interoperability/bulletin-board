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
  });

  it('should assign the management committee correctly', async () => {
    // todo if addresses dont match, complain
    // check that the management committee is asigned
    const lsInstance = await LedgerState.deployed();
    const accs = [accounts[1], accounts[2]];
    const pks = ["akjsdf90asdfafdakfja09dfa", "asdfjasd90f8asdjfasjdfiaj"];
    await lsInstance.setManagementCommittee(accs, pks);
    const res = await lsInstance.getManagementCommittee.call();
    expect(res[0], "stored addresses for the committee did not match expected").to.eql(accs)
    expect(res[1], "stored DLT public keys for the committee did not match expected").to.eql(pks)
  });

  it('should create a new candidate accumulator correctly', async () => {
    // todo if addresses dont match, complain
    // check that the management committee is asigned
    // emits the relevant event"""
  });

  it('should accept votes on a candidate accumulator correctly', async () => {
    // todo if addresses dont match, complain
    // check that the management committee is asigned
  });

  it('should ratify a candidate accumulator if enough votes are received', async () => {
    // todo if addresses dont match, complain
    // check that the management committee is asigned
  });

  it('should reject votes on a ratified accumulators', async () => {
    // todo if addresses dont match, complain
    // check that the management committee is asigned
  });

  it('should detect conflicting accumulator votes', async () => {
    // todo if addresses dont match, complain
    // check that the management committee is asigned
  });

  it('should raise conflicts correctly', async () => {
    // todo if addresses dont match, complain
    // check that the management committee is asigned
  });

});

