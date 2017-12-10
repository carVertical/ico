pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/token/MintableToken.sol";

contract cVToken is MintableToken {
    string public constant name = "cVToken";
    string public constant symbol = "cV";
    uint8 public constant decimals = 18;
    mapping (address => uint256) private lockDuration;

    // Checks whether it can transfer or otherwise throws.
    modifier canTransfer(address _sender, uint _value) {
        require(lockDuration[_sender] < now);
        _;
    }

    // Checks modifier and allows transfer if tokens are not locked.
    function transfer(address _to, uint _value) canTransfer(msg.sender, _value) public returns (bool success) {
        return super.transfer(_to, _value);
    }

    // Checks modifier and allows transfer if tokens are not locked.
    function transferFrom(address _from, address _to, uint _value) canTransfer(_from, _value) public returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }

    function lockTill(address addr, uint256 timeTill) public onlyOwner {
        lockDuration[addr] = timeTill;
    }

    function tokenOwner() public view returns (address) {
        return owner;
    }

}
