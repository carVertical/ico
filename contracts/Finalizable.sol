pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract Finalizable is Ownable {

  bool public isFinalized = false;

  event Finalized();

  function Finalizable() Ownable() public {}

  function finalize() onlyOwner public {
    require(!isFinalized);

    finalization();
    Finalized();

    isFinalized = true;
  }

  function finalization() internal {}

}
