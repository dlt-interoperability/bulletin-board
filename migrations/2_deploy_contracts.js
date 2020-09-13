const StringUtils = artifacts.require("StringUtils");
const LedgerState = artifacts.require("LedgerState");

module.exports = function (deployer) {
  deployer.deploy(StringUtils);
  deployer.deploy(LedgerState);
};
