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
  uint256 public constant kRate = 240000;
  uint256 public constant kMinStake = 0.1 ether;
  uint256 public constant kMaxStake = 2000 ether;
  uint256 public constant kOrgValue = 35000 ether;

  uint256[6] internal stageLimits = [
    1050 ether,
    3050 ether,
    6050 ether,
    9050 ether,
    12050 ether,
    15050 ether
  ];
  uint8[6] internal stageDiscounts = [
    145,
    135,
    125,
    115,
    110,
    105
  ];

  // Organization token distribution
  uint256 internal icoBalance = kOrgValue.mul(43).div(100);
  uint256 internal teamBalance = kOrgValue.mul(12).div(100);
  uint256 internal foundersBalance = kOrgValue.mul(10).div(100);
  uint256 internal earlyBirdsBalance = kOrgValue.mul(23).div(100);
  uint256 internal legalExpensesBalance = kOrgValue.mul(6).div(100);
  uint256 internal specialBalance = kOrgValue.mul(1).div(100);
  uint256 internal teamICOBonusBalance = kOrgValue.mul(5).div(100);

  // Organization wallets
  address public teamYear1 = 0x66BD5aDa347071D73D3cb6fc21dCAee28DB6f356;
  address public teamYear2 = 0x3549a1463A78B44930F6BF6DefaD518B08C0523D;
  address public teamYear3 = 0xfC1827355d7340aC40482c85e9Be6dE8eF71E45A;
  address public teamYear4 = 0xbaA3895cCa486500494b678E0B3Abd487eAeC99e;

  address public foundersYear1 = 0x27c90dE13eE38D41fC78b6939C4ECc754bF22cAf;
  address public foundersYear2 = 0xC56E30E3358613b8D3f4E066C12eEAFefcCD0966;
  address public foundersYear3 = 0x1c76b7B84A90D1CbB330b6Cb6E73208FBe674A7E;
  address public foundersYear4 = 0x4c57513Abec55c9FfF8e7aBF915B63E94eDb0eFC;

  address public legalExpensesWallet = 0x5661c9a1899fbF122F6ca9de26144f2ff2213a50;
  address public teamICOBonusWallet = 0x5661c9a1899fbF122F6ca9de26144f2ff2213a50;

  address public specialMintWallet = 0x3FEA3828f22d0AD4846F0D20CC145070D96BC85b;

  address public earlyBirdsWallet = 0x75F5eDC08A468a8596D2248814B9A1d1c5653D1D;

  function cVOrganization() public {
    require(stageLimits[stageLimits.length.sub(1)] == icoBalance);
    require(stageLimits.length == stageDiscounts.length);
    uint256 mintedBeforeICO = 85 ether;
    earlyBirdsBalance = earlyBirdsBalance.sub(mintedBeforeICO);
  }

}
