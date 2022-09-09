//SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import './SharedFnsAndData.sol';

// Testnet

contract FractalStrings {

  SharedFnsAndData sfad;
  constructor(address sfadAddress) public {
    sfad = SharedFnsAndData(sfadAddress);
  }

  // To tesselate the Ethereum diamond, shapes are rectangles
  function defineShape(uint256 gen, uint8 sideIdx, uint8 colourIdxFill) internal view returns (string memory) {
    return '<circle id="shape0" fill="rgba(0,0,0,1)" stroke="none" cx="0" cy="0" r="0.5"/>';
    // return '<circle id="shape0" fill="rgba(255,255,0,0.5)" stroke-width="0.3px" stroke="rgba(0,0,255,0.8)" cx="0" cy="0" r="0.5"/>';
  }

  function defineAllShapes(uint256 gen) internal view returns (string memory) {
    return string(abi.encodePacked(
      defineShape(gen, 0, 1)
    ));
  }

  string[7] internal translates = [
    ' translate(0, 0)',
    ' translate(-1, 0)',
    ' translate(1, 0)',
    ' translate( 0.5, 0.866)',
    ' translate(-0.5, 0.866)',
    ' translate(-0.5,-0.866)',
    ' translate(0.5,-0.866)'
  ];
  function getIteration1Item(uint256 gen, uint8 itemIdx) private view returns (string memory) {
    return string(abi.encodePacked(
      '<g transform="scale(0.42857)"><g transform="',
      translates[itemIdx],
      '"><use href="#shape0"/></g></g>'
    ));
  }

  // Defines it_1_0, it_1_1
  function defineIteration1(uint256 gen, uint8 sideIdx) internal view returns (string memory) {
    // sideIdx should be 0 (left) or 1 (right)
    return string(abi.encodePacked(
      '<g id="it_1_',
      sfad.uint2str(sideIdx),
      '">',
      getIteration1Item(gen, 0),
      getIteration1Item(gen, 1),
      getIteration1Item(gen, 2),
      getIteration1Item(gen, 3),
      getIteration1Item(gen, 4),
      getIteration1Item(gen, 5),
      getIteration1Item(gen, 6),
      '</g>'
    ));
  }

  // There are 4 potential dropouts, each has probability 2^(-DROPOUT_BITS)
  // Using DROPOUT_BITS = 2, so probability of 0, 1, 2, 3, 4 dropouts is 31%, 42%, 21%, 4.6%, 0.3%
  function countDropout01(uint256 gen, uint8 itemIdx) public view returns (uint8 result) {
    return 0;
    // return sfad.getUint8(gen, 60 + 2 * itemIdx, 2) == 0 ? 1 : 0;
  }

  function countDropouts(uint256 gen) public view returns (uint8) {
    return countDropout01(gen, 0) + countDropout01(gen, 1) + countDropout01(gen, 2) + countDropout01(gen, 3);
  }

  function getDropoutAnimTxt(uint256 gen, uint8 itemIdx) internal view returns (string memory) {
    uint8 countDrop01 = countDropout01(gen, itemIdx);
    if (countDrop01 == 0) return '';
    return string(abi.encodePacked(
      '<animateTransform attributeName="transform" attributeType="XML" type="scale" values="1;1;0;0;0;0;1;1;1;1;1;1;1;1;1" dur="',
      sfad.uint2str(uint8(4 + itemIdx + 4 * sfad.getUint8(gen, 56 + itemIdx, 1))),  // Dropout cycle between 4 and 11 seconds, 1 bit random
      '.618s" repeatCount="indefinite" />'
    ));
  }

  // Probability 16 in 128 of rotation style, 8 in 128 of reflection, otherwise freestyle (104 in 128)
  function styleText(uint256 gen) public view returns (string memory) {
    if (countDropouts(gen) == 0) return 'Solid';
    uint8 style = styleNumber(gen);
    if (style < 16) return 'Spinner';
    if (style < 24) return 'Reflective';
    return 'Freestyle';
  }

  // If there are dropouts, 16 in 128 of rotation/spinner, 8 in 128 of reflective style
  function styleNumber(uint256 gen) internal view returns (uint8) {
    return sfad.getUint8(gen, 182, 7);  // free
  }

  // Returns 0 or 1. 0 scales by 0.5, 1 scales by -0.5
  uint8[4] internal xc = [0, 0, 1, 1];
  uint8[4] internal yc = [0, 1, 1, 0];
  function getReflectionNum(uint256 gen, uint8 itemIdx, uint8 coordIdx) internal view returns (uint8) {
    uint8 style = styleNumber(gen);
    if (style < 16) return 0;
    if (style < 24) {
      uint8 style2 = style - 16;
      uint8 x1 = style2 % 2;
      uint8 x2 = (style2 >> 1) % 2;
      uint8 y1 = (style2 >> 2) % 2;
      uint8 y2 = (style2 >> 3) % 2;
      if (coordIdx == 0) {
        return (x1 + x2 * xc[itemIdx]) % 2;
      } else {
        return (y1 + y2 * yc[itemIdx]) * 2;
      }
    }
    return sfad.getUint8(gen, 190 + coordIdx + 2 * itemIdx, 1);
  }

  // Returns "360", "-360", or "0"
  string[3] internal rotates = ["0","360","-360"];
  function getRotationNum(uint256 gen, uint8 itemIdx) internal view returns (string memory) {
    return "360";
    // return rotates[sfad.getUint8(gen, 48 + 2 * itemIdx, 2) % 3];
  }

  // string[4] internal xs = ['-0.25','-0.25',' 0.25',' 0.25'];
  // string[4] internal ys = ['-0.25',' 0.25',' 0.25','-0.25'];
  function getIterationNItem(uint256 gen, uint8 iteration, uint8 sideIdx, uint8 itemIdx) internal view returns (string memory) {
    return string(abi.encodePacked(
      '<g transform="scale(0.42857)">',
      '<g transform="',
      translates[itemIdx],
      '">',
      '<use href="#it_',
      sfad.uint2str(iteration-1),
      '_',
      sfad.uint2str(sideIdx),
      '">',
      '<animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0;',
      getRotationNum(gen, itemIdx),
      '" dur="1000s" repeatCount="indefinite" />',
      '</use></g></g>'
    ));
  }

  // side = 0, 1; iteration = 2, 3, 4; this uses 24 bits of randomness
  function getTwistIdx(uint256 gen, uint8 sideIdx, uint8 iteration) internal view returns (uint8) {
    return 0;
    // return sfad.getUint8(gen, 76 + 4 * sideIdx + 8 * (iteration - 2), 4);
  }

  // Rotation at each level is at slightly different times to the overall movement
  uint8[16] internal twistCounts = [0,0,0,0,0 , 1,1,1,1,1,1,1,1,1,1,1];
  function getTwistiness(uint256 gen) public view returns (uint8) {
    return twistCounts[getTwistIdx(gen, 0, 2)]
    + twistCounts[getTwistIdx(gen, 1, 2)]
    + twistCounts[getTwistIdx(gen, 0, 3)]
    + twistCounts[getTwistIdx(gen, 1, 3)]
    + twistCounts[getTwistIdx(gen, 0, 4)]
    + twistCounts[getTwistIdx(gen, 1, 4)];
  }
  string[16] internal twistValues = [
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
    '90;90;90;90;0;0;0;44;90',
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
      twistValues[getTwistIdx(gen, sideIdx, iteration)],
      '" ',
      getAnimDurTxt(gen),
      ' repeatCount="indefinite" />',
      getIterationNItem(gen, iteration, sideIdx, 0),
      getIterationNItem(gen, iteration, sideIdx, 1),
      getIterationNItem(gen, iteration, sideIdx, 2),
      getIterationNItem(gen, iteration, sideIdx, 3),
      getIterationNItem(gen, iteration, sideIdx, 4),
      getIterationNItem(gen, iteration, sideIdx, 5),
      getIterationNItem(gen, iteration, sideIdx, 6),
      '</g>'
    ));
  }

  function renderEthereum(uint256 gen, uint8 sideIdx, uint8 iteration, int16 translate) public view returns (string memory) {
    return string(abi.encodePacked(
      '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200;360 200 200" dur="1000s" repeatCount="indefinite" additive="sum"/><use href="#it_',
      sfad.uint2str(iteration),
      '_',
      sfad.uint2str(sideIdx),
      '" transform="translate(200, 200) scale(282, 282)"/></g>'
    ));
  }

  // Animation time between 3 and 39 seconds, mostly in the middle of the range
  // Uses 8 bits of randomness
  function getAnimDurS(uint256 gen) public view returns (uint8) {
    uint8 r255 = sfad.getUint8(gen, 16, 8); // 0 to 255
    uint8 r15 = r255 % 4 + (r255 >> 2) % 4 + (r255 >> 4) % 4 + (r255 >> 6) % 4; // Between 0 and 12
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
      renderEthereum(gen, 0, 4, 125)
      // renderEthereum(gen, 0, RENDER_ITERATION, 125)
      // renderEthereum(gen, 1, RENDER_ITERATION, 275)
    ));
  }
}