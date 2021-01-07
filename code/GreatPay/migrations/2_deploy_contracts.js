const GreatPay = artifacts.require("GreatPay");

module.exports = function(deployer) {
  deployer.deploy(GreatPay, '0xA2C0D48fc58d166A3a3fE357F98c145C6BefeE65', 60, web3.utils.toWei('1', 'ether'));
};
