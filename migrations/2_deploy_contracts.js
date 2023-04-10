var TronMulticall = artifacts.require("./TronMulticall.sol");

module.exports = function(deployer) {
  deployer.deploy(TronMulticall);
};
