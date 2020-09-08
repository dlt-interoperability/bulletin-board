const ConvertLib = artifacts.require("StringUtils");
const MetaCoin = artifacts.require("LedgerState");

module.exports = function(deployer) {
  deployer.deploy(StringUtils);
  deployer.link(StringUtils, LedgerState);
  deployer.deploy(LedgerState);
};
