// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// ERC20 contract interface
abstract contract Token {
    function balanceOf(address) public virtual view returns (uint);
}

contract BalanceChecker {
  /*
    Check the token balance of a wallet in a token contract

    Returns the balance of the token for user. Avoids possible errors:
      - return 0 on non-contract address 
      - returns 0 if the contract doesn't implement balanceOf
  */
  function tokenBalance(address user, address token) public view returns (uint) {
    // check if token is actually a contract
    uint256 tokenCode;
    assembly { tokenCode := extcodesize(token) } // contract code size

    // is it a contract and does it implement balanceOf 
    if (tokenCode > 0) {
        (bool methodExists, ) = token.staticcall(abi.encodePacked(bytes4(0x70a08231), user));
            if (methodExists) {
                return Token(token).balanceOf(user);
            } else {
                return 0;
            }
    } else {
      return 0;
    }
  }

  function balancesPerAddress(address user, address[] memory tokens) public view returns (uint[] memory) {
      uint[] memory addrBalances = new uint[](tokens.length);
      for (uint i = 0; i < tokens.length; i++) {
          if (tokens[i] != address(0x0)) {
              addrBalances[i] = tokenBalance(user, tokens[i]);
          } else {
              addrBalances[i] = user.balance; // ETH balance
          }
      }

      return addrBalances;
  }

  function balancesHash(address[] calldata users, address[] calldata tokens) external view returns (uint256, bytes32[] memory) {
    bytes32[] memory addrBalances = new bytes32[](users.length);

    for(uint i = 0; i < users.length; i++) {
      addrBalances[i] = keccak256(abi.encodePacked(balancesPerAddress(users[i], tokens)));
    }

    return (block.number - 1, addrBalances);
  }
}
