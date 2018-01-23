var cVTokenCrowdsale = artifacts.require('./cVTokenCrowdsale.sol');
var cVToken = artifacts.require('./cVToken.sol');

const wallet = '0xe5fc65B4943c548622e98B43E19E596Fc0adA34A';  // Real collection wallet
const token = '0xdA6cb58A0D0C01610a29c5A65c303e13e885887C';
const period = 100;  // 100 days
const startTime = 1514329200;  // 12/26/2017 @ 11:00pm (UTC)

module.exports = function(deployer) {

  if (deployer.network == 'development') {
    return deployer.deploy(cVToken).then(() => deployer.deploy(
      cVTokenCrowdsale,
      startTime,
      period,
      wallet,
      cVToken.address,
      true
    ));
  } else {
    return deployer.deploy(
      cVTokenCrowdsale,
      startTime,
      period,
      wallet,
      token,
      false
    );
  }

};
