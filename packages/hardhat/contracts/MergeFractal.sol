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
  function getUint8(uint256 id, uint8 startBit, uint8 bits) public view returns (uint8) {
    return uint8(generator[id] >> startBit) & masks8[bits - 1];
  }

  // TODO: make internal
  function getStr(uint256 id, uint8 startBit, uint8 bits) public view returns (string memory) {
    return ToColor.uint2str(getUint8(id, startBit, bits));
  }

  // TODO: make internal
  function getDur(uint256 id, uint8 startBit) public view returns (string memory) {
    return string(abi.encodePacked(' dur="',getStr(id, startBit, 8),'s"'));
  }

  // TODO: make internal
  function getRGBA(uint256 id, uint8 startBit, uint8 colourSection, string memory alpha) public view returns (string memory) {
    // Section should be 0, 1, 2 or 3 (0 is darkest, 3 is lightest)
    // Gives colours 0-7, 8-15, 16-23, 24-31 via idx
    uint8 idx = 8 * colourSection + getUint8(id, startBit, 3); // 3 bits = 8 colour choices
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


  // 11 bits of offset
  function renderLines(uint256 id, uint8 colourSection, uint8 startBit, string memory maxAngleText) public view returns (string memory) {
    string memory linesPath = "M 2 226 L 2 174 M 6 247 L 6 153 M 9 261 L 9 139 M 13 272 L 13 128 M 17 281 L 17 119 M 21 289 L 21 111 M 25 297 L 25 103 M 29 304 L 29 96 M 33 310 L 33 90 M 37 315 L 37 85 M 41 321 L 41 79 M 44 326 L 44 74 M 48 330 L 48 70 M 52 335 L 52 65 M 56 339 L 56 61 M 60 343 L 60 57 M 64 347 L 64 53 M 68 350 L 68 50 M 72 353 L 72 47 M 76 357 L 76 43 M 79 360 L 79 40 M 83 362 L 83 38 M 87 365 L 87 35 M 91 368 L 91 32 M 95 370 L 95 30 M 99 373 L 99 27 M 103 375 L 103 25 M 107 377 L 107 23 M 111 379 L 111 21 M 114 381 L 114 19 M 118 383 L 118 17 M 122 384 L 122 16 M 126 386 L 126 14 M 130 387 L 130 13 M 134 389 L 134 11 M 138 390 L 138 10 M 142 391 L 142 9 M 146 392 L 146 8 M 149 394 L 149 6 M 153 394 L 153 6 M 157 395 L 157 5 M 161 396 L 161 4 M 165 397 L 165 3 M 169 398 L 169 2 M 173 398 L 173 2 M 177 399 L 177 1 M 181 399 L 181 1 M 184 399 L 184 1 M 188 400 L 188 0 M 192 400 L 192 0 M 196 400 L 196 0 M 200 400 L 200 0 M 204 400 L 204 0 M 208 400 L 208 0 M 212 400 L 212 0 M 216 399 L 216 1 M 219 399 L 219 1 M 223 399 L 223 1 M 227 398 L 227 2 M 231 398 L 231 2 M 235 397 L 235 3 M 239 396 L 239 4 M 243 395 L 243 5 M 247 394 L 247 6 M 251 394 L 251 6 M 254 392 L 254 8 M 258 391 L 258 9 M 262 390 L 262 10 M 266 389 L 266 11 M 270 387 L 270 13 M 274 386 L 274 14 M 278 384 L 278 16 M 282 383 L 282 17 M 286 381 L 286 19 M 289 379 L 289 21 M 293 377 L 293 23 M 297 375 L 297 25 M 301 373 L 301 27 M 305 370 L 305 30 M 309 368 L 309 32 M 313 365 L 313 35 M 317 362 L 317 38 M 321 360 L 321 40 M 324 357 L 324 43 M 328 353 L 328 47 M 332 350 L 332 50 M 336 347 L 336 53 M 340 343 L 340 57 M 344 339 L 344 61 M 348 335 L 348 65 M 352 330 L 352 70 M 356 326 L 356 74 M 359 321 L 359 79 M 363 315 L 363 85 M 367 310 L 367 90 M 371 304 L 371 96 M 375 297 L 375 103 M 379 289 L 379 111 M 383 281 L 383 119 M 387 272 L 387 128 M 391 261 L 391 139 M 394 247 L 394 153 M 398 226 L 398 174 ";
    string memory render = '';
    {
      render = string(abi.encodePacked(
        // render,
        '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; ',
        maxAngleText,
        ' 200 200; 0 200 200"',
        getDur(id, startBit + 3),
        ' repeatCount="indefinite"/><path id="lines0" fill="none" stroke="',
        getRGBA(id, startBit, colourSection, "0.99"),
        '" stroke-width="1px" d="',
        linesPath,
        '"/></g>'
      ));
    }
    return render;     
  }

  function renderDiskAndLines(uint256 id) public view returns (string memory) {
    uint8 startBitBG = 83;
    string memory render = '';    
    render = string(abi.encodePacked(
      // render,
      renderDisk(id, startBitBG),
      renderLines(id, 0, 50, "-270"),
      renderLines(id, 1, 61, "270"),
      renderLines(id, 2, 72, "-180"),
      renderLines(id, 3, startBitBG, "180")
    ));
    return render;    
  }

  // Function visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenById(uint256 id) public view returns (string memory) {
    // string memory linesPath = "M 2 226 L 2 174 M 6 247 L 6 153 M 9 261 L 9 139 M 13 272 L 13 128 M 17 281 L 17 119 M 21 289 L 21 111 M 25 297 L 25 103 M 29 304 L 29 96 M 33 310 L 33 90 M 37 315 L 37 85 M 41 321 L 41 79 M 44 326 L 44 74 M 48 330 L 48 70 M 52 335 L 52 65 M 56 339 L 56 61 M 60 343 L 60 57 M 64 347 L 64 53 M 68 350 L 68 50 M 72 353 L 72 47 M 76 357 L 76 43 M 79 360 L 79 40 M 83 362 L 83 38 M 87 365 L 87 35 M 91 368 L 91 32 M 95 370 L 95 30 M 99 373 L 99 27 M 103 375 L 103 25 M 107 377 L 107 23 M 111 379 L 111 21 M 114 381 L 114 19 M 118 383 L 118 17 M 122 384 L 122 16 M 126 386 L 126 14 M 130 387 L 130 13 M 134 389 L 134 11 M 138 390 L 138 10 M 142 391 L 142 9 M 146 392 L 146 8 M 149 394 L 149 6 M 153 394 L 153 6 M 157 395 L 157 5 M 161 396 L 161 4 M 165 397 L 165 3 M 169 398 L 169 2 M 173 398 L 173 2 M 177 399 L 177 1 M 181 399 L 181 1 M 184 399 L 184 1 M 188 400 L 188 0 M 192 400 L 192 0 M 196 400 L 196 0 M 200 400 L 200 0 M 204 400 L 204 0 M 208 400 L 208 0 M 212 400 L 212 0 M 216 399 L 216 1 M 219 399 L 219 1 M 223 399 L 223 1 M 227 398 L 227 2 M 231 398 L 231 2 M 235 397 L 235 3 M 239 396 L 239 4 M 243 395 L 243 5 M 247 394 L 247 6 M 251 394 L 251 6 M 254 392 L 254 8 M 258 391 L 258 9 M 262 390 L 262 10 M 266 389 L 266 11 M 270 387 L 270 13 M 274 386 L 274 14 M 278 384 L 278 16 M 282 383 L 282 17 M 286 381 L 286 19 M 289 379 L 289 21 M 293 377 L 293 23 M 297 375 L 297 25 M 301 373 L 301 27 M 305 370 L 305 30 M 309 368 L 309 32 M 313 365 L 313 35 M 317 362 L 317 38 M 321 360 L 321 40 M 324 357 L 324 43 M 328 353 L 328 47 M 332 350 L 332 50 M 336 347 L 336 53 M 340 343 L 340 57 M 344 339 L 344 61 M 348 335 L 348 65 M 352 330 L 352 70 M 356 326 L 356 74 M 359 321 L 359 79 M 363 315 L 363 85 M 367 310 L 367 90 M 371 304 L 371 96 M 375 297 L 375 103 M 379 289 L 379 111 M 383 281 L 383 119 M 387 272 L 387 128 M 391 261 L 391 139 M 394 247 L 394 153 M 398 226 L 398 174 ";
    string memory render = '';
    render = string(abi.encodePacked(
      render,
      renderDiskAndLines(id)
    ));
    return render;
  }
}
