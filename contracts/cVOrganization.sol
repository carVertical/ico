pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/math/SafeMath.sol";

contract cVOrganization {
  using SafeMath for uint256;

  /** Constants
   * ----------
   * kRate - Ether to CVToken rate. 1 ether is 42000 tokens.
   * kMinStake - Min amount of Ether that can be contributed.
   * kMaxStake - Max amount of Ether that can be contributed.
   * kTotalEth - Entire organization value in Ether.
   */
  uint256 public constant kRate = 42000;
  uint256 public constant kMinStake = 0.1 ether;
  uint256 public constant kMaxStake = 2000 ether;
  uint256 public constant kOrgValue = 35000 ether;

  // Organization token distribution
  uint256 internal icoBalance = kOrgValue.mul(43).div(100);
  uint256 internal teamBalance = kOrgValue.mul(14).div(100);
  uint256 internal foundersBalance = kOrgValue.mul(13).div(100);
  uint256 internal earlyBirdsBalance = kOrgValue.mul(23).div(100);
  uint256 internal legalExpensesBalance = kOrgValue.mul(6).div(100);
  uint256 internal specialBalance = kOrgValue.mul(1).div(100);

  // Organization wallets
  address public teamYear1 = 0x198e13017d2333712bd942d8b028610b95c363da;
  address public teamYear2 = 0x198e13017d2333712bd942d8b028610b95c363da;
  address public teamYear3 = 0x198e13017d2333712bd942d8b028610b95c363da;
  address public teamYear4 = 0x198e13017d2333712bd942d8b028610b95c363da;

  address public foundersYear1 = 0x198e13017d2333712bd942d8b028610b95c363da;
  address public foundersYear2 = 0x198e13017d2333712bd942d8b028610b95c363da;
  address public foundersYear3 = 0x198e13017d2333712bd942d8b028610b95c363da;
  address public foundersYear4 = 0x198e13017d2333712bd942d8b028610b95c363da;

  address public legalExpensesWallet = 0x198e13017d2333712bd942d8b028610b95c363da;

  address public specialMintWallet = 0x198e13017d2333712bd942d8b028610b95c363da;

  function cVOrganization() public {
    uint256 mintedBeforeICO = 85 ether;
    earlyBirdsBalance = earlyBirdsBalance.sub(mintedBeforeICO);
  }

}
