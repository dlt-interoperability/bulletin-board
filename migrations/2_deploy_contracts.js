const StringUtils = artifacts.require("StringUtils");
const LedgerState = artifacts.require("LedgerState");
const ManagementCommittee = artifacts.require("ManagementCommittee");

module.exports = function (deployer) {
  deployer.deploy(StringUtils);
  deployer.deploy(LedgerState);
};
