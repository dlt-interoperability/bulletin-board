const ByteUtils = artifacts.require("ByteUtils");
const LedgerState = artifacts.require("LedgerState");

module.exports = function (deployer) {
  deployer.deploy(ByteUtils);
  deployer.link(ByteUtils, LedgerState);
  deployer.deploy(LedgerState);
};
