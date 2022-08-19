//SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import './SharedFnsAndData.sol';

contract FractalStrings {


  // Paths are (approx) in a box [-50, -50] to [50, 50] so require scale 1/100 to fix in a unit box
  uint8 internal constant PATHS_LEN = 3;
  string[PATHS_LEN] internal pathData = [
    'M -50 -50 L -50 50 50 50 50 -50 -50 -50',
    'M 0 -50 L -50 0 -50 50 0 25 50 50 50 0 0 -50',
    'M 0 -50 L -50 -33 -50 33 0 50 50 33 50 -33 0 -50'
  ];

  SharedFnsAndData sfad;
  constructor(address sfadAddress) public {
    // 2nd contract because 1st contract ran out of code space...
    sfad = SharedFnsAndData(sfadAddress);
  }

  function defineShape(uint256 gen, uint8 shapeIdx, uint8 colourIdxFill, uint8 colourIdxLine) internal view returns (string memory) {
    return string(abi.encodePacked(
      '<path id="shape',
      sfad.uint2str(shapeIdx),
      '" d="',
      pathData[sfad.getUint8(gen, sfad.getSectionShapesStartBits(shapeIdx), 4) % PATHS_LEN],
      '" fill="',
      sfad.getRGBA(gen, colourIdxFill, "0.65"),
      '" stroke="',
      sfad.getRGBA(gen, colourIdxLine, "0.80"),
      '" stroke-width="6px" transform="scale(0.01 -0.01)" />'
    ));
  }

  // Defines shape0, shape1, shape2...
  function defineAllShapes(uint256 gen) public view returns (string memory) {
    return string(abi.encodePacked(
      defineShape(gen, 0, 1, 0),
      defineShape(gen, 1, 1, 1)
      // defineShape(gen, 2, 1, 2),
      // defineShape(gen, 3, 1, 3),
      // defineShape(gen, 4, 2, 0),
      // defineShape(gen, 5, 2, 1),
      // defineShape(gen, 6, 2, 2),
      // defineShape(gen, 7, 2, 3)
    ));
  }

  function renderEthereum(uint256 gen) public view returns (string memory) {
    return string(abi.encodePacked(
      '<defs>',
      defineAllShapes(gen),
      '</defs>',
      '<g>',
      '<animateTransform attributeName="transform" attributeType="XML" type="translate" values="0; 37.5; 75; 0" dur="10s" repeatCount="indefinite"/>',
      '<use href="#shape0" transform="translate(125, 200) scale(95, 170) rotate(45)"/>',
      '</g>',
      '<g>',
      '<animateTransform attributeName="transform" attributeType="XML" type="translate" values="0; -37.5; -75; 0" dur="10s" repeatCount="indefinite"/>',
      '<use href="#shape1" transform="translate(275, 200) scale(95, 170) rotate(45)"/>',
      '</g>'
    ));
  }

}