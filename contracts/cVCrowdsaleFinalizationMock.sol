pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";

import "./cVCrowdsaleFinalization.sol";
import "./cVTokenMock.sol";

contract cVCrowdsaleFinalizationMock is cVCrowdsaleFinalization {

  function tokenSetup() public onlyOwner {
    cVTokenMock tokenMock = new cVTokenMock();
    tokenMock.setNow(now);
    token = cVToken(tokenMock);  // hacking type system

    uint256 icoSoldTokens = 4637734523665296890795280000;
    address tokenHolder = 0x16052217BEf1a56fcEf68C996EdA34bf0C96D5e5;
    token.mint(tokenHolder, icoSoldTokens);
  }

}
