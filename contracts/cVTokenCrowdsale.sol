pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./cVOrganization.sol";
import "./cVStagedCrowdsale.sol";

contract cVTokenCrowdsale is Ownable, cVOrganization, cVStagedCrowdsale {
  using SafeMath for uint256;

  // Start and end timestamps.
  uint public startTime;
  uint public endTime;

  mapping (address => uint8) whitelist;
  bool whiteListEnabled = false;

  // Addresses of exchanges, so people do not contribute from exchange
  mapping (address => uint8) blacklist;

  uint256 public membersCount = 0;

  bool public isFinalized = false;

  // Event for token ownership transfer
  event TokenOwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  // Event for post-ICO token bonus withdrawal
  event WithdrawPostICOBonus(
    address indexed contributor,
    uint256 contributed,
    uint256 bonus
  );

  /**
   * @param _startTime Unix timestamp for the start of the token sale
   * @param _period Period of days, ICO will be open.
   * @param _wallet Ethereum address to which the contributed funds are forwarded.
   * @param _token Token instance address.
   */
  function cVTokenCrowdsale(
    uint256 _startTime,
    uint8 _period,
    address _wallet,
    address _token
    ) cVOrganization() cVStagedCrowdsale(_wallet, _token, kRate) public {
    /* require(_startTime > now); */
    require(_period > 0);

    startTime = _startTime;
    endTime = _startTime.add(60 * 60 * 24 * _period);
  }

  /** Purchase validator
   * @param _sender Contributors address
   * @param _amount Contributed amount
   */
  modifier validPurchase(address _sender, uint256 _amount) {
    require(msg.sender != 0x0);  // valid address
    isWhitelisted(msg.sender);  // is in whitelist
    require(blacklist[msg.sender] == 0); // not in blacklist
    /* require(now >= startTime && now <= endTime);  // within ico range */
    require(msg.value >= kMinStake && msg.value <= kMaxStake);  // within purchase range
    _;
  }

  // Default cointract function
  function () public payable {
    if (isFinalized) {
      claimRefund();
    } else {
      buyTokens();
    }
  }

  // Entry point for a contribution
  function buyTokens() validPurchase(msg.sender, msg.value) public payable {
    require(weiRaised.add(msg.value) <= icoBalance);

    super.buyTokens();

    icoBalance = icoBalance.sub(msg.value);
  }

  /** Mint tokens for BTC,LTC,Fiat contributions.
   * @param _receiver Who tokens will go to.
   * @param _value An amount of ether worth of tokens.
   */
  function manualTokenMint(address _receiver, uint256 _value) public onlyOwner {
    require(!(icoBalance.sub(_value) < 0));

    super.manualTokenMint(_receiver, _value);

    icoBalance = icoBalance.sub(_value);
  }

  /** Mint tokens for early product adopters.
   * @param _receiver Who tokens will go to.
   * @param _value An amount of ether worth of tokens.
   */
  function manualEarlyBirdsTokenMint(address _receiver, uint256 _value) public onlyOwner {
    require(!(earlyBirdsBalance.sub(_value) < 0));

    super.manualEarlyBirdsTokenMint(_receiver, _value);

    earlyBirdsBalance = earlyBirdsBalance.sub(_value);
  }

  // Entry point for refund
  function claimRefund() public {
    require(isFinalized);
    require(!softCapReached());

    vault.refund(msg.sender);
  }

  // Finalize and close crowdsale.
  function finalize() public onlyOwner {
    require(!isFinalized);
    require(now > endTime || icoBalance < kMinStake);

    if (softCapReached()) {
      vault.close();

      teamReward();
      foundersReward();
      legalExpenses();
      specialMint();

      // TODO - make sure 1% is minted for charity.
      // Mint leftover tokens.
      // Contributors will be able to withdraw them.
      token.mint(this, icoBalance.mul(kRate));
    } else {
      vault.enableRefunds();
    }

    transferTokenOwnership(owner);
    isFinalized = true;
  }

  /**
   * @return true If soft cap is reached.
   */
  function softCapReached() private constant returns (bool) {
    uint256 softCap = stageLimits[1];
    return weiRaised >= softCap;
  }

  /** Whitelist an address.
   * @param _addr Address to whitelist
   */
  function addToWhitelist(address _addr) public onlyOwner {
    require(whitelist[_addr] == 0);
    whitelist[_addr] = 1;
    membersCount = membersCount.add(1);
  }

  /** Blacklist an address
   * @param _addr Address to blacklist
   */
  function addToBlacklist(address _addr) public onlyOwner {
    require(blacklist[_addr] == 0);
    blacklist[_addr] = 1;
  }

  /** Checks if contributor passes whitelist check.
   * @param _sender Address to check
   * @return true If user is whitelisted or whitelisting is disabled.
   */
  function isWhitelisted(address _sender) private view returns (bool) {
    if (whiteListEnabled) {
      return (whitelist[_sender] > 0);
    } else {
      return true;
    }
  }

  /** Enable/Disable whitelist check
   * @param _enabled Address to check
   */
  function changeWhitelistStatus(bool _enabled) public onlyOwner {
    whiteListEnabled = _enabled;
  }

  /** Allows the current owner to transfer control of the contracts token to a newOwner
   * @param newOwner The address to transfer ownership to
   */
  function transferTokenOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    require(token.tokenOwner() != address(0));

    TokenOwnershipTransferred(token.tokenOwner(), newOwner);

    token.transferOwnership(newOwner);
  }

  // Close refund vault early
  function closeRefundVault() public onlyOwner {
    require(softCapReached());

    vault.close();
  }

  // Mint and vest Team Reward
  function teamReward() private {
    uint256 partPerYear = teamBalance.mul(kRate).div(4);
    uint yearInSeconds = 31536000;

    teamBalance = 0;
    token.lockTill(teamYear1, startTime + yearInSeconds);
    token.mint(teamYear1, partPerYear);

    token.lockTill(teamYear2, startTime + yearInSeconds * 2);
    token.mint(teamYear2, partPerYear);

    token.lockTill(teamYear3, startTime + yearInSeconds * 3);
    token.mint(teamYear3, partPerYear);

    token.lockTill(teamYear4, startTime + yearInSeconds * 4);
    token.mint(teamYear4, partPerYear);
  }

  // Mint and vest Founders Reward
  function foundersReward() private {
    uint256 partPerYear = foundersBalance.mul(kRate).div(4);
    uint yearInSeconds = 31536000;

    foundersBalance = 0;
    token.lockTill(foundersYear1, startTime + yearInSeconds);
    token.mint(foundersYear1, partPerYear);

    token.lockTill(foundersYear2, startTime + yearInSeconds * 2);
    token.mint(foundersYear2, partPerYear);

    token.lockTill(foundersYear3, startTime + yearInSeconds * 3);
    token.mint(foundersYear3, partPerYear);

    token.lockTill(foundersYear4, startTime + yearInSeconds * 4);
    token.mint(foundersYear4, partPerYear);
  }

  // Mint tokens for Legal Expenses
  function legalExpenses() private {
    uint256 tokens = legalExpensesBalance.mul(kRate);

    legalExpensesBalance = 0;
    token.mint(legalExpensesWallet, tokens);
  }

  // Special Mint
  function specialMint() private {
    uint256 tokens = specialBalance.mul(kRate);

    specialBalance = 0;
    token.mint(specialMintWallet, tokens);
  }

}
