var cVToken = artifacts.require('./cVToken.sol');
var cVEarlyBirdsCrowdsale = artifacts.require('./cVEarlyBirdsCrowdsale.sol');

const wallet = '0xB34fF5F0db23Ab946fa846140Af824190230dEA3';  // Collection Wallet
const rate = 4200;

module.exports = function(deployer) {
  deployer.deploy(cVToken).then(function() {
    return deployer.deploy(cVEarlyBirdsCrowdsale, rate, wallet, cVToken.address);
  });
};
