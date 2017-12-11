pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/math/SafeMath.sol";

import "./Finalizable.sol";
import "./cVToken.sol";


contract cVEarlyBirdsCrowdsale is Finalizable {
  using SafeMath for uint256;

  uint256 public rate;
  address public wallet;
  cVToken public token;

  uint256 public weiRaised;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param bonusWei bonus wei added to value
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 bonusWei,
    uint256 amount
  );
  /**
   * Event for token ownership transfer
   * @param previousOwner who owned token before
   * @param newOwner who owns token now
   */
  event TokenOwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  function cVEarlyBirdsCrowdsale(
    uint256 _rate,
    address _wallet,
    address _token)
    Finalizable() public {
    rate = _rate;
    wallet = _wallet;
    token = cVToken(_token);
  }

  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;
    uint256 bonus = calculateBonus(msg.value);
    uint256 weiAmountWithBonus = weiAmount.add(bonus);

    // calculate token amount to be created
    uint256 tokens = weiAmountWithBonus.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(
      msg.sender,
      beneficiary,
      weiAmount,
      bonus,
      tokens
    );

    forwardFunds();
  }

  // send ether to the fund collection wallet
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  /**
   * Calculate additional bonus depending in amount
   * >=5 ether = 55% bonus
   * >=200 ether = 65% bonus
   * @param amount Wei to calculate bonus from
   * @return wei Calculated bonus wei for amount
   */
  function calculateBonus(uint256 amount) private pure returns (uint256) {
    uint256 bonusForAmount;
    if (amount >= 200 ether) {
      bonusForAmount = amount.mul(65).div(100);
    } else {
      bonusForAmount = amount.mul(55).div(100);
    }

    return bonusForAmount;
  }

  /**
   * Validate contribution
   * Must be non-zero
   * Must be more then 5 ether
   * @return true if the transaction can buy tokens
   */
  function validPurchase() internal view returns (bool) {
    bool nonZeroPurchase = msg.value != 0;
    bool moreThenFiveEther = msg.value >= 5 ether;
    return nonZeroPurchase && moreThenFiveEther;
  }

  /**
   * Allows the current owner to transfer control of the contracts token to a newOwner
   * @param newOwner The address to transfer ownership to
   */
  function transferTokenOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    require(token.tokenOwner() != address(0));

    TokenOwnershipTransferred(token.tokenOwner(), newOwner);

    token.transferOwnership(newOwner);
  }

  /**
   * Post finalization actions.
   * transfer token ownership to contract creator.
   */
  function finalization() internal {
    transferTokenOwnership(owner);
  }

}
