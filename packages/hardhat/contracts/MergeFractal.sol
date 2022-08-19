//SPDX-License-Identifier: MIT

//   ____ ______ __  __  ____ ____   ____ __ __ ___  ___    ___  ___  ____ ____    ___   ____     ____ ____   ___    ___ ______  ___  __   
//  ||    | || | ||  || ||    || \\ ||    || || ||\\//||    ||\\//|| ||    || \\  // \\ ||       ||    || \\ // \\  //   | || | // \\ ||   
//  ||==    ||   ||==|| ||==  ||_// ||==  || || || \/ ||    || \/ || ||==  ||_// (( ___ ||==     ||==  ||_// ||=|| ((      ||   ||=|| ||   
//  ||___   ||   ||  || ||___ || \\ ||___ \\_// ||    ||    ||    || ||___ || \\  \\_|| ||___    ||    || \\ || ||  \\__   ||   || || ||__|
                                                                                                                                        
// (ASCII art font: Double, via https://patorjk.com/software/taag)

// Merge Fractal NFT developed for the Ethereum Merge event
// by David Ryan (@davidryan59 on Twitter)
// Check out some more of my fractal art at Nifty Ink!
// Artist page for niftymaestro.eth: https://nifty.ink/artist/0xbFAc61D1e22EFA9d37Fc3Ff36B9dff9655131F52

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

contract MergeFractal is ERC721, Ownable {

  // ----------------------------------------------
  // Amend these when deploying to new networks  
  bool internal constant IS_TESTNET = true;
  string internal constant NETWORK = 'TESTNET';
  // bool internal constant IS_TESTNET = false;
  // string internal constant NETWORK = 'Ethereum';
  // string internal constant NETWORK = 'Optimism';  // etc
  // ----------------------------------------------

  // Control placement of 4 sets of rotating lines
  uint8[4] internal sectionLineTranslates = [2, 4, 36, 38];

  // Random core dev and team to thank
  uint8 internal constant CORE_DEV_START_BIT = 0; // Uses 8 bits
  uint8 internal constant TEAM_ARRAY_LEN = 25;
  string[TEAM_ARRAY_LEN] internal teams = ['Independent','0xSplits','Akula','EF DevOps','EF Geth','EF Ipsilon','EF JavaScript','EF Portal','EF Protocol Support','EF Research','EF Robust Incentives Group','EF Security','EF Solidity','EF Testing','Erigon','Ethereum Cat Herders','Hyperledger Besu','Lighthouse','Lodestar','Nethermind','Prysmatic','Quilt','Status','Teku','TXRX'];

  // Random saying
  uint8 internal constant SAYING_START_BIT = 8; // Uses 8 bits
  uint8 internal constant SAYING_ARRAY_LEN = 19;
  string[SAYING_ARRAY_LEN] internal sayings = ['PoS > PoW','Environmentally friendly at last','The Flippening','Decentralise Everything','Energy consumption -99.95%','Unstoppable smart contracts','Run your own node','TTD 58750000000000000000000','TTD 5.875 * 10^22','TTD 2^19 * 5^22 * 47','Validate with 32 ETH','Validators > Miners','Sustainable and secure','Proof-of-stake consensus','World Computer','Permissionless','Vitalik is clapping','Vitalik is dancing','Anthony Sassano is dancing'];

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

  function generateSVGofTokenById(uint256 id) public view returns (string memory) {
    return string(abi.encodePacked(
      '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
        renderTokenById(id),
      '</svg>'
    ));
  }

  function renderDisk(uint256 gen) internal view returns (string memory) {
    return string(abi.encodePacked(
      '<circle fill="',
      sfad.getRGBA(gen, 3, "1"),
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

  function renderTestnetColourPatch(uint256 gen, uint8 arraySection) internal view returns (string memory) {
    return string(abi.encodePacked(
      '<rect x="',
      sfad.uint2str(arraySection >> 1 == 0 ? 0 : 350),
      '" y="',
      sfad.uint2str(arraySection % 2 == 1 ? 0 : 350),
      '" width="50" height="50" rx="15" fill="',
      sfad.getRGBA(gen, arraySection, "1"),
      '"/>'
    ));
  }

  // Uses 6 random bits per line set / section
  function renderLines(uint256 gen, uint8 arraySection, string memory maxAngleText) internal view returns (string memory) {
    return string(abi.encodePacked(
      '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; ',
      maxAngleText,
      ' 200 200; 0 200 200"',
      sfad.getDurText(gen, arraySection),
      ' repeatCount="indefinite"/><path fill="none" stroke-linecap="round" stroke="',
      sfad.getRGBA(gen, arraySection, "0.90"),
      '" stroke-width="9px"',
      sfad.getLinesPath(),
      getLinesTransform(arraySection),
      '/></g>',
      IS_TESTNET ? renderTestnetColourPatch(gen, arraySection) : ''
    ));
  }

  function renderDiskAndLines(uint256 gen) internal view returns (string memory) {
    return string(abi.encodePacked(
      renderDisk(gen),
      renderLines(gen, 0, "-270"),
      renderLines(gen, 1, "270"),
      renderLines(gen, 2, "-180"),
      renderLines(gen, 3, "180")
    ));
  }

  function renderBorder(uint256 gen) internal view returns (string memory) {
    string memory rgba0 = sfad.getRGBA(gen, 0, "0.9");
    return string(abi.encodePacked(
      '<circle r="180" stroke-width="28px" stroke="',
      sfad.getRGBA(gen, 3, "0.8"),
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
    return sfad.getUint8(generator[id], CORE_DEV_START_BIT, 8) % sfad.getCoreDevArrayLen();
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
    string memory teamText = string(abi.encodePacked(' / ', getTeamName(id)));
    if (getTeamIdx(id) == 0) { // If team = Individual, don't display team
      teamText = '';
    }
    return string(abi.encodePacked(
      getCoreDevName(id),
      teamText
    ));   
  }

  function getSaying(uint256 id) internal view returns (string memory) {
    return sayings[sfad.getUint8(generator[id], SAYING_START_BIT, 8) % SAYING_ARRAY_LEN];
  }

  function renderText(uint256 id) internal view returns (string memory) {
    return string(abi.encodePacked(
      '<defs><style>text{font-size:15px;font-family:Helvetica,sans-serif;font-weight:900;fill:',
      sfad.getRGBA(generator[id], 0, "1"),
      ';letter-spacing:1px}</style><path id="textcircle" fill="none" stroke="rgba(255,0,0,0.5)" d="M 196 375 A 175 175 270 1 1 375 200 A 175 175 90 0 1 204 375" /></defs>',
      '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; 360 200 200" dur="120s" repeatCount="indefinite"/><text><textPath href="#textcircle">/ ',
      NETWORK,
      ' Merge Fractal #',
      sfad.uint2str(id),
      ' / ',
      getCoreDevAndTeamText(id),
      ' / ',
      getSaying(id),
      ' / Minted by ',
      sfad.toHexString(uint160(mintooor[id]), 20),
      '♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦</textPath></text></g>'
    ));  
  }

  function renderTokenById(uint256 id) public view returns (string memory) {
    uint256 gen = generator[id];
    return string(abi.encodePacked(
      renderDiskAndLines(gen),
      renderBorder(gen),
      renderText(id),
      fs.renderEthereum(gen)
    ));
  }
}
