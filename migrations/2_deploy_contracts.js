const c = artifacts.require("UpstandContract");

module.exports = function (deployer) {
  deployer.deploy(c);
};
