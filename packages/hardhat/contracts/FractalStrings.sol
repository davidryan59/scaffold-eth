//SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import './SharedFnsAndData.sol';

contract FractalStrings {

  SharedFnsAndData sfad;
  constructor(address sfadAddress) public {
    // 2nd contract because 1st contract ran out of code space...
    sfad = SharedFnsAndData(sfadAddress);
  }

  // To tesselate the Ethereum diamond, shapes are rectangles
  function defineShape(uint256 gen, uint8 sideIdx, uint8 colourIdxFill) internal view returns (string memory) {
    return string(abi.encodePacked(
      '<rect id="shape',
      sfad.uint2str(sideIdx),
      '" x="-0.5" y="-0.5" width="1" height="1" rx="0.25" fill="',
      sfad.getRGBA(gen, colourIdxFill, "0.70"),
      '" stroke="',
      sfad.getRGBA(gen, 0, "0.80"),
      '" stroke-width="0.15px"/>'
    ));
  }

  // Defines shape0, shape1, ... shape7
  function defineAllShapes(uint256 gen) internal view returns (string memory) {
    return string(abi.encodePacked(
      defineShape(gen, 0, 1),
      defineShape(gen, 1, 2)
    ));
  }

  uint16[8] internal xStarts = [250, 750, 250, 750, 250, 750, 250, 750];
  uint16[8] internal xEnds = [125, 375, 625, 875, 625, 875, 125, 375];
  function getIteration1Item(uint8 sideIdx, uint8 itemIdx) private view returns (string memory) {
    uint8 idx = 4 * sideIdx + itemIdx;
    return string(abi.encodePacked(
      '<g transform="translate(-0.5, 0)"><animateTransform attributeName="transform" attributeType="XML" type="translate"',
      sfad.calcValuesFull(xStarts[idx], xEnds[idx], '0.', itemIdx > 1 ? " -0.25" : " 0.25"),
      ANIM_DUR,
      ' repeatCount="indefinite" additive="sum"/><animateTransform attributeName="transform" attributeType="XML" type="scale"',
      sfad.calcValuesFull(500, 250, '0.', ' 0.5'),
      ANIM_DUR,
      ' repeatCount="indefinite" additive="sum"/><use href="#shape',
      sfad.uint2str(sideIdx),
      '"/></g>'
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

  string[4] internal xs = ['-0.25','-0.25',' 0.25',' 0.25'];
  string[4] internal ys = ['-0.25',' 0.25','-0.25',' 0.25'];
  function getIterationNItem(uint256 gen, uint8 iteration, uint8 sideIdx, uint8 itemIdx) internal view returns (string memory) {
    return string(abi.encodePacked(
      '<g><use href="#it_',
      sfad.uint2str(iteration-1),
      '_',
      sfad.uint2str(sideIdx),
      '" transform="translate(',
      xs[itemIdx],
      ',',
      ys[itemIdx],
      ') rotate(',
      sfad.uint2str(90 * uint16(sfad.getUint8(gen, 13 + itemIdx * 2, 2))),
      ') scale(0.5 ',
      sfad.getUint8(gen, 21 + itemIdx, 1) == 0 ? '-0.5' : '0.5',
      ')"/></g>'
    ));
  }

  // Rotation at each level is at slightly different times to the overall movement
  string[16] internal rotates = [
    '0;0',
    '0;0',
    '0;0',
    '0;0',
    '0;0',
    '90;90;90;90;0;0;90',
    '-90;-90;-90;0;0;0;-90',
    '90;90;0;0;0;0;90',
    '90;90;90;90;90;0;0;90',
    '-90;-90;-90;-90;0;0;0;-90',
    '90;90;90;0;0;0;0;90',
    '-90;-90;-45;0;0;0;0;-90',
    '90;90;90;90;90;0;0;0;90',
    '-90;-90;-60;-30;0;0;0;0;-90',
    '90;90;72;54;36;18;0;0;90',
    '-90;-90;0;0;0;0;0;-90;-90'
  ];
  // Defines `it_N_i` in terms of `it_[N-1]_i`
  function defineIterationN(uint256 gen, uint8 sideIdx, uint8 iteration) internal view returns (string memory) {
    // sideIdx should be 0 (left) or 1 (right)
    return string(abi.encodePacked(
      '<g id="it_',
      sfad.uint2str(iteration),
      '_',
      sfad.uint2str(sideIdx),
      '"><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="',
      rotates[sfad.getUint8(gen, 155 + 4 * sideIdx + 8 * iteration, 4)],
      '" ',
      ANIM_DUR,
      ' repeatCount="indefinite" />',
      getIterationNItem(gen, iteration, sideIdx, 0),
      getIterationNItem(gen, iteration, sideIdx, 1),
      getIterationNItem(gen, iteration, sideIdx, 2),
      getIterationNItem(gen, iteration, sideIdx, 3),
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
      ', 200) scale(95, 190) rotate(45)"/></g>'
    ));
  }

  uint8 internal constant RENDER_ITERATION = 4;
  string internal constant ANIM_DUR = ' dur="30s"';

  function renderEthereums(uint256 gen) public view returns (string memory) {
    return string(abi.encodePacked(
      '<defs>',
      defineAllShapes(gen),
      defineIteration1(0),
      defineIteration1(1),
      defineIterationN(gen, 0, 2),
      defineIterationN(gen, 1, 2),
      defineIterationN(gen, 0, 3),
      defineIterationN(gen, 1, 3),
      defineIterationN(gen, 0, 4),
      defineIterationN(gen, 1, 4), // up to iteration 4 can be rendered
      '</defs>',
      renderEthereum(0, RENDER_ITERATION, 125),
      renderEthereum(1, RENDER_ITERATION, 275)
    ));
  }
}