//SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import './SharedFnsAndData.sol';

contract FractalStrings {

  // Paths are (approx) in a box [-50, -50] to [50, 50] so require scale 1/100 to fix in a unit box
  uint8 internal constant PATHS_LEN = 6;
  string[PATHS_LEN] internal pathData = [
    'M -50 -50 L -50 50 50 50 50 -50 -50 -50',
    'M -50 -50 L -50 50 50 50 50 0 0 -50 -50 -50',
    'M -50 -50 L -50 50 50 50 50 0 0 0 0 -50 -50 -50',
    'M -50 -50 L -50 50 50 50 0 0 50 -50 -50 -50',
    'M -50 -50 L -50 50 0 33 50 50 50 -50 0 -33 -50 -50',
    'M -50 -50 L -33 0 -50 50 0 33 50 50 33 0 50 -50 0 -33 -50 -50'
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
      pathData[0],
      // pathData[sfad.getUint8(gen, sfad.getSectionShapesStartBits(shapeIdx), 4) % PATHS_LEN],
      '" fill="',
      sfad.getRGBA(gen, colourIdxFill, "0.75"),
      '" stroke="',
      sfad.getRGBA(gen, 0, "0.85"),
      // sfad.getRGBA(gen, colourIdxLine, "0.80"),
      '" stroke-width="3px" transform="scale(0.01 -0.01)" />'
    ));
  }

  // Defines shape0, shape1, ... shape7
  function defineAllShapes(uint256 gen) internal view returns (string memory) {
    return string(abi.encodePacked(
      defineShape(gen, 0, 1, 0),
      defineShape(gen, 1, 1, 1),
      defineShape(gen, 2, 1, 2),
      defineShape(gen, 3, 1, 3),
      defineShape(gen, 4, 2, 0),
      defineShape(gen, 5, 2, 1),
      defineShape(gen, 6, 2, 2),
      defineShape(gen, 7, 2, 3)
    ));
  }

  uint16[8] internal xStarts = [250, 750, 250, 750, 250, 750, 250, 750];
  uint16[8] internal xEnds = [125, 375, 625, 875, 625, 875, 125, 375];
  function getIteration1Item(uint8 sideIdx, uint8 itemIdx) private view returns (string memory) {
    uint8 idx = 4 * sideIdx + itemIdx;
    return string(abi.encodePacked(
      '<g transform="translate(-0.5, 0)">',
      '<animateTransform attributeName="transform" attributeType="XML" type="translate"',
      sfad.calcValuesFull(xStarts[idx], xEnds[idx], '0.', itemIdx > 1 ? " -0.25" : " 0.25"),
      ANIM_DUR,
      ' repeatCount="indefinite" additive="sum"/>',
      '<animateTransform attributeName="transform" attributeType="XML" type="scale"',
      sfad.calcValuesFull(500, 250, '0.', ' 0.5'),
      ANIM_DUR,
      ' repeatCount="indefinite" additive="sum"/>',
      '<use href="#shape',
      sfad.uint2str(idx),
      '"/>',
      '</g>'
    ));
  }

  // Defines it_1_0, it_1_1
  function defineIteration1(uint8 sideIdx) internal view returns (string memory) {
    // sideIdx should be 0 (left) or 1 (right)
    return string(abi.encodePacked(
      '<g id="it_1_',
      sfad.uint2str(sideIdx),
      '">',
      getIteration1Item(sideIdx, 0),
      getIteration1Item(sideIdx, 1),
      getIteration1Item(sideIdx, 2),
      getIteration1Item(sideIdx, 3),
      '</g>'
    ));
  }

  function getIterationNItem(uint8 sideIdx, uint8 iteration, string memory x, string memory y) internal view returns (string memory) {
    return string(abi.encodePacked(
      '<g>',
      // '<animateTransform attributeName="transform" attributeType="XML" type="rotate"',
      // sfad.calcValues(90, 0),
      // ANIM_DUR,
      // ' repeatCount="indefinite"/>',
      '<use href="#it_',
      sfad.uint2str(iteration-1),
      '_',
      sfad.uint2str(sideIdx),
      '" transform="scale(0.5) translate(',
      x,
      ',',
      y,
      ')"/></g>'
    ));
  }

  // Defines `it_N_i` in terms of `it_[N-1]_i`
  function defineIterationN(uint8 sideIdx, uint8 iteration) internal view returns (string memory) {
    // sideIdx should be 0 (left) or 1 (right)
    return string(abi.encodePacked(
      '<g id="it_',
      sfad.uint2str(iteration),
      '_',
      sfad.uint2str(sideIdx),
      '">',
      getIterationNItem(sideIdx, iteration, "-0.5", "-0.5"),
      getIterationNItem(sideIdx, iteration, " 0.5", "-0.5"),
      getIterationNItem(sideIdx, iteration, "-0.5", " 0.5"),
      getIterationNItem(sideIdx, iteration, " 0.5", " 0.5"),
      '</g>'
    ));
  }

  function renderEthereum(uint8 sideIdx, uint8 iteration, int16 translate) public view returns (string memory) {
    return string(abi.encodePacked(
      '<g><animateTransform attributeName="transform" attributeType="XML" type="translate"',
      sfad.calcValues(0, 200 - translate),
      ANIM_DUR,
      ' repeatCount="indefinite" additive="sum"/><use href="#it_',
      sfad.uint2str(iteration),
      '_',
      sfad.uint2str(sideIdx),
      '" transform="translate(',
      sfad.int2str(translate),
      ', 200) scale(95, 170) rotate(45)"/></g>'
    ));
  }

  uint8 internal constant RENDER_ITERATION = 3;
  string internal constant ANIM_DUR = ' dur="10s"';

  function renderEthereums(uint256 gen) public view returns (string memory) {
    return string(abi.encodePacked(
      '<defs>',
      defineAllShapes(gen),
      defineIteration1(0),
      defineIteration1(1),
      defineIterationN(0, 2),
      defineIterationN(1, 2),
      defineIterationN(0, 3),
      defineIterationN(1, 3),
      // defineIterationN(0, 4),
      // defineIterationN(1, 4), // up to iteration 4 can be rendered
      '</defs>',
      renderEthereum(0, RENDER_ITERATION, 125),
      renderEthereum(1, RENDER_ITERATION, 275)
    ));
  }
}