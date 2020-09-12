const ManagementCommittee = artifacts.require("ManagementCommittee");
const truffleAssert = require('truffle-assertions');

contract('ManagementCommittee', (accounts) => {
  const fixAccs = [accounts[0], accounts[1], accounts[2]];
  const fixPks = ["akjsdf90asdfafdakfja09dfa", "asdfjasd90f8asdjfasjdfiaj", "asdfjasd90f8asdjfasjdfiaj"];
  let mcInstance;

  before(async function () {
    mcInstance = await ManagementCommittee.new(accounts[0]);
  });

  it('should assign the admin to the initiator of the contract', async () => {
    const admin = await mcInstance.admin.call();
    assert.equal(admin.valueOf(), accounts[0], "Admin account does not match expected");
  });

  it('should only allow an admin to update the management committee correctly', async () => {
    await truffleAssert.reverts(mcInstance.setCommittee(fixPks, fixAccs, { from: accounts[1] }));
  });

  it('should be equal number of addresses and DLT public keys provided', async () => {
    await truffleAssert.reverts(mcInstance.setCommittee(fixPks, [accounts[1]]));
  });

  it('should assign the management committee correctly', async () => {
    const updateTx = await mcInstance.setCommittee(fixPks, fixAccs);
    const committee = await mcInstance.getCommittee.call();

    expect(committee[0], "stored addresses for the committee did not match expected").to.eql(fixAccs)
    expect(committee[1], "stored DLT public keys for the committee did not match expected").to.eql(fixPks)

    // ensure the relevant event was emitted
    truffleAssert.eventEmitted(updateTx, 'ManagmentCommitteeUpdated');
  });
});
