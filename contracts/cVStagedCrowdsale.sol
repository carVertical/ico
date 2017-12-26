pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/crowdsale/RefundVault.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./cVToken.sol";

contract cVStagedCrowdsale {
  using SafeMath for uint256;

  uint256 public weiRaised;

  // Address where funds are collected.
  address public wallet;

  cVToken public token;
  RefundVault public vault;

  uint256[6] private stageLimits = [
    1050 ether,
    3050 ether,
    6050 ether,
    9050 ether,
    12050 ether,
    15050 ether
  ];
  uint8[6] private stageDiscounts = [
    145,
    135,
    125,
    115,
    110,
    105
  ];
  uint public currentStage = 0;

  uint256 private rate;

  // Event which records a token purchase
  event TokenPurchase(
    address indexed beneficiary,
    uint256 value,
    uint256 amount,
    uint stage);

  // Event which records an early birds token purchase
  event EarlyBirdsTokenPurchase(
    address indexed beneficiary,
    uint256 value,
    uint256 amount);

  // Event which records an early birds token purchase
  event ManualMintRequiresRefund(
    address indexed receiver,
    uint256 refund);

  /**
   * @param _wallet Ethereum address to which the contributed funds are forwarded.
   * @param _token Token instance address.
   * @param _rate Rate at which cV token to ether will be generating
   */
  function cVStagedCrowdsale(
    address _wallet,
    address _token,
    uint256 _rate
    ) public {
    require(_wallet != address(0));
    require(_token != address(0));
    require(_rate > 0);

    vault = new RefundVault(_wallet);
    token = cVToken(_token);

    wallet = _wallet;

    rate = _rate;
  }

  // Entry point for a contribution
  function buyTokens() public payable {
    uint256 refund = appendContribution(msg.sender, msg.value);

    if (refund > 0) {
      msg.sender.transfer(refund);
    }
  }

  /** Mint tokens for BTC,LTC,Fiat contributions.
   * @param _receiver Who tokens will go to.
   * @param _value An amount of ether worth of tokens.
   */
  function manualTokenMint(address _receiver, uint256 _value) public {
    uint256 refund = appendContribution(_receiver, _value);

    if (refund > 0) {
      ManualMintRequiresRefund(_receiver, refund);
    }
  }

  /** Mint tokens for early product adopters.
   * @param _receiver Who tokens will go to.
   * @param _value An amount of ether worth of tokens.
   */
  function manualEarlyBirdsTokenMint(address _receiver, uint256 _value) public {
    uint256 tokens = _value.mul(rate);

    token.mint(_receiver, tokens);

    EarlyBirdsTokenPurchase(_receiver, _value, tokens);
  }

  /** Make all transfers and deposits for contribution.
   ** Increment stage if needed.
   * @param _sender Contributorf
   * @param _value Value
   * @returns uint256 refund
   */
  function appendContribution(address _sender, uint256 _value) private returns (uint256 _refund) {
    require(currentStage < stageLimits.length);

    weiRaised = weiRaised.add(_value);

    uint256 excess;

    if (weiRaised > stageLimits[currentStage]) {
      excess = weiRaised.sub(stageLimits[currentStage]);
      _value = _value.sub(excess);

      // Excess should be refunded if we are at the last stage.
      if (currentStage == stageLimits.length.sub(1)) {
        _refund = excess;
        weiRaised = weiRaised.sub(excess);
        excess = 0;
      }
    }

    mintTokens(_value, _sender);

    if (excess > 0) {
      currentStage = currentStage.add(1);
      mintTokens(excess, _sender);
    }
  }

  function mintTokens(uint256 _value, address _sender) private {
    uint256 tokens = _value.mul(rate).mul(stageDiscounts[currentStage]).div(100);
    TokenPurchase(_sender, _value, tokens, currentStage);
    token.mint(_sender, tokens);

    //   0 - to wallet
    //   1 - to vault
    // 2-5 - to wallet
    if (currentStage == 1) {
      vault.deposit.value(_value)(_sender);
    } else {
      wallet.transfer(_value);
    }
  }

}
