pragma solidity ^0.4.18;

import "./cVMintableToken.sol";

contract cVToken is cVMintableToken {
  string public constant name = "cVToken";
  string public constant symbol = "cV";
  uint8 public constant decimals = 18;
  mapping (address => uint256) private lockUntil;

  bool public transfersAreLocked = true;

  // Checks whether it can transfer or otherwise throws.
  modifier canTransfer(address _sender, uint _value) {
    require(!transfersAreLocked);
    require(lockUntil[_sender] < now);
    _;
  }

  // Returns current token Owner
  function tokenOwner() public view returns (address) {
    return owner;
  }

  // Checks modifier and allows transfer if tokens are not locked.
  function transfer(address _to, uint _value) canTransfer(msg.sender, _value) public returns (bool success) {
    return super.transfer(_to, _value);
  }

  // Checks modifier and allows transfer if tokens are not locked.
  function transferFrom(address _from, address _to, uint _value) canTransfer(_from, _value) public returns (bool success) {
    return super.transferFrom(_from, _to, _value);
  }

  // lock address from transfering until ..
  function lockTill(address addr, uint256 unlockTime) public onlyOwner {
    lockUntil[addr] = unlockTime;
  }

  // lock/unlock transfers
  function changeTransferLock(bool locked) public onlyOwner {
    transfersAreLocked = locked;
  }

}
