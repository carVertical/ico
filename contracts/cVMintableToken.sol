pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/token/StandardToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract cVMintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  uint256 public supplyLimit = 9931143978 ether;
  bool public mintingFinished = false;

  modifier canMint(uint256 _amount) {
    require(!mintingFinished);
    require(totalSupply.add(_amount) <= supplyLimit);
    _;
  }

  function mint(address _to, uint256 _amount) onlyOwner canMint(_amount) public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  function finishMinting() onlyOwner canMint(0) public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }

}
