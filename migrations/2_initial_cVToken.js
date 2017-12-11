var cVToken = artifacts.require('./cVToken.sol');
var cVEarlyBirdsCrowdsale = artifacts.require('./cVEarlyBirdsCrowdsale.sol');

const wallet = '0x2FeD59e4618043580158b5B2038ebc8777E393e7';  // Collection Wallet
const rate = 4200;

module.exports = function(deployer) {
  deployer.deploy(cVToken).then(function() {
    return deployer.deploy(cVEarlyBirdsCrowdsale, rate, wallet, cVToken.address);
  });
};
