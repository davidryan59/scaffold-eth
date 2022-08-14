//SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';

import './HexStrings.sol';
import './ToColor.sol';
//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

contract MergeFractal is ERC721, Ownable {
  uint8[8] internal masks8 = [1, 3, 7, 15, 31, 63, 127, 255];
  uint8[32] internal colsR = [0,0,85,170,0,85,0,85,170,0,255,85,170,0,255,85,170,0,85,255,170,255,85,170,0,255,85,170,255,255,170,255];
  uint8[32] internal colsG = [0,0,0,0,85,85,170,0,0,85,0,85,85,170,85,170,170,255,255,0,85,85,170,170,255,170,255,255,255,170,255,255];
  uint8[32] internal colsB = [0,170,85,0,85,0,0,255,170,255,85,170,85,170,0,85,0,85,0,255,255,170,255,170,255,85,170,85,0,255,255,170];
  uint8[32] internal durations = [31,53,73,103,137,167,197,233,37,59,79,107,139,173,199,239,41,61,83,109,149,179,211,241,43,67,89,113,151,181,223,251];
  uint8[4] internal sectionColStartBits = [50, 56, 62, 68];
  uint8[4] internal sectionLineTranslates = [2, 4, 46, 48];

  using Strings for uint256;
  using HexStrings for uint160;
  using ToColor for bytes3;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  constructor() public ERC721("MergeFractals", "MERGFR") {
    // RELEASE THE MERGE FRACTALS!
  }

  mapping (uint256 => uint256) public generator;
  uint256 mintDeadline = block.timestamp + 24 hours;

  function mintItem()
      public
      returns (uint256)
  {
      require( block.timestamp < mintDeadline, "DONE MINTING");
      _tokenIds.increment();
      uint256 id = _tokenIds.current();
      _mint(msg.sender, id);
      generator[id] = uint256(keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this), id)));
      return id;
  }

  // TODO: remove this, testing only
  function getGenTEMP(uint256 id) public view returns (uint256) {
    return generator[id];
  }

  // TODO: make internal
  // Get up to 8 pseudorandom bits from the 256-bit pseudorandom generator
  function getUint8(uint256 id, uint8 startBit, uint8 bits) public view returns (uint8) {
    return uint8(generator[id] >> startBit) & masks8[bits - 1];
  }

  // TODO: make internal
  function getDur(uint256 id, uint8 startBit, uint8 arraySection) public view returns (string memory) {
    uint8 idx = 8 * arraySection + getUint8(id, startBit, 3); // 3 bits = 8 duration choices
    return string(abi.encodePacked(
      ' dur="',
      ToColor.uint2str(durations[idx]),
      's"'
    ));
  }

  // TODO: make internal
  function getRGBA(uint256 id, uint8 startBit, uint8 arraySection, string memory alpha) public view returns (string memory) {
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

  function tokenURI(uint256 id) public view override returns (string memory) {
    require(_exists(id), "not exist");
    string memory name = string(abi.encodePacked('Merge Fractal #',id.toString()));
    string memory description = string(abi.encodePacked('This Merge Fractal is the color #F00!!!'));
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
        '", "attributes": [{"trait_type": "color", "value": "#F00"}], "owner":"',
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

  function renderDisk(uint256 id, uint8 startBit) public view returns (string memory) {
    string memory render = '';
    render = string(abi.encodePacked(
      // render,
      '<circle fill="',
      getRGBA(id, startBit, 3, "1"),
      '" cx="200" cy="200" r="200"/>'
    ));
    return render;    
  }

  function getLinesTransform(uint8 arraySection) public view returns (string memory) {
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

  // Uses 6 random bits
  function renderLines(uint256 id, uint8 startBit, uint8 arraySection, string memory maxAngleText) public view returns (string memory) {
    string memory rgba = getRGBA(id, startBit, arraySection, "0.90");
    string memory linesPath = ' d="M 11 1145 L 11 855 M 32 1251 L 32 749 M 53 1322 L 53 678 M 74 1379 L 74 621 M 96 1427 L 96 573 M 117 1469 L 117 531 M 138 1507 L 138 493 M 160 1542 L 160 458 M 181 1574 L 181 426 M 202 1603 L 202 397 M 223 1630 L 223 370 M 245 1655 L 245 345 M 266 1679 L 266 321 M 287 1701 L 287 299 M 309 1722 L 309 278 M 330 1742 L 330 258 M 351 1761 L 351 239 M 372 1778 L 372 222 M 394 1795 L 394 205 M 415 1811 L 415 189 M 436 1826 L 436 174 M 457 1840 L 457 160 M 479 1853 L 479 147 M 500 1866 L 500 134 M 521 1878 L 521 122 M 543 1889 L 543 111 M 564 1900 L 564 100 M 585 1910 L 585 90 M 606 1919 L 606 81 M 628 1928 L 628 72 M 649 1936 L 649 64 M 670 1944 L 670 56 M 691 1951 L 691 49 M 713 1958 L 713 42 M 734 1964 L 734 36 M 755 1970 L 755 30 M 777 1975 L 777 25 M 798 1979 L 798 21 M 819 1984 L 819 16 M 840 1987 L 840 13 M 862 1990 L 862 10 M 883 1993 L 883 7 M 904 1995 L 904 5 M 926 1997 L 926 3 M 947 1999 L 947 1 M 968 1999 L 968 1 M 989 2000 L 989 0 M 1011 2000 L 1011 0 M 1032 1999 L 1032 1 M 1053 1999 L 1053 1 M 1074 1997 L 1074 3 M 1096 1995 L 1096 5 M 1117 1993 L 1117 7 M 1138 1990 L 1138 10 M 1160 1987 L 1160 13 M 1181 1984 L 1181 16 M 1202 1979 L 1202 21 M 1223 1975 L 1223 25 M 1245 1970 L 1245 30 M 1266 1964 L 1266 36 M 1287 1958 L 1287 42 M 1309 1951 L 1309 49 M 1330 1944 L 1330 56 M 1351 1936 L 1351 64 M 1372 1928 L 1372 72 M 1394 1919 L 1394 81 M 1415 1910 L 1415 90 M 1436 1900 L 1436 100 M 1457 1889 L 1457 111 M 1479 1878 L 1479 122 M 1500 1866 L 1500 134 M 1521 1853 L 1521 147 M 1543 1840 L 1543 160 M 1564 1826 L 1564 174 M 1585 1811 L 1585 189 M 1606 1795 L 1606 205 M 1628 1778 L 1628 222 M 1649 1761 L 1649 239 M 1670 1742 L 1670 258 M 1691 1722 L 1691 278 M 1713 1701 L 1713 299 M 1734 1679 L 1734 321 M 1755 1655 L 1755 345 M 1777 1630 L 1777 370 M 1798 1603 L 1798 397 M 1819 1574 L 1819 426 M 1840 1542 L 1840 458 M 1862 1507 L 1862 493 M 1883 1469 L 1883 531 M 1904 1427 L 1904 573 M 1926 1379 L 1926 621 M 1947 1322 L 1947 678 M 1968 1251 L 1968 749 M 1989 1145 L 1989 855 "';
    string memory render = '';
    render = string(abi.encodePacked(
      // render,
      '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; ',
      maxAngleText,
      ' 200 200; 0 200 200"',
      getDur(id, startBit + 3, arraySection),
      ' repeatCount="indefinite"/><path fill="none" stroke-linecap="round" stroke="',
      rgba,
      '" stroke-width="9px"',
      linesPath,
      getLinesTransform(arraySection),
      '/></g>'
    ));

    // -------------------------------
    // TEMP RECTANGLES TO TEST COLOURS
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
    // -------------------------------

    return render;     
  }

  function renderDiskAndLines(uint256 id) public view returns (string memory) {
    string memory render = '';    
    render = string(abi.encodePacked(
      // render,
      renderDisk(id, sectionColStartBits[3]),
      renderLines(id, sectionColStartBits[0], 0, "-270"),
      renderLines(id, sectionColStartBits[1], 1, "270"),
      renderLines(id, sectionColStartBits[2], 2, "-180"),
      renderLines(id, sectionColStartBits[3], 3, "180")
    ));
    return render;    
  }

  function renderBorder(uint256 id) public view returns (string memory) {
    string memory rgba0 = getRGBA(id, sectionColStartBits[0], 0, "0.9");
    string memory rgba3 = getRGBA(id, sectionColStartBits[3], 3, "0.8");
    string memory render = '';    
    render = string(abi.encodePacked(
      // render,
      '<circle r="175" stroke-width="38px" stroke="',
      rgba3,
      '" fill="none" cx="200" cy="200"/>',
      '<circle r="197" stroke-width="6px" stroke="',
      rgba0,
      '" fill="none" cx="200" cy="200"/>',
      '<circle r="153" stroke-width="6px" stroke="',
      rgba0,
      '" fill="none" cx="200" cy="200"/>'
    ));

    // // TEMP to switch off borders temporarily
    // render = '';

    return render;    
  }

  // Function visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenById(uint256 id) public view returns (string memory) {
    // string memory linesPath = "M 2 226 L 2 174 M 6 247 L 6 153 M 9 261 L 9 139 M 13 272 L 13 128 M 17 281 L 17 119 M 21 289 L 21 111 M 25 297 L 25 103 M 29 304 L 29 96 M 33 310 L 33 90 M 37 315 L 37 85 M 41 321 L 41 79 M 44 326 L 44 74 M 48 330 L 48 70 M 52 335 L 52 65 M 56 339 L 56 61 M 60 343 L 60 57 M 64 347 L 64 53 M 68 350 L 68 50 M 72 353 L 72 47 M 76 357 L 76 43 M 79 360 L 79 40 M 83 362 L 83 38 M 87 365 L 87 35 M 91 368 L 91 32 M 95 370 L 95 30 M 99 373 L 99 27 M 103 375 L 103 25 M 107 377 L 107 23 M 111 379 L 111 21 M 114 381 L 114 19 M 118 383 L 118 17 M 122 384 L 122 16 M 126 386 L 126 14 M 130 387 L 130 13 M 134 389 L 134 11 M 138 390 L 138 10 M 142 391 L 142 9 M 146 392 L 146 8 M 149 394 L 149 6 M 153 394 L 153 6 M 157 395 L 157 5 M 161 396 L 161 4 M 165 397 L 165 3 M 169 398 L 169 2 M 173 398 L 173 2 M 177 399 L 177 1 M 181 399 L 181 1 M 184 399 L 184 1 M 188 400 L 188 0 M 192 400 L 192 0 M 196 400 L 196 0 M 200 400 L 200 0 M 204 400 L 204 0 M 208 400 L 208 0 M 212 400 L 212 0 M 216 399 L 216 1 M 219 399 L 219 1 M 223 399 L 223 1 M 227 398 L 227 2 M 231 398 L 231 2 M 235 397 L 235 3 M 239 396 L 239 4 M 243 395 L 243 5 M 247 394 L 247 6 M 251 394 L 251 6 M 254 392 L 254 8 M 258 391 L 258 9 M 262 390 L 262 10 M 266 389 L 266 11 M 270 387 L 270 13 M 274 386 L 274 14 M 278 384 L 278 16 M 282 383 L 282 17 M 286 381 L 286 19 M 289 379 L 289 21 M 293 377 L 293 23 M 297 375 L 297 25 M 301 373 L 301 27 M 305 370 L 305 30 M 309 368 L 309 32 M 313 365 L 313 35 M 317 362 L 317 38 M 321 360 L 321 40 M 324 357 L 324 43 M 328 353 L 328 47 M 332 350 L 332 50 M 336 347 L 336 53 M 340 343 L 340 57 M 344 339 L 344 61 M 348 335 L 348 65 M 352 330 L 352 70 M 356 326 L 356 74 M 359 321 L 359 79 M 363 315 L 363 85 M 367 310 L 367 90 M 371 304 L 371 96 M 375 297 L 375 103 M 379 289 L 379 111 M 383 281 L 383 119 M 387 272 L 387 128 M 391 261 L 391 139 M 394 247 L 394 153 M 398 226 L 398 174 ";
    string memory render = '';
    render = string(abi.encodePacked(
      // render,
      renderDiskAndLines(id),
      renderBorder(id)
    ));
    return render;
  }
}
