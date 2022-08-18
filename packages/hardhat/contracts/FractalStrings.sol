//SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

contract FractalStrings {
  string public testString = "Fractal Strings is operational!";

  constructor() public {
    // 2nd contract because 1st contract ran out of code space...
  }

  function testFunction() public pure returns (uint8) {
    return 42;
  }

  function getTestString() public view returns (string memory) {
    return testString;
  }
}