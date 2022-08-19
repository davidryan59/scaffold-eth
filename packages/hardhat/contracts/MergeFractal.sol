//SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';
// Learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

import './SharedFnsAndData.sol';
import './FractalStrings.sol';


// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

// Merge Fractal NFT developed for the Ethereum Merge event
// by David Ryan (@davidryan59 on Twitter)
// Check out some more of my fractal art at Nifty Ink!
// Artist page for niftymaestro.eth: https://nifty.ink/artist/0xbFAc61D1e22EFA9d37Fc3Ff36B9dff9655131F52

contract MergeFractal is ERC721, Ownable {

  // ----------------------------------------------
  // Amend these when deploying to new networks  
  bool internal constant IS_TESTNET = true;
  string internal constant NETWORK = 'TESTNET';
  // bool internal constant IS_TESTNET = false;
  // string internal constant NETWORK = 'Ethereum';
  // string internal constant NETWORK = 'Optimism';  // etc
  // ----------------------------------------------

  uint16[32] internal durations = [31,53,73,103,137,167,197,233,37,59,79,107,139,173,199,239,41,61,83,109,149,179,211,241,43,67,89,113,151,181,223,251];

  // Control colours that are used in the NFT
  uint8[32] internal colsR = [0,128,96,64,0,0,0,64,85,255,191,128,0,0,0,128,170,0,64,127,255,255,255,127,255,127,191,255,255,255,191,255];
  uint8[32] internal colsG = [0,0,32,64,128,64,0,0,85,0,64,128,255,128,0,0,170,255,191,127,0,127,255,255,255,255,191,127,191,255,255,159];
  uint8[32] internal colsB = [0,0,0,0,0,64,128,64,85,0,0,0,0,128,255,128,170,255,255,255,255,127,0,127,255,255,255,255,191,127,191,223];

  // Control placement of 4 sets of rotating lines
  uint8[4] internal sectionLineTranslates = [2, 4, 36, 38];

  // Control how randomisation is generated via startBit
  uint8[8] internal sectionShapesStartBits = [74, 78, 82, 86, 90, 94, 98, 102]; // 8 shapes, each uses 4 bits for shape selection
  uint8[4] internal sectionColStartBits = [50, 56, 62, 68]; // 4 sections, each uses 3 bits for colour, 3 bits for duration

  // Random core dev and team to thank
  uint8 internal constant CORE_DEV_START_BIT = 0; // Uses 8 bits
  uint8 internal constant TEAM_ARRAY_LEN = 25;
  string[TEAM_ARRAY_LEN] internal teams = ['Independent','0xSplits','Akula','EF DevOps','EF Geth','EF Ipsilon','EF JavaScript','EF Portal','EF Protocol Support','EF Research','EF Robust Incentives Group','EF Security','EF Solidity','EF Testing','Erigon','Ethereum Cat Herders','Hyperledger Besu','Lighthouse','Lodestar','Nethermind','Prysmatic','Quilt','Status','Teku','TXRX'];

  // Random saying
  uint8 internal constant SAYING_START_BIT = 8; // Uses 8 bits
  uint8 internal constant SAYING_ARRAY_LEN = 19;
  string[SAYING_ARRAY_LEN] internal sayings = ['PoS > PoW','Environmentally friendly at last','The Flippening','Decentralise Everything','Energy consumption -99.95%','Unstoppable smart contracts','Run your own node','TTD 58750000000000000000000','TTD 5.875 * 10^22','TTD 2^19 * 5^22 * 47','Validate with 32 ETH','Validators > Miners','Sustainable and secure','Proof-of-stake consensus','World Computer','Permissionless','Vitalik is clapping','Vitalik is dancing','Anthony Sassano is dancing'];

  // Paths are (approx) in a box [-50, -50] to [50, 50] so require scale 1/100 to fix in a unit box
  uint8 internal constant PATHS_LEN = 3;
  string[PATHS_LEN] internal pathData = [
    'M -50 -50 L -50 50 50 50 50 -50 -50 -50',
    'M 0 -50 L -50 0 -50 50 0 25 50 50 50 0 0 -50',
    'M 0 -50 L -50 -33 -50 33 0 50 50 33 50 -33 0 -50'
  ];

  using Strings for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  SharedFnsAndData sfad;
  FractalStrings fs;
  constructor(address sfadAddress, address fsAddress) public ERC721("MergeFractals", "MERGFR") {
    sfad = SharedFnsAndData(sfadAddress);
    fs = FractalStrings(fsAddress);
  }

  mapping (uint256 => uint256) internal generator;
  mapping (uint256 => address) internal mintooor;
  uint256 mintDeadline = block.timestamp + 60 days;

  function mintItem()
      public
      returns (uint256)
  {
      require( block.timestamp < mintDeadline, "DONE MINTING");
      _tokenIds.increment();
      uint256 id = _tokenIds.current();
      _mint(msg.sender, id);
      generator[id] = uint256(keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this), id)));
      mintooor[id] = msg.sender;
      return id;
  }

  // Get up to 8 pseudorandom bits from the 256-bit pseudorandom generator
  function getUint8(uint256 id, uint8 startBit, uint8 bits) internal view returns (uint8) {
    uint8 gen8bits = uint8(generator[id] >> startBit);
    if (bits >= 8) return gen8bits;
    return gen8bits % 2 ** bits;
  }

  function getRGBA(uint256 id, uint8 arraySection, string memory alpha) internal view returns (string memory) {
    uint8 startBit = sectionColStartBits[arraySection];
    // Array section values are 0, 1, 2 or 3 (0 is darkest, 3 is lightest)
    // These sections give colours 0-7, 8-15, 16-23, 24-31
    uint8 idx = 8 * arraySection + getUint8(id, startBit, 3); // 3 bits = 8 colour choices
    return string(abi.encodePacked(
      'rgba(',
      sfad.uint2str(colsR[idx]),
      ',',
      sfad.uint2str(colsG[idx]),
      ',',
      sfad.uint2str(colsB[idx]),
      ',',
      alpha,
      ')'
    ));
  }

  function getTrait(string memory traitType, string memory traitValue) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '{"trait_type": "',
      traitType,
      '", "value": "',
      traitValue,
      '"}'
    ));
  }

  function getAllAttributes(uint256 id) public view returns (string memory) {
    return string(abi.encodePacked(
      '[',
      getTrait("Dev", getCoreDevName(id)),
      ',',
      getTrait("Team", getTeamName(id)),
      ',',
      getTrait("Saying", getSaying(id)),
      ']'
    ));
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
    require(_exists(id), "not exist");
    string memory name = string(abi.encodePacked('Merge Fractal #',id.toString()));
    string memory description = string(abi.encodePacked('This Merge Fractal is to thank ', getCoreDevName(id), '!'));
    string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));

    return string(abi.encodePacked(
      'data:application/json;base64,',
      Base64.encode(bytes(abi.encodePacked(
        '{"name":"',
        name,
        '", "description":"',
        description,
        '", "external_url":"https://burnyboys.com/token/',
        id.toString(),
        '", "attributes": ',
        getAllAttributes(id),
        ', "owner":"',
        sfad.toHexString(uint160(ownerOf(id)), 20),
        '", "image": "data:image/svg+xml;base64,',
        image,
        '"}'
      )))
    ));
  }

  function generateSVGofTokenById(uint256 id) internal view returns (string memory) {
    return string(abi.encodePacked(
      '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
        renderTokenById(id),
      '</svg>'
    ));
  }

  function renderDisk(uint256 id) internal view returns (string memory) {
    return string(abi.encodePacked(
      '<circle fill="',
      getRGBA(id, 3, "1"),
      '" cx="200" cy="200" r="200"/>'
    ));
  }

  function getLinesTransform(uint8 arraySection) internal view returns (string memory) {
    uint16 num1 = sectionLineTranslates[arraySection];
    return string(abi.encodePacked(
      ' transform="translate(',
      sfad.uint2str(num1),
      ' ',
      sfad.uint2str(num1),
      ') scale(0.',
      sfad.uint2str(200 - num1),
      ')"'
    ));
  }

  function getDur(uint256 id, uint8 arraySection) internal view returns (string memory) {
    uint8 startBitDur = sectionColStartBits[arraySection] + 3;
    uint8 idx = 8 * arraySection + getUint8(id, startBitDur, 3); // 3 bits = 8 duration choices
    return string(abi.encodePacked(
      ' dur="',
      sfad.uint2str(3 * durations[idx]), // It was rotating too fast! Extra factor here
      's"'
    ));
  }

  // Uses 6 random bits
  function renderLines(uint256 id, uint8 arraySection, string memory maxAngleText) internal view returns (string memory) {
    string memory rgba = getRGBA(id, arraySection, "0.90");
    // // -------------------------------
    // // TEMP RECTANGLES TO TEST COLOURS
    // string memory render = '';
    // render = '' // <<assign it>>
    // // ...
    // if (IS_TESTNET) {
    //   uint16 x = arraySection >> 1 == 0 ? 0 : 350;
    //   uint16 y = arraySection % 2 == 1 ? 0 : 350;
    //   render = string(abi.encodePacked(
    //     render,
    //     '<rect x="',
    //     sfad.uint2str(x),
    //     '" y="',
    //     sfad.uint2str(y),
    //     '" width="50" height="50" rx="15" fill="',
    //     rgba,
    //     '"/>'
    //   ));
    // }
    // // -------------------------------

    return string(abi.encodePacked(
      '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; ',
      maxAngleText,
      ' 200 200; 0 200 200"',
      getDur(id, arraySection),
      ' repeatCount="indefinite"/><path fill="none" stroke-linecap="round" stroke="',
      rgba,
      '" stroke-width="9px"',
      sfad.getLinesPath(),
      getLinesTransform(arraySection),
      '/></g>'
    ));
  }

  function renderDiskAndLines(uint256 id) internal view returns (string memory) {
    return string(abi.encodePacked(
      renderDisk(id),
      renderLines(id, 0, "-270"),
      renderLines(id, 1, "270"),
      renderLines(id, 2, "-180"),
      renderLines(id, 3, "180")
    ));
  }

  function renderBorder(uint256 id) internal view returns (string memory) {
    string memory rgba0 = getRGBA(id, 0, "0.9");
    return string(abi.encodePacked(
      '<circle r="180" stroke-width="28px" stroke="',
      getRGBA(id, 3, "0.8"),
      '" fill="none" cx="200" cy="200"/>',
      '<circle r="197" stroke-width="6px" stroke="',
      rgba0,
      '" fill="none" cx="200" cy="200"/>',
      '<circle r="163" stroke-width="6px" stroke="',
      rgba0,
      '" fill="none" cx="200" cy="200"/>'
    ));
  }

  function getCoreDevIdx(uint256 id) internal view returns (uint8 idx) {
    return getUint8(id, CORE_DEV_START_BIT, 8) % sfad.getCoreDevArrayLen();
  }

  function getTeamIdx(uint256 id) internal view returns (uint8 idx) {
    return sfad.getCoreDevTeamIndex(getCoreDevIdx(id));
  }

  function getCoreDevName(uint256 id) internal view returns (string memory) {
    return sfad.getCoreDevName(getCoreDevIdx(id));
  }

  function getTeamName(uint256 id) internal view returns (string memory) {
    return teams[getTeamIdx(id)];
  }

  function getCoreDevAndTeamText(uint256 id) internal view returns (string memory) {
    string memory teamText = string(abi.encodePacked(' and ', getTeamName(id)));
    if (getCoreDevIdx(id) == 0) { // Dev = Vitalik
      teamText = string(abi.encodePacked(' for Ethereum'));
    } else if (getTeamIdx(id) == 0) { // Team = Individual
      teamText = '';
    }
    return string(abi.encodePacked(
      'Thank you ',
      getCoreDevName(id),
      teamText
    ));   
  }

  function getSaying(uint256 id) internal view returns (string memory) {
    return sayings[getUint8(id, SAYING_START_BIT, 8) % SAYING_ARRAY_LEN];
  }

  function renderText(uint256 id) internal view returns (string memory) {
    return string(abi.encodePacked(
      '<defs><style>text{font-size:15px;font-family:Helvetica,sans-serif;font-weight:900;fill:',
      getRGBA(id, 0, "1"),
      ';letter-spacing:1px}</style><path id="textcircle" fill="none" stroke="rgba(255,0,0,0.5)" d="M 196 375 A 175 175 270 1 1 375 200 A 175 175 90 0 1 204 375" /></defs>',
      '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; 360 200 200" dur="120s" repeatCount="indefinite"/><text><textPath href="#textcircle">/ ',
      NETWORK,
      ' Merge Fractal #',
      sfad.uint2str(id),
      ' / ',
      getCoreDevAndTeamText(id),
      '! / ',
      // getSaying(id),
      fs.getTestString(),
      ' / Minted by ',
      sfad.toHexString(uint160(mintooor[id]), 20),
      '♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦</textPath></text></g>'
    ));  
  }

  function defineShape(uint256 id, uint8 shapeIdx, uint8 colourIdxFill, uint8 colourIdxLine) internal view returns (string memory) {
    return string(abi.encodePacked(
      '<path id="shape',
      sfad.uint2str(shapeIdx),
      '" d="',
      pathData[getUint8(id, sectionShapesStartBits[shapeIdx], 4) % PATHS_LEN],
      '" fill="',
      getRGBA(id, colourIdxFill, "0.65"),
      '" stroke="',
      getRGBA(id, colourIdxLine, "0.80"),
      '" stroke-width="6px" transform="scale(0.01 -0.01)" />'
    ));
  }

  // Defines shape0, shape1, shape2...
  function defineAllShapes(uint256 id) public view returns (string memory) {
    return string(abi.encodePacked(
      defineShape(id, 0, 1, 0),
      defineShape(id, 1, 1, 1)
      // defineShape(id, 2, 1, 2),
      // defineShape(id, 3, 1, 3),
      // defineShape(id, 4, 2, 0),
      // defineShape(id, 5, 2, 1),
      // defineShape(id, 6, 2, 2),
      // defineShape(id, 7, 2, 3)
    ));
  }

  // uint16[31] internal interpolationCurve10k = [0,50,200,450,800,1250,1800,2450,3200,4050,5000,5950,6800,7550,8200,8750,9200,9550,9800,9950,10000,9992,9872,9352,7952,5000,2048,648,128,8,0];

  // function calculateTransformValues(int64 startVal, int64 endVal) internal pure returns (string memory) {
  //   string memory result = '';
  //   return '0; 37; 75; 0';
  // }

  function renderEthereum(uint256 id) internal view returns (string memory) {
    return string(abi.encodePacked(
      '<defs>',
      defineAllShapes(id),
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

  // Function visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenById(uint256 id) public view returns (string memory) {
    return string(abi.encodePacked(
      renderDiskAndLines(id),
      renderBorder(id),
      renderText(id),
      renderEthereum(id)
    ));
  }
}
