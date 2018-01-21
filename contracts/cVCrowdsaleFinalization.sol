pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

import "./cVFinalizationWallets.sol";
import "./cVToken.sol";

contract cVCrowdsaleFinalization is Ownable, cVFinalizationWallets {
  using SafeMath for uint256;

  cVToken public token;

  function tokenSetup() public onlyOwner {
    address tokenAddress = 0xdA6cb58A0D0C01610a29c5A65c303e13e885887C;
    token = cVToken(tokenAddress);
  }

  function distributeTokens() public onlyOwner {
    uint256 maxSupply = token.supplyLimit();

    uint256 planedToSellTokens = maxSupply.mul(43).div(100);
    uint256 soldFromEarlyBirds = token.totalSupply().sub(planedToSellTokens);
    uint256 earlyBirdsPool = maxSupply.mul(23).div(100);

    mint(earlyBirdsWallet, earlyBirdsPool.sub(soldFromEarlyBirds));

    // total 12% for team
    mintAndLock(teamYear1, maxSupply.mul(3).div(100), 1);
    mintAndLock(teamYear2, maxSupply.mul(3).div(100), 2);
    mintAndLock(teamYear3, maxSupply.mul(3).div(100), 3);
    mintAndLock(teamYear4, maxSupply.mul(3).div(100), 4);

    // total 10% for founders
    mintAndLock(foundersYear1, maxSupply.mul(25).div(1000), 1);
    mintAndLock(foundersYear2, maxSupply.mul(25).div(1000), 2);
    mintAndLock(foundersYear3, maxSupply.mul(25).div(1000), 3);
    mintAndLock(foundersYear4, maxSupply.mul(25).div(1000), 4);

    mint(teamICOBonusWallet, maxSupply.mul(11).div(100));
    mint(specialMintWallet, maxSupply.mul(1).div(100));

    mint(earlyBirdsWallet, maxSupply.sub(token.totalSupply()));
  }

  function mint(
    address _beneficiary,
    uint256 _tokens
  ) private {
    token.mint(_beneficiary, _tokens);
  }

  function mintAndLock(
    address _beneficiary,
    uint256 _tokens,
    uint8 _lockForYears
  ) private {
    uint yearInSeconds = 31536000;

    token.lockTill(_beneficiary, now + yearInSeconds * _lockForYears);
    token.mint(_beneficiary, _tokens);
  }

  /** Allows the current owner to transfer control of the contracts token to a newOwner
   * @param _newOwner The address to transfer ownership to
   */
  function transferTokenOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));

    token.transferOwnership(_newOwner);
  }

  function transferTokenToMaster() public {
    address master = 0x4CBE3136377659d854BACC248cc58064fB975e72;
    token.transferOwnership(master);
  }

  function makeTokenTransferable() public onlyOwner {
    token.changeTransferLock(false);
    token.finishMinting();
    token.transferOwnership(token);
  }

}
