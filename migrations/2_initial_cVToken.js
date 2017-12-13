var cVToken = artifacts.require('./cVToken.sol');
var cVEarlyBirdsCrowdsale = artifacts.require('./cVEarlyBirdsCrowdsale.sol');

const wallet = '0x4CBE3136377659d854BACC248cc58064fB975e72';  // Collection Wallet
const rate = 240000;

module.exports = function(deployer) {
  deployer.deploy(cVToken).then(function() {
    return deployer.deploy(cVEarlyBirdsCrowdsale, rate, wallet, cVToken.address);
  });
};
