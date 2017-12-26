var cVTokenCrowdsale = artifacts.require('./cVTokenCrowdsale.sol');
var cVToken = artifacts.require('./cVToken.sol');

const wallet = '0xe5fc65B4943c548622e98B43E19E596Fc0adA34A';  // Real collection wallet
const period = 100;  // 100 days
const startTime = 1514311200;  // 12/26/2017 @ 6:00pm (UTC)

module.exports = function(deployer) {
  deployer.deploy(cVToken).then(function() {
    return deployer.deploy(
      cVTokenCrowdsale,
      startTime,
      period,
      wallet,
      cVToken.address
    );
  });
};
