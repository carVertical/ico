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

  // Contributors and their total contributions.
  mapping (address => uint256) public contributors;

  // Stages are ICO waves. They define limits and discounts.
  struct Stage {
    uint256 limit;
    uint discount;
  }
  Stage[] stageList;

  uint public stage = 0;

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

    setupStages();
  }

  // Entry point for a contribution
  function buyTokens() public payable {
    weiRaised = weiRaised.add(msg.value);

    // tokens to mint for contrinuted amount of ether
    uint256 tokens = calculateTokensForContributedAmount(msg.value);

    token.mint(msg.sender, tokens);

    contributors[msg.sender] = contributors[msg.sender].add(msg.value);

    TokenPurchase(msg.sender, msg.value, tokens, stage);

    appendContributionToStage(msg.sender, msg.value);
  }

  /** Mint tokens for BTC,LTC,Fiat contributions.
   * @param _receiver Who tokens will go to.
   * @param _value An amount of ether worth of tokens.
   */
  function manualTokenMint(address _receiver, uint256 _value) public {
    weiRaised = weiRaised.add(_value);

    // tokens being bought for contributed amount of ether
    uint256 tokens = calculateTokensForContributedAmount(_value);

    token.mint(_receiver, tokens);

    TokenPurchase(_receiver, _value, tokens, stage);

    appendContributionToStage(_receiver, _value);
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
   * @param _sender Contributor
   * @param _value Value
   */
  function appendContributionToStage(address _sender, uint256 _value) private  {
    if (crossingToNextStage(_value, 1)) {
      uint256 amountAvailableForRefund = weiRaised.sub(stageList[stage].limit);

      wallet.transfer(this.balance.sub(amountAvailableForRefund));
      vault.deposit.value(amountAvailableForRefund)(_sender);
    } else if (crossingToNextStage(_value, 2)) {
      uint256 amountToBeTransfered = weiRaised.sub(stageList[stage].limit);

      vault.deposit.value(this.balance.sub(amountToBeTransfered))(_sender);
      wallet.transfer(amountToBeTransfered);
    } else if (stage == 2) {
      vault.deposit.value(_value)(_sender);
    } else {
      wallet.transfer(this.balance);
    }

    // Increment currnet Stage if wei raised crosses a limit.
    if (amountIsCrossingStageLimit()) {
      stage = stage.add(1);
    }
  }

  // Setup contribution stages (waves)
  function setupStages() private {
    stageList.push(Stage({ limit: 1050 ether, discount: 145 }));
    stageList.push(Stage({ limit: 2000 ether, discount: 135 }));
    stageList.push(Stage({ limit: 3000 ether, discount: 125 }));
    stageList.push(Stage({ limit: 3000 ether, discount: 115 }));
    stageList.push(Stage({ limit: 3000 ether, discount: 110 }));
    stageList.push(Stage({ limit: 3000 ether, discount: 105 }));
  }

  /**
   * @return bool true if latest contributed crossed stage limit
   */
  function amountIsCrossingStageLimit() private view returns (bool) {
    return (weiRaised >= stageList[stage].limit);
  }

  /** Add Stage bonus to amount.
   * @param _amount The amount to which we are adding bonus wei
   * @param _stage Stage to add bonus for
   * @return uint256 if being crossed to next
   */
  function addBonus(uint256 _amount, Stage _stage) private pure returns (uint256) {
    return _amount.mul(_stage.discount).div(100);
  }

  /** Checks if contribution is crossing to the next stage.
   * @param _amount The amount that might be crossing the stage.
   * @param _stage Checks if stage is being crossed
   * @return true if being crossed to next
   */
  function crossingToNextStage(uint256 _amount, uint _stage) private view returns (bool) {
    uint256 amountBeforeLastContribution = weiRaised.sub(_amount);
    return (stage == _stage && amountBeforeLastContribution < stageList[stage].limit);
  }

  /** Calculates the amount of tokens for contributed amount
   ** including current Stage discount
   * @param _amount Wei being contributed
   * @return uint256 amount of tokens for _amount of wei contributed
   */
  function calculateTokensForContributedAmount(uint256 _amount) private view returns (uint256) {
    uint256 totalAmountWithDiscount = 0;

    Stage storage currentStage = stageList[stage];
    Stage storage nextStage = stageList[stage.add(1)];

    if (amountIsCrossingStageLimit()) {
      uint256 amountOverStageLimit = weiRaised.sub(currentStage.limit);
      uint256 amountUnderStageLimit = _amount.sub(amountOverStageLimit);
      uint256 underLimitAmount = addBonus(amountUnderStageLimit, currentStage);
      uint256 overLimitAmount = addBonus(amountOverStageLimit, nextStage);

      totalAmountWithDiscount = underLimitAmount.add(overLimitAmount);
    } else {
      totalAmountWithDiscount = addBonus(_amount, currentStage);
    }

    return totalAmountWithDiscount.mul(rate);
  }

}
