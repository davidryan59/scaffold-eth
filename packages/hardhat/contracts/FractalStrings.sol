//SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import './SharedFnsAndData.sol';

contract FractalStrings {
  string public testString = "Fractal Strings is operational!";

  SharedFnsAndData sfad;
  constructor(address sfadAddress) public {
    // 2nd contract because 1st contract ran out of code space...
    sfad = SharedFnsAndData(sfadAddress);
  }

  function testFunction() public pure returns (uint8) {
    return 42;
  }

  function getTestString() public view returns (string memory) {
    return testString;
  }
}