var cVCrowdsaleFinalizationMock = artifacts.require('./cVCrowdsaleFinalizationMock.sol');
var cVCrowdsaleFinalization = artifacts.require('./cVCrowdsaleFinalization.sol');


module.exports = function(deployer) {
  if (deployer.network == 'development') {
    return deployer.deploy(cVCrowdsaleFinalizationMock).then(() => {
      return deployer.deploy(cVCrowdsaleFinalization);
    });
  } else {
    return deployer.deploy(cVCrowdsaleFinalization);
  }
};
