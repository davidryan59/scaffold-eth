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
  function getIteration1Item(uint256 gen, uint8 sideIdx, uint8 itemIdx) private view returns (string memory) {
    uint8 idx = 4 * sideIdx + itemIdx;
    return string(abi.encodePacked(
      '<g transform="translate(-0.5, 0)"><animateTransform attributeName="transform" attributeType="XML" type="translate"',
      sfad.calcValues(xStarts[idx], xEnds[idx], '0.', itemIdx > 1 ? " -0.25" : " 0.25"),
      getAnimDurTxt(gen),
      ' repeatCount="indefinite" additive="sum"/><animateTransform attributeName="transform" attributeType="XML" type="scale"',
      sfad.calcValues(500, 250, '0.', ' 0.5'),
      getAnimDurTxt(gen),
      ' repeatCount="indefinite" additive="sum"/><use href="#shape',
      sfad.uint2str(sideIdx),
      '"/></g>'
    ));
  }

  // Defines it_1_0, it_1_1
  function defineIteration1(uint256 gen, uint8 sideIdx) internal view returns (string memory) {
    // sideIdx should be 0 (left) or 1 (right)
    return string(abi.encodePacked(
      '<g id="it_1_',
      sfad.uint2str(sideIdx),
      '">',
      getIteration1Item(gen, sideIdx, 0),
      getIteration1Item(gen, sideIdx, 1),
      getIteration1Item(gen, sideIdx, 2),
      getIteration1Item(gen, sideIdx, 3),
      '</g>'
    ));
  }

  // 16 bits total across 4 items
  uint8 internal constant DROPOUT_BITS = 1;
  function countDropout01(uint256 gen, uint8 itemIdx) public view returns (uint8 result) {
    return sfad.getUint8(gen, 187 + DROPOUT_BITS * itemIdx, DROPOUT_BITS) == 0 ? 1 : 0;
  }

  function getDropoutAttrTxt(uint256 gen) public view returns (string memory) {
    return sfad.uint2str(countDropout01(gen, 0) + countDropout01(gen, 1) + countDropout01(gen, 2) + countDropout01(gen, 3));
  }

  string[4] internal dropoutAnimTxts = [
    ' values="1;1;1;1;1;1;1;1;1;1;1;0;0;1" dur="4.236s"',
    ' values="1;1;1;1;1;1;1;1;0;1;0;1" dur="8.618s"',
    ' values="1;1;1;1;1;1;1;1;1;1;0.5;0.5;0;1" dur="5.618s"',
    ' values="1;1;1;1;1;1;1;1;1.25;0.5;0.5;1" dur="6.854s"'
  ];

  function getDropoutAnimTxt(uint256 gen, uint8 itemIdx) internal view returns (string memory) {
    uint8 countDrop01 = countDropout01(gen, itemIdx);
    if (countDrop01 == 0) return '';
    return string(abi.encodePacked(
      '<animateTransform attributeName="transform" attributeType="XML" type="scale" ',
      dropoutAnimTxts[itemIdx],
      ' repeatCount="indefinite" />'
    ));
  }

  string[4] internal xs = ['-0.25','-0.25',' 0.25',' 0.25'];
  string[4] internal ys = ['-0.25',' 0.25','-0.25',' 0.25'];
  function getIterationNItem(uint256 gen, uint8 iteration, uint8 sideIdx, uint8 itemIdx) internal view returns (string memory) {
    return string(abi.encodePacked(
      '<g>',
      iteration == RENDER_ITERATION ? '' : getDropoutAnimTxt(gen, itemIdx),
      '<use href="#it_',
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
  string [16] internal rotates = [
    '0;0',
    '0;0',
    '0;0',
    '0;0',
    '0;0',
    '90;90;90;90;0;0;90',
    '-90;-90;-90;0;0;0;-90',
    '90;90;0;0;0;0;90',
    '90;90;60;30;0;0;90',
    '-90;-90;-90;-90;0;0;-45;-90',
    '-90;-90;0;0;0;0;0;-90',
    '90;90;45;0;0;0;0;90',
    '90;90;60;30;0;0;90;90',
    '-90;-90;-90;-90;-90;0;0;-90;-90',
    '90;90;90;90;0;0;0;45;90',
    '-90;-90;0;0;0;0;0;0;-90'
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
      getAnimDurTxt(gen),
      ' repeatCount="indefinite" />',
      getIterationNItem(gen, iteration, sideIdx, 0),
      getIterationNItem(gen, iteration, sideIdx, 1),
      getIterationNItem(gen, iteration, sideIdx, 2),
      getIterationNItem(gen, iteration, sideIdx, 3),
      '</g>'
    ));
  }

  function renderEthereum(uint256 gen, uint8 sideIdx, uint8 iteration, int16 translate) public view returns (string memory) {
    return string(abi.encodePacked(
      '<g><animateTransform attributeName="transform" attributeType="XML" type="translate"',
      sfad.calcValues(0, 200 - translate, '', ''),
      getAnimDurTxt(gen),
      ' repeatCount="indefinite" additive="sum"/><use href="#it_',
      sfad.uint2str(iteration),
      '_',
      sfad.uint2str(sideIdx),
      '" transform="translate(',
      sfad.int2str(translate),
      ', 200) scale(95, 190) rotate(45)"/></g>'
    ));
  }

  // Animation time between 3 and 48 seconds, mostly in the middle of the range
  // Uses 8 bits of randomness
  function getAnimDurS(uint256 gen) public view returns (uint8) {
    uint8 r255 = sfad.getUint8(gen, 135, 8); // 0 to 255
    uint8 r15 = r255 % 4 + (r255 >> 2) % 4 + (r255 >> 4) % 4 + (r255 >> 6) % 4; // 0 to 15
    return 3 * (1 + r15);
  }

  // Format of output is ' dur="5s"'
  function getAnimDurTxt(uint256 gen) internal view returns (string memory) {
    return string(abi.encodePacked(
      ' dur="',
      sfad.uint2str(getAnimDurS(gen)),
      's"'
    ));
  }

  uint8 internal constant RENDER_ITERATION = 4;
  function renderEthereums(uint256 gen) public view returns (string memory) {
    return string(abi.encodePacked(
      '<defs>',
      defineAllShapes(gen),
      defineIteration1(gen, 0),
      defineIteration1(gen, 1),
      defineIterationN(gen, 0, 2),
      defineIterationN(gen, 1, 2),
      defineIterationN(gen, 0, 3),
      defineIterationN(gen, 1, 3),
      defineIterationN(gen, 0, 4),
      defineIterationN(gen, 1, 4), // up to iteration 4 can be rendered
      '</defs>',
      renderEthereum(gen, 0, RENDER_ITERATION, 125),
      renderEthereum(gen, 1, RENDER_ITERATION, 275)
    ));
  }
}