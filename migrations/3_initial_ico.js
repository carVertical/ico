var cVTokenCrowdsale = artifacts.require('./cVTokenCrowdsale.sol');
var cVToken = artifacts.require('./cVToken.sol');

const wallet = '0x72fee04528dff07c9b2a702DEb45B0B91636cD76';
const period = 100;  // 100 days
// const startTime = 1514311200;  // 12/26/2017 @ 6:00pm (UTC)
const startTime = 1513585566;

module.exports = function(deployer) {
  deployer.deploy(cVToken).then(function() {
    return deployer.deploy(
      cVTokenCrowdsale,
      startTime,
      1,
      wallet,
      cVToken.address
    );
  });
};
