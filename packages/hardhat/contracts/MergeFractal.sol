//SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';
// Learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

import './HexStrings.sol';
import './ToColor.sol';

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

  uint8[8] internal masks8 = [1, 3, 7, 15, 31, 63, 127, 255];
  uint8[32] internal colsR = [0,0,85,170,0,85,0,85,170,0,255,85,170,0,255,85,170,0,85,255,170,255,85,170,0,255,85,170,255,255,170,255];
  uint8[32] internal colsG = [0,0,0,0,85,85,170,0,0,85,0,85,85,170,85,170,170,255,255,0,85,85,170,170,255,170,255,255,255,170,255,255];
  uint8[32] internal colsB = [0,170,85,0,85,0,0,255,170,255,85,170,85,170,0,85,0,85,0,255,255,170,255,170,255,85,170,85,0,255,255,170];
  uint8[32] internal durations = [31,53,73,103,137,167,197,233,37,59,79,107,139,173,199,239,41,61,83,109,149,179,211,241,43,67,89,113,151,181,223,251];
  uint8[4] internal sectionColStartBits = [50, 56, 62, 68]; // Uses 3 bits for colour, 3 bits for duration
  uint8[4] internal sectionLineTranslates = [2, 4, 36, 38];

  // Random core dev and team to thank
  uint8 internal constant CORE_DEV_START_BIT = 0; // Uses 8 bits
  uint8 internal constant CORE_DEV_ARRAY_LEN = 120;
  string[CORE_DEV_ARRAY_LEN] internal coreDevNames = ['Vitalik','donations.0xSplits.eth','Artem Vorotnikov','Parithosh Jayanthi','Rafael Matias','Guillaume Ballet','Jared Wasinger','Marius van der Wijden','Matt Garnett','Peter Szilagyi','Andrei Maiboroda','Jose Hugo de la cruz Romero','Paweł Bylica','Andrew Day','Gabriel','Holger Drewes','Jochem','Scotty Poi','Jacob Kaufmann','Jason Carver','Mike Ferris','Ognyan Genev','Piper Merriam','Danny Ryan','Tim Beiko','Trenton Van Epps','Aditya Asgaonkar','Alex Stokes','Ansgar Dietrichs','Antonio Sanso','Carl Beekhuizen','Dankrad Feist','Dmitry Khovratovich','Francesco d’Amato','George Kadianakis','Hsiao Wei Wang','Justin Drake','Mark Simkin','Proto','Zhenfei Zhang','Anders','Barnabé Monnot','Caspar Schwarz-Schilling','David Theodore','Fredrik Svantes','Justin Traglia','Tyler Holmes','Yoav Weiss','Alex Beregszaszi','Harikrishnan Mulackal','Kaan Uzdogan','Kamil Sliwak','Leonardo de Sa Alt','Mario Vega','Andrey Ashikhmin','Enrique Avila Asapche','Giulio Rebuffo','Michelangelo Riccobene','Tullio Canepa','Pooja Ranjan','Daniel Lehrner','Danno Ferrin','Gary Schulte','Jiri Peinlich','Justin Florentine','Karim Taam','Guru','Jim McDonald','Peter Davies','Adrian Manning','Diva Martínez','Mac Ladson','Mark Mackey','Mehdi Zerouali','Michael Sproul','Paul Hauner','Pawan Dhananjay Ravi','Sean Anderson','Cayman Nava','Dadepo Aderemi','dapplion','Gajinder Singh','Phil Ngo','Tuyen Nguyen','Daniel Caleda','Jorge Mederos','Łukasz Rozmej','Marcin Sobczak','Marek Moraczyński','Mateusz Jędrzejewski','Tanishq','Tomasz Stanzeck','James He','Kasey Kirkham','Nishant Das','potuz','Preston Van Loon','Radosław Kapka','Raul Jordan','Taran Singh','Terence Tsao','Sam Wilson','Dustin Brody','Etan Kissling','Eugene Kabanov','Jacek Sieka','Jordan Hrycaj','Kim De Mey','Konrad Staniec','Mamy Ratsimbazafy','Zahary Karadzhov','Adrian Sutton','Ben Edgington','Courtney Hunter','Dmitry Shmatko','Enrico Del Fante','Paul Harris','Alex Vlasov','Anton Nashatyrev','Mikhail Kalinin'];
  uint8[CORE_DEV_ARRAY_LEN] internal coreDevTeamIndices = [0,1,2,3,3,4,4,4,4,4,5,5,5,6,6,6,6,6,7,7,7,7,7,8,8,8,9,9,9,9,9,9,9,9,9,9,9,9,9,9,10,10,10,11,11,11,11,11,12,12,12,12,12,13,14,14,14,14,14,15,16,16,16,16,16,16,0,0,0,17,17,17,17,17,17,17,17,17,18,18,18,18,18,18,19,19,19,19,19,19,19,19,20,20,20,20,20,20,20,20,20,21,22,22,22,22,22,22,22,22,22,23,23,23,23,23,23,24,24,24];
  uint8 internal constant TEAM_ARRAY_LEN = 25;
  string[TEAM_ARRAY_LEN] internal teams = ['Independent','0xSplits','Akula','EF DevOps','EF Geth','EF Ipsilon','EF JavaScript','EF Portal','EF Protocol Support','EF Research','EF Robust Incentives Group','EF Security','EF Solidity','EF Testing','Erigon','Ethereum Cat Herders','Hyperledger Besu','Lighthouse','Lodestar','Nethermind','Prysmatic','Quilt','Status','Teku','TXRX'];

  // Random saying
  uint8 internal constant SAYING_START_BIT = 8; // Uses 8 bits
  uint8 internal constant SAYING_ARRAY_LEN = 19;
  string[SAYING_ARRAY_LEN] internal sayings = ['PoS > PoW','Environmentally friendly at last','The Flippening','Decentralise Everything','Energy consumption -99.95%','Unstoppable smart contracts','Run your own node','TTD 58750000000000000000000','TTD 5.875 * 10^22','TTD 2^19 * 5^22 * 47','Validate with 32 ETH','Validators > Miners','Sustainable and secure','Proof-of-stake consensus','World Computer','Permissionless','Vitalik is clapping','Vitalik is dancing','Anthony Sassano is dancing'];

  using Strings for uint256;
  using HexStrings for uint160;
  using ToColor for bytes3;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  constructor() public ERC721("MergeFractals", "MERGFR") {
    // RELEASE THE MERGE FRACTALS!
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
    return uint8(generator[id] >> startBit) & masks8[bits - 1];
  }

  function getRGBA(uint256 id, uint8 arraySection, string memory alpha) internal view returns (string memory) {
    uint8 startBit = sectionColStartBits[arraySection];
    // Array section values are 0, 1, 2 or 3 (0 is darkest, 3 is lightest)
    // These sections give colours 0-7, 8-15, 16-23, 24-31
    uint8 idx = 8 * arraySection + getUint8(id, startBit, 3); // 3 bits = 8 colour choices
    return string(abi.encodePacked(
      'rgba(',
      ToColor.uint2str(colsR[idx]),
      ',',
      ToColor.uint2str(colsG[idx]),
      ',',
      ToColor.uint2str(colsB[idx]),
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
        (uint160(ownerOf(id))).toHexString(20),
        '", "image": "data:image/svg+xml;base64,',
        image,
        '"}'
      )))
    ));
  }

  function generateSVGofTokenById(uint256 id) internal view returns (string memory) {
    string memory svg = string(abi.encodePacked(
      '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
        renderTokenById(id),
      '</svg>'
    ));
    return svg;
  }

  function renderDisk(uint256 id) internal view returns (string memory) {
    string memory render = '';
    render = string(abi.encodePacked(
      // render,
      '<circle fill="',
      getRGBA(id, 3, "1"),
      '" cx="200" cy="200" r="200"/>'
    ));
    return render;    
  }

  function getLinesTransform(uint8 arraySection) internal view returns (string memory) {
    uint8 num1 = sectionLineTranslates[arraySection];
    uint16 num2 = 200 - num1;
    string memory render = '';
    render = string(abi.encodePacked(
      // render,
      ' transform="translate(',
      ToColor.uint2str(num1),
      ' ',
      ToColor.uint2str(num1),
      ') scale(0.',
      ToColor.uint2str(num2),
      ')"'
    ));
    return render;    
  }

  function getDur(uint256 id, uint8 arraySection) internal view returns (string memory) {
    uint8 startBitDur = sectionColStartBits[arraySection] + 3;
    uint8 idx = 8 * arraySection + getUint8(id, startBitDur, 3); // 3 bits = 8 duration choices
    return string(abi.encodePacked(
      ' dur="',
      ToColor.uint2str(durations[idx]),
      's"'
    ));
  }

  // Uses 6 random bits
  function renderLines(uint256 id, uint8 arraySection, string memory maxAngleText) internal view returns (string memory) {
    string memory rgba = getRGBA(id, arraySection, "0.90");
    string memory linesPath = ' d="M 11 1145 L 11 855 M 32 1251 L 32 749 M 53 1322 L 53 678 M 74 1379 L 74 621 M 96 1427 L 96 573 M 117 1469 L 117 531 M 138 1507 L 138 493 M 160 1542 L 160 458 M 181 1574 L 181 426 M 202 1603 L 202 397 M 223 1630 L 223 370 M 245 1655 L 245 345 M 266 1679 L 266 321 M 287 1701 L 287 299 M 309 1722 L 309 278 M 330 1742 L 330 258 M 351 1761 L 351 239 M 372 1778 L 372 222 M 394 1795 L 394 205 M 415 1811 L 415 189 M 436 1826 L 436 174 M 457 1840 L 457 160 M 479 1853 L 479 147 M 500 1866 L 500 134 M 521 1878 L 521 122 M 543 1889 L 543 111 M 564 1900 L 564 100 M 585 1910 L 585 90 M 606 1919 L 606 81 M 628 1928 L 628 72 M 649 1936 L 649 64 M 670 1944 L 670 56 M 691 1951 L 691 49 M 713 1958 L 713 42 M 734 1964 L 734 36 M 755 1970 L 755 30 M 777 1975 L 777 25 M 798 1979 L 798 21 M 819 1984 L 819 16 M 840 1987 L 840 13 M 862 1990 L 862 10 M 883 1993 L 883 7 M 904 1995 L 904 5 M 926 1997 L 926 3 M 947 1999 L 947 1 M 968 1999 L 968 1 M 989 2000 L 989 0 M 1011 2000 L 1011 0 M 1032 1999 L 1032 1 M 1053 1999 L 1053 1 M 1074 1997 L 1074 3 M 1096 1995 L 1096 5 M 1117 1993 L 1117 7 M 1138 1990 L 1138 10 M 1160 1987 L 1160 13 M 1181 1984 L 1181 16 M 1202 1979 L 1202 21 M 1223 1975 L 1223 25 M 1245 1970 L 1245 30 M 1266 1964 L 1266 36 M 1287 1958 L 1287 42 M 1309 1951 L 1309 49 M 1330 1944 L 1330 56 M 1351 1936 L 1351 64 M 1372 1928 L 1372 72 M 1394 1919 L 1394 81 M 1415 1910 L 1415 90 M 1436 1900 L 1436 100 M 1457 1889 L 1457 111 M 1479 1878 L 1479 122 M 1500 1866 L 1500 134 M 1521 1853 L 1521 147 M 1543 1840 L 1543 160 M 1564 1826 L 1564 174 M 1585 1811 L 1585 189 M 1606 1795 L 1606 205 M 1628 1778 L 1628 222 M 1649 1761 L 1649 239 M 1670 1742 L 1670 258 M 1691 1722 L 1691 278 M 1713 1701 L 1713 299 M 1734 1679 L 1734 321 M 1755 1655 L 1755 345 M 1777 1630 L 1777 370 M 1798 1603 L 1798 397 M 1819 1574 L 1819 426 M 1840 1542 L 1840 458 M 1862 1507 L 1862 493 M 1883 1469 L 1883 531 M 1904 1427 L 1904 573 M 1926 1379 L 1926 621 M 1947 1322 L 1947 678 M 1968 1251 L 1968 749 M 1989 1145 L 1989 855 "';
    string memory render = '';
    render = string(abi.encodePacked(
      // render,
      '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; ',
      maxAngleText,
      ' 200 200; 0 200 200"',
      getDur(id, arraySection),
      ' repeatCount="indefinite"/><path fill="none" stroke-linecap="round" stroke="',
      rgba,
      '" stroke-width="9px"',
      linesPath,
      getLinesTransform(arraySection),
      '/></g>'
    ));

    // -------------------------------
    // TEMP RECTANGLES TO TEST COLOURS
    if (IS_TESTNET) {
      uint16 x = arraySection >> 1 == 0 ? 0 : 350;
      uint16 y = arraySection % 2 == 1 ? 0 : 350;
      render = string(abi.encodePacked(
        render,
        '<rect x="',
        ToColor.uint2str(x),
        '" y="',
        ToColor.uint2str(y),
        '" width="50" height="50" rx="15" fill="',
        rgba,
        '"/>'
      ));
    }
    // -------------------------------

    return render;     
  }

  function renderDiskAndLines(uint256 id) internal view returns (string memory) {
    string memory render = '';    
    render = string(abi.encodePacked(
      // render,
      renderDisk(id),
      renderLines(id, 0, "-270"),
      renderLines(id, 1, "270"),
      renderLines(id, 2, "-180"),
      renderLines(id, 3, "180")
    ));
    return render;    
  }

  function renderBorder(uint256 id) internal view returns (string memory) {
    string memory rgba0 = getRGBA(id, 0, "0.9");
    string memory rgba3 = getRGBA(id, 3, "0.8");
    string memory render = '';    
    render = string(abi.encodePacked(
      // render,
      '<circle r="180" stroke-width="28px" stroke="',
      rgba3,
      '" fill="none" cx="200" cy="200"/>',
      '<circle r="197" stroke-width="6px" stroke="',
      rgba0,
      '" fill="none" cx="200" cy="200"/>',
      '<circle r="163" stroke-width="6px" stroke="',
      rgba0,
      '" fill="none" cx="200" cy="200"/>'
    ));
    return render;    
  }

  function getCoreDevIdx(uint256 id) internal view returns (uint8 idx) {
    return getUint8(id, CORE_DEV_START_BIT, 8) % CORE_DEV_ARRAY_LEN;
  }

  function getTeamIdx(uint256 id) internal view returns (uint8 idx) {
    return coreDevTeamIndices[getCoreDevIdx(id)];
  }

  function getCoreDevName(uint256 id) internal view returns (string memory) {
    return coreDevNames[getCoreDevIdx(id)];
  }

  function getTeamName(uint256 id) internal view returns (string memory) {
    return teams[getTeamIdx(id)];
  }

  function getCoreDevAndTeamText(uint256 id) internal view returns (string memory) {
    uint8 devIdx = getCoreDevIdx(id);
    uint8 teamIdx = getTeamIdx(id);
    string memory teamText = string(abi.encodePacked(' and ', getTeamName(id)));
    if (devIdx == 0) { // Dev = Vitalik
      teamText = string(abi.encodePacked(' for Ethereum'));
    } else if (teamIdx == 0) { // Team = Individual
      teamText = '';
    }
    string memory render = '';    
    render = string(abi.encodePacked(
      // render,
      'Thank you ',
      getCoreDevName(id),
      teamText
    ));
    return render;       
  }

  function getSaying(uint256 id) internal view returns (string memory) {
    return sayings[getUint8(id, SAYING_START_BIT, 8) % SAYING_ARRAY_LEN];
  }

  function renderText(uint256 id) internal view returns (string memory) {
    string memory rgba0 = getRGBA(id, 0, "1");
    string memory render = '';    
    render = string(abi.encodePacked(
      // render,
      '<defs><style>text{font-size:15px;font-family:Helvetica,sans-serif;font-weight:900;fill:',
      rgba0,
      ';letter-spacing:1px}</style><path id="textcircle" fill="none" stroke="rgba(255,0,0,0.5)" d="M 196 375 A 175 175 270 1 1 375 200 A 175 175 90 0 1 204 375" /></defs>',
      '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; 360 200 200" dur="120s" repeatCount="indefinite"/><text><textPath href="#textcircle">/ ',
      NETWORK,
      ' Merge Fractal #',
      ToColor.uint2str(id),
      ' / ',
      getCoreDevAndTeamText(id),
      '! / ',
      getSaying(id),
      ' / Minted by ',
      (uint160(mintooor[id])).toHexString(20),
      '♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦♢♦</textPath></text></g>'
    ));
    return render;    
  }

  function renderEthereum(uint256 id) internal view returns (string memory) {
    string memory rgbaLineF = getRGBA(id, 1, "0.80");
    string memory rgbaFillF = getRGBA(id, 1, "0.65");
    string memory rgbaFillG = getRGBA(id, 2, "0.65");
    string memory rgbaLineG = getRGBA(id, 2, "0.80");
    string memory render = '';    
    render = string(abi.encodePacked(
      // render,
      '<defs><rect id="f0" x="-0.5" y="-0.5" width="1" height="1" stroke="',rgbaLineF,'" fill="',rgbaFillF,'" stroke-width="0.05"/></defs>',
      '<defs><rect id="g0" x="-0.5" y="-0.5" width="1" height="1" stroke="',rgbaLineG,'" fill="',rgbaFillG,'" stroke-width="0.05"/></defs>',
      '<use href="#f0" transform="translate(125, 200) scale(95, 170) rotate(45)"/>',
      '<use href="#g0" transform="translate(275, 200) scale(95, 170) rotate(45)"/>'
    ));
    return render;    
  }

  // Function visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenById(uint256 id) public view returns (string memory) {
    string memory render = '';
    render = string(abi.encodePacked(
      // render,
      renderDiskAndLines(id),
      renderBorder(id),
      renderText(id),
      renderEthereum(id)
    ));
    return render;
  }
}
