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

  // mapping (uint256 => bool) public iteration2ternary;
  // mapping (uint256 => bool) public iteration3ternary;
  // mapping (uint256 => bool) public rotatoor;

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

      // bytes32 predictableRandom = keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this), id ));
      // generator[id] = predictableRandom;


      // color3[id] = bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[1]) >> 8 ) | ( bytes3(predictableRandom[2]) >> 16 );
      // iteration2ternary[id] = uint8(predictableRandom[3]) & 0x1 == 1;
      // iteration3ternary[id] = uint8(predictableRandom[3]) & 0x2 == 2;
      // rotatoor[id] = uint8(predictableRandom[3]) & 0x4 == 4;
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
  function getRGBA(uint256 id, uint8 startBit, uint8 section, string memory alpha) public view returns (string memory) {
    // section should be 0, 1, 2 or 3
    // Gives colours 0-7, 8-15, 16-23, 24-31 via idx
    uint8 idx = 8 * section + getUint8(id, startBit, 3); // 3 bits = 8 colour choices
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

      return
          string(
              abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                          abi.encodePacked(
                              '{"name":"',
                              name,
                              '", "description":"',
                              description,
                              '", "external_url":"https://burnyboys.com/token/',
                              id.toString(),
                              '", "attributes": [{"trait_type": "color", "value": "#',
                              'F00',
                              // color1[id].toColor(),
                              '"}], "owner":"',
                              (uint160(ownerOf(id))).toHexString(20),
                              '", "image": "data:image/svg+xml;base64,',
                              image,
                              '"}'
                          )
                        )
                    )
              )
          );
  }

  function generateSVGofTokenById(uint256 id) internal view returns (string memory) {
    string memory svg = string(abi.encodePacked(
      '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
        renderTokenById(id),
      '</svg>'
    ));
    return svg;
  }

  // function getIteration0Line(
  //   string memory label,
  //   string memory transl,
  //   string memory x,
  //   string memory y
  // ) private pure returns (string memory) {
  //   return string(abi.encodePacked(
  //     '<g>',
  //       '<animateTransform attributeName="transform" attributeType="XML" type="translate" values="0; ',transl,'; 0" dur="10s" repeatCount="indefinite" additive="sum"/>',
  //       '<animateTransform attributeName="transform" attributeType="XML" type="scale" values="1 1; 0.5 1; 1 1" dur="10s" repeatCount="indefinite" additive="sum"/>',
  //       '<use href="#',label,'0" x="',x,'" y="',y,'"/>',
  //     '</g>'
  //   ));
  // }

  // function makeNextIteration4Square(
  //   uint256 id,
  //   string memory label,
  //   string memory thisIt,
  //   string memory prevIt
  // ) private view returns (string memory) {
  //   string memory labelThisIt = string(abi.encodePacked(label, thisIt));
  //   string memory labelPrevIt = string(abi.encodePacked(label, prevIt));
  //   return string(abi.encodePacked(
  //     '<g id="',labelThisIt,'" transform="scale(0.5)">',
  //       rotatoor[id]?'<animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0; -90; 0" dur="10s" repeatCount="indefinite" additive="sum"/>':'',
  //       '<use href="#',labelPrevIt,'" x="-0.5" y=" 0.5"/>',
  //       '<use href="#',labelPrevIt,'" x=" 0.5" y=" 0.5"/>',
  //       '<use href="#',labelPrevIt,'" x="-0.5" y="-0.5"/>',
  //       '<g transform="rotate(0 0.5 -0.5)"><use href="#',labelPrevIt,'" x=" 0.5" y="-0.5"/></g>',
  //     '</g>'
  //   ));
  // }

  // function makeNextIteration9Square(
  //   uint256 id,
  //   string memory label,
  //   string memory thisIt,
  //   string memory prevIt
  // ) private view returns (string memory) {
  //   string memory labelThisIt = string(abi.encodePacked(label, thisIt));
  //   string memory labelPrevIt = string(abi.encodePacked(label, prevIt));
  //   return string(abi.encodePacked(
  //     '<g id="',labelThisIt,'" transform="scale(0.3333)">',
  //       rotatoor[id]?'<animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0; 90; 0" dur="10s" repeatCount="indefinite" additive="sum"/>':'',
  //       '<use href="#',labelPrevIt,'" x="-1" y=" 1"/>',
  //       '<use href="#',labelPrevIt,'" x=" 0" y=" 1"/>',
  //       '<g transform="rotate(0 1 1)"><use href="#',labelPrevIt,'" x=" 1" y=" 1"/></g>',
  //       '<g transform="rotate(0 -1 0)"><use href="#',labelPrevIt,'" x="-1" y=" 0"/></g>',
  //       '<g transform="rotate(0 0 0)"><use href="#',labelPrevIt,'" x=" 0" y=" 0"/></g>',
  //       '<use href="#',labelPrevIt,'" x=" 1" y=" 0"/>',
  //       '<use href="#',labelPrevIt,'" x="-1" y="-1"/>',
  //       '<use href="#',labelPrevIt,'" x=" 0" y="-1"/>',
  //       '<use href="#',labelPrevIt,'" x=" 1" y="-1"/>',
  //     '</g>'
  //   ));
  // }

  // function getFractal(
  //   uint256 id,
  //   string memory label,
  //   string memory lineCol,
  //   string memory fillCol,
  //   string memory t1,
  //   string memory t2
  // ) private view returns (string memory) {
  //   string memory iteration0 = string(abi.encodePacked(
  //     '<rect id="',label,'0" x="-0.5" y="-0.5" width="1" height="1" stroke="',lineCol,'" fill="',fillCol,'" stroke-width="0.1"/>'
  //   ));
  //   string memory iteration1 = string(abi.encodePacked(
  //     '<g id="',label,'1" transform="scale(0.5)">',
  //       getIteration0Line(label, t1, "-0.5", " 0.5"),
  //       getIteration0Line(label, t1, " 0.5", " 0.5"),
  //       getIteration0Line(label, t2, "-0.5", "-0.5"),
  //       getIteration0Line(label, t2, " 0.5", "-0.5"),
  //     '</g>'
  //   ));
  //   string memory iteration2 = iteration2ternary[id] ? makeNextIteration9Square(id, label, "2", "1") : makeNextIteration4Square(id, label, "2", "1");
  //   string memory iteration3 = iteration3ternary[id] ? makeNextIteration9Square(id, label, "3", "2") : makeNextIteration4Square(id, label, "3", "2");
  //   return string(abi.encodePacked(
  //     iteration0,
  //     iteration1,
  //     iteration2,
  //     iteration3
  //   ));
  // }

  // Function visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenById(uint256 id) public view returns (string memory) {
    string memory linesPath = "M 2 226 L 2 174 M 6 247 L 6 153 M 9 261 L 9 139 M 13 272 L 13 128 M 17 281 L 17 119 M 21 289 L 21 111 M 25 297 L 25 103 M 29 304 L 29 96 M 33 310 L 33 90 M 37 315 L 37 85 M 41 321 L 41 79 M 44 326 L 44 74 M 48 330 L 48 70 M 52 335 L 52 65 M 56 339 L 56 61 M 60 343 L 60 57 M 64 347 L 64 53 M 68 350 L 68 50 M 72 353 L 72 47 M 76 357 L 76 43 M 79 360 L 79 40 M 83 362 L 83 38 M 87 365 L 87 35 M 91 368 L 91 32 M 95 370 L 95 30 M 99 373 L 99 27 M 103 375 L 103 25 M 107 377 L 107 23 M 111 379 L 111 21 M 114 381 L 114 19 M 118 383 L 118 17 M 122 384 L 122 16 M 126 386 L 126 14 M 130 387 L 130 13 M 134 389 L 134 11 M 138 390 L 138 10 M 142 391 L 142 9 M 146 392 L 146 8 M 149 394 L 149 6 M 153 394 L 153 6 M 157 395 L 157 5 M 161 396 L 161 4 M 165 397 L 165 3 M 169 398 L 169 2 M 173 398 L 173 2 M 177 399 L 177 1 M 181 399 L 181 1 M 184 399 L 184 1 M 188 400 L 188 0 M 192 400 L 192 0 M 196 400 L 196 0 M 200 400 L 200 0 M 204 400 L 204 0 M 208 400 L 208 0 M 212 400 L 212 0 M 216 399 L 216 1 M 219 399 L 219 1 M 223 399 L 223 1 M 227 398 L 227 2 M 231 398 L 231 2 M 235 397 L 235 3 M 239 396 L 239 4 M 243 395 L 243 5 M 247 394 L 247 6 M 251 394 L 251 6 M 254 392 L 254 8 M 258 391 L 258 9 M 262 390 L 262 10 M 266 389 L 266 11 M 270 387 L 270 13 M 274 386 L 274 14 M 278 384 L 278 16 M 282 383 L 282 17 M 286 381 L 286 19 M 289 379 L 289 21 M 293 377 L 293 23 M 297 375 L 297 25 M 301 373 L 301 27 M 305 370 L 305 30 M 309 368 L 309 32 M 313 365 L 313 35 M 317 362 L 317 38 M 321 360 L 321 40 M 324 357 L 324 43 M 328 353 L 328 47 M 332 350 L 332 50 M 336 347 L 336 53 M 340 343 L 340 57 M 344 339 L 344 61 M 348 335 L 348 65 M 352 330 L 352 70 M 356 326 L 356 74 M 359 321 L 359 79 M 363 315 L 363 85 M 367 310 L 367 90 M 371 304 L 371 96 M 375 297 L 375 103 M 379 289 L 379 111 M 383 281 L 383 119 M 387 272 L 387 128 M 391 261 L 391 139 M 394 247 L 394 153 M 398 226 L 398 174 ";
    string memory render = string(abi.encodePacked(
      '<defs><linearGradient id="linear-gradient-13" x1="96" y1="202.4" x2="150" y2="202.4" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#574581" /><stop offset="1" stop-color="#4c235b" /></linearGradient><linearGradient id="linear-gradient-19" x1="149.1" y1="24" x2="149.1" y2="276" href="#linear-gradient-13" /><clipPath id="clip-path"><path class="cls-1" d="M0-42.3h300v188.6H0z" /></clipPath><clipPath id="clip-path-2"><path class="cls-1" d="M.4 0h300v300H.4z" /></clipPath><style>.cls-1{fill:none}.cls-2{fill:url(#linear-gradient)}.cls-4{fill:url(#linear-gradient-2)}.cls-5{fill:url(#linear-gradient-3)}.cls-14{fill:url(#linear-gradient-12)}.cls-15{opacity:.2}.cls-16{clip-path:url(#clip-path-2)}.cls-17{fill:#e75a00}.cls-18{fill:url(#linear-gradient-13)}.cls-19{fill:#fff}.cls-20{fill:url(#linear-gradient-14)}.cls-21{fill:url(#linear-gradient-15)}.cls-22{fill:url(#linear-gradient-16)}.cls-23{fill:url(#linear-gradient-17)}.cls-24{fill:url(#linear-gradient-18)}.cls-25{stroke:#fff;stroke-miterlimit:10;fill:url(#linear-gradient-19)}</style><style>@keyframes ff{0%,49.9%,to{transform:translate(0,0) scale(1,1)}50%,99.9%{transform:translate(300px,0) scale(-1,1)}}#Fire1{animation:ff 300ms linear infinite normal forwards}text{font-size:16px;font-family:Helvetica,sans-serif;font-weight:900;fill:#fff;letter-spacing:1px}#Ether,#Ring,#background{filter:hue-rotate(42deg)}#Fire_to_move{transform:translate(0px,20px)}</style>',
        // getFractal(id, 'f', 'rgba(0, 0, 0, 0.75)', 'rgba(0, 0, 255, 0.5)', '-0.5', '0.5'),
        // getFractal(id, 'g', 'rgba(128, 80, 0, 0.75)', 'rgba(255, 240, 128, 0.5)', '0.5', '-0.5'),
        // '<rect id="rect_bg" x="2" y="2" rx="150" ry="150" width="396" height="396" stroke="#',color[id].toColor(),'" fill="rgba(160, 160, 160, 1)" stroke-width="5"/>',
      '<g><animateTransform attributeName="transform" attributeType="XML" type="translate" values="0; 95; 0" dur="10s" repeatCount="indefinite" additive="sum"/>',
      '<use href="#f3" transform="translate(105, 200) scale(125, 250) rotate(45)"/></g>',
      '<g><animateTransform attributeName="transform" attributeType="XML" type="translate" values="0; -95; 0" dur="10s" repeatCount="indefinite" additive="sum"/>',
        '<use href="#g3" transform="translate(295, 200) scale(125, 250) rotate(45)"/></g>',

      // '<path id="lines" fill="none" stroke="rgba(240, 180, 80, 1)" stroke-width="1px" d="M 2 230 L 2 170 M 15 277 L 15 123 M 29 303 L 29 97 M 42 322 L 42 78 M 55 338 L 55 62 M 68 350 L 68 50 M 81 361 L 81 39 M 95 370 L 95 30 M 108 377 L 108 23 M 121 384 L 121 16 M 134 389 L 134 11 M 147 393 L 147 7 M 160 396 L 160 4 M 174 398 L 174 2 M 187 400 L 187 0 M 200 400 L 200 0 M 213 400 L 213 0 M 226 398 L 226 2 M 240 396 L 240 4 M 253 393 L 253 7 M 266 389 L 266 11 M 279 384 L 279 16 M 292 377 L 292 23 M 305 370 L 305 30 M 319 361 L 319 39 M 332 350 L 332 50 M 345 338 L 345 62 M 358 322 L 358 78 M 371 303 L 371 97 M 385 277 L 385 123 M 398 230 L 398 170 " />',
      // '<path id="lines" fill="none" stroke="rgba(20,0,80, 1)" stroke-width="1px" d="M 2 230 L 2 170 M 15 277 L 15 123 M 29 303 L 29 97 M 42 322 L 42 78 M 55 338 L 55 62 M 68 350 L 68 50 M 81 361 L 81 39 M 95 370 L 95 30 M 108 377 L 108 23 M 121 384 L 121 16 M 134 389 L 134 11 M 147 393 L 147 7 M 160 396 L 160 4 M 174 398 L 174 2 M 187 400 L 187 0 M 200 400 L 200 0 M 213 400 L 213 0 M 226 398 L 226 2 M 240 396 L 240 4 M 253 393 L 253 7 M 266 389 L 266 11 M 279 384 L 279 16 M 292 377 L 292 23 M 305 370 L 305 30 M 319 361 L 319 39 M 332 350 L 332 50 M 345 338 L 345 62 M 358 322 L 358 78 M 371 303 L 371 97 M 385 277 L 385 123 M 398 230 L 398 170 " />',
      // '<path id="lines" fill="none" stroke="rgba(128,40,0,1)" stroke-width="0.4px" d="',linesPath,'"/>',

      // // YELLOW, RED, BLUE 
      // '<path id="lines1" fill="none" stroke="rgba(255,255,0,0.55)" stroke-width="1.5px" d="',linesPath,'"/>',
      // '<path id="lines3" fill="none" stroke="rgba(255,0,0,0.55)" stroke-width="1.5px" d="',linesPath,'"/>',
      // '<path id="lines2" fill="none" stroke="rgba(0,0,255,0.55)" stroke-width="1.5px" d="',linesPath,'"/>',

      // GOLDS
      '<path id="lines0" fill="none" stroke="',getRGBA(id,  88, 0, "0.55"),'" stroke-width="2px" d="',linesPath,'"/>',
      '<path id="lines1" fill="none" stroke="',getRGBA(id,  91, 1, "0.55"),'" stroke-width="2px" d="',linesPath,'"/>',
      '<path id="lines2" fill="none" stroke="',getRGBA(id,  94, 2, "0.55"),'" stroke-width="2px" d="',linesPath,'"/>',
      '<path id="lines3" fill="none" stroke="',getRGBA(id,  97, 3, "0.55"),'" stroke-width="2px" d="',linesPath,'"/>',

      // '<path id="lines2" fill="none" stroke="rgba(0,40,128,1)" stroke-width="0.4px" d="M 2 226 L 2 174 M 6 247 L 6 153 M 9 261 L 9 139 M 13 272 L 13 128 M 17 281 L 17 119 M 21 289 L 21 111 M 25 297 L 25 103 M 29 304 L 29 96 M 33 310 L 33 90 M 37 315 L 37 85 M 41 321 L 41 79 M 44 326 L 44 74 M 48 330 L 48 70 M 52 335 L 52 65 M 56 339 L 56 61 M 60 343 L 60 57 M 64 347 L 64 53 M 68 350 L 68 50 M 72 353 L 72 47 M 76 357 L 76 43 M 79 360 L 79 40 M 83 362 L 83 38 M 87 365 L 87 35 M 91 368 L 91 32 M 95 370 L 95 30 M 99 373 L 99 27 M 103 375 L 103 25 M 107 377 L 107 23 M 111 379 L 111 21 M 114 381 L 114 19 M 118 383 L 118 17 M 122 384 L 122 16 M 126 386 L 126 14 M 130 387 L 130 13 M 134 389 L 134 11 M 138 390 L 138 10 M 142 391 L 142 9 M 146 392 L 146 8 M 149 394 L 149 6 M 153 394 L 153 6 M 157 395 L 157 5 M 161 396 L 161 4 M 165 397 L 165 3 M 169 398 L 169 2 M 173 398 L 173 2 M 177 399 L 177 1 M 181 399 L 181 1 M 184 399 L 184 1 M 188 400 L 188 0 M 192 400 L 192 0 M 196 400 L 196 0 M 200 400 L 200 0 M 204 400 L 204 0 M 208 400 L 208 0 M 212 400 L 212 0 M 216 399 L 216 1 M 219 399 L 219 1 M 223 399 L 223 1 M 227 398 L 227 2 M 231 398 L 231 2 M 235 397 L 235 3 M 239 396 L 239 4 M 243 395 L 243 5 M 247 394 L 247 6 M 251 394 L 251 6 M 254 392 L 254 8 M 258 391 L 258 9 M 262 390 L 262 10 M 266 389 L 266 11 M 270 387 L 270 13 M 274 386 L 274 14 M 278 384 L 278 16 M 282 383 L 282 17 M 286 381 L 286 19 M 289 379 L 289 21 M 293 377 L 293 23 M 297 375 L 297 25 M 301 373 L 301 27 M 305 370 L 305 30 M 309 368 L 309 32 M 313 365 L 313 35 M 317 362 L 317 38 M 321 360 L 321 40 M 324 357 L 324 43 M 328 353 L 328 47 M 332 350 L 332 50 M 336 347 L 336 53 M 340 343 L 340 57 M 344 339 L 344 61 M 348 335 L 348 65 M 352 330 L 352 70 M 356 326 L 356 74 M 359 321 L 359 79 M 363 315 L 363 85 M 367 310 L 367 90 M 371 304 L 371 96 M 375 297 L 375 103 M 379 289 L 379 111 M 383 281 L 383 119 M 387 272 L 387 128 M 391 261 L 391 139 M 394 247 L 394 153 M 398 226 L 398 174 " />',
      // '<g id="sept-grid"><use href="#lines"/><use href="#lines" transform="rotate(25.71 200 200)"/><use href="#lines" transform="rotate(51.42 200 200)"/><use href="#lines" transform="rotate(77.14 200 200)"/><use href="#lines" transform="rotate(102.85 200 200)"/><use href="#lines" transform="rotate(128.57 200 200)"/><use href="#lines" transform="rotate(154.29 200 200)"/></g>',
      // '<g id="pent-grid"><use href="#lines"/><use href="#lines" transform="rotate(36 200 200)"/><use href="#lines" transform="rotate(72 200 200)"/><use href="#lines" transform="rotate(108 200 200)"/><use href="#lines" transform="rotate(144 200 200)"/></g>',
      // '<g id="tri-grid"><use href="#lines"/><use href="#lines" transform="rotate(120 200 200)"/><use href="#lines" transform="rotate(240 200 200)"/></g>',
      // '<g id="sq-grid"><use href="#lines"/><use href="#lines" transform="rotate(90 200 200)"/></g>',

      // '<text dy="0"><textPath href="#textcircle2"><animate attributeName="startOffset" from="0%" to="80%" begin="0s" dur="10s" repeatCount="indefinite" /> / EIP-1559 / #1559 / Basefee: 8.68 Gwei / 0xabcdabcdabcdabcdabcdabcdabcdabcd bum pants bum pants</textPath></text>',
      
      '</defs>',

      // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; -37 200 200; 0 200 200" dur="29s" repeatCount="indefinite" additive="sum"/><path id="textcircle4" fill="rgba(0, 0, 255, 0.8)" stroke="none" d="M 330 200 C 355 213 339 225 368 247 365 264 339 267 351 291 338 301 326 312 288 296 293 318 293 347 278 347 252 329 251 366 233 357 216 340 204 342 188 363 178 337 161 354 155 326 133 343 119 341 112 323 85 334 73 324 73 303 54 300 51 283 53 263 59 247 35 239 66 219 42 207 32 194 64 182 49 166 40 147 70 144 67 127 90 127 98 116 93 95 85 67 124 93 114 53 142 72 153 70 160 40 177 52 191 63 203 28 216 52 228 70 251 36 263 43 274 59 282 73 288 88 314 79 329 83 333 100 323 124 345 130 360 139 333 162 363 169 344 186 330 200 " /></g>',
      // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; -41 200 200; 0 200 200" dur="37s" repeatCount="indefinite" additive="sum"/><path id="textcircle5" fill="none" stroke="rgba(255, 255, 0, 0.8)" stroke-width="10px" stroke-linecap="round" d="M 270 200 C 276 238 261 272 216 278 187 243 122 296 125 237 175 200 56 129 180 173 187 121 220 124 234 161 331 145 256 203 307 266 286 332 207 245 163 317 166 233 190 204 157 195 64 113 187 177 195 147 245 88 284 128 308 165 229 205 333 304 281 342 201 245 133 340 117 264 61 232 45 162 96 109 184 164 200 184 235 132 288 138 303 181 266 222 281 270 241 298 196 245 160 274 180 213 172 204 76 159 165 163 179 137 201 191 210 186 334 123 259 197 280 232 222 224 202 208 199 208 171 239 140 231 158 202 129 169 184 179 174 78 209 154 270 110 335 135 270 200 " /></g>',
      // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; 23 200 200; 0 200 200" dur="23s" repeatCount="indefinite" additive="sum"/><path id="textcircle2" fill="none" stroke="rgba(0, 0, 0, 0.75)" stroke-width="50px" stroke-linecap="round" d="M 343 203 C 335 237 307 264 290 300 271 339 237 360 192 317 141 363 129 306 103 275 82 249 60 218 90 184 88 150 44 78 122 95 135 6 188 39 239 23 283 32 335 61 302 140 375 150 353 199 385 257 309 263 333 344 292 378 234 372 187 388 141 366 116 319 98 280 66 257 20 222 56 180 96 153 44 70 90 51 139 42 188 10 224 77 265 74 337 55 330 122 349 158 360 199 372 249 358 291 295 307 285 358 219 304 186 365 150 338 86 361 103 284 26 277 1 226 30 181 32 131 105 119 91 50 146 37 186 46 229 58 269 61 291 105 302 140 357 154 343 203 " /></g>',
      // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; -31 200 200; 0 200 200" dur="17s" repeatCount="indefinite" additive="sum"/><path id="textcircle3" fill="none" stroke="rgba(255, 255, 255, 0.5)" stroke-width="50px" stroke-linecap="round" d="M 349 201 C 326 238 312 269 306 310 259 311 242 394 194 338 164 302 94 354 51 322 58 260 100 212 56 181 84 149 110 124 124 94 136 22 190 68 227 73 252 104 284 114 295 139 368 153 335 202 361 244 313 269 316 331 295 372 230 352 194 303 155 328 94 358 116 267 39 271 6 232 51 176 28 122 53 83 130 104 148 52 188 75 232 52 287 29 328 67 332 119 320 169 337 197 338 238 297 256 332 349 280 358 231 365 184 384 166 300 101 347 99 281 104 239 71 219 26 177 22 122 50 82 106 74 164 99 186 6 234 17 282 43 334 55 329 123 350 160 349 201 " /></g>',

      // '<g><use href="#lines""/><use href="#lines" transform="rotate(120)"/><use href="#lines" transform="rotate(240)"/></g>',
      '<circle fill="',getRGBA(id, 97, 3, "1"),'" cx="200" cy="200" r="200"/>',
      // '<circle fill="rgba(0,0,0,1)" cx="200" cy="200" r="200"/>',


      // // this is good
      // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; -51.42 200 200; 0 200 200" dur="47s" repeatCount="indefinite" additive="sum"/><use href="#sept-grid"/></g>',
      // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; 51.42 200 200; 0 200 200" dur="59s" repeatCount="indefinite" additive="sum"/><use href="#sept-grid"/></g>',

      // // this is good
      // '<g><use href="#pent-grid"/></g>',
      // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; 72 200 200; 0 200 200" dur="113s" repeatCount="indefinite" additive="sum"/><use href="#pent-grid"/></g>',
      // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; -72 200 200; 0 200 200" dur="139s" repeatCount="indefinite" additive="sum"/><use href="#pent-grid"/></g>',

      // // // this is good
      // '<g><use href="#tri-grid"/></g>',
      // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; 60 200 200; 0 200 200" dur="173s" repeatCount="indefinite" additive="sum"/><use href="#tri-grid"/></g>',
      // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; -60 200 200; 0 200 200" dur="199s" repeatCount="indefinite" additive="sum"/><use href="#tri-grid"/></g>',
      // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; 60 200 200; 0 200 200" dur="229s" repeatCount="indefinite" additive="sum"/><use href="#tri-grid"/></g>',
      // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; -60 200 200; 0 200 200" dur="263s" repeatCount="indefinite" additive="sum"/><use href="#tri-grid"/></g>',

      // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; -90 200 200; 0 200 200" dur="61s" repeatCount="indefinite" additive="sum"/><use href="#sq-grid"/></g>',
      // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; 90 200 200; 0 200 200" dur="67s" repeatCount="indefinite" additive="sum"/><use href="#sq-grid"/></g>',
      // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; -90 200 200; 0 200 200" dur="73s" repeatCount="indefinite" additive="sum"/><use href="#sq-grid"/></g>',
      // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; 90 200 200; 0 200 200" dur="83s" repeatCount="indefinite" additive="sum"/><use href="#sq-grid"/></g>',
      // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; -90 200 200; 0 200 200" dur="97s" repeatCount="indefinite" additive="sum"/><use href="#sq-grid" transform="translate(40, 40) scale(0.8)"/></g>',
      // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; 90 200 200; 0 200 200" dur="113s" repeatCount="indefinite" additive="sum"/><use href="#sq-grid" transform="translate(40, 40) scale(0.8)"/></g>',
      // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; -90 200 200; 0 200 200" dur="127s" repeatCount="indefinite" additive="sum"/><use href="#sq-grid" transform="translate(40, 40) scale(0.8)"/></g>',


      // this looks great
      '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; -180 200 200; 0 200 200"',getDur(id, 64),' repeatCount="indefinite"/><use href="#lines1"/></g>',
      '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200;  180 200 200; 0 200 200"',getDur(id, 72),' repeatCount="indefinite"/><use href="#lines2"/></g>',
      '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200;  180 200 200; 0 200 200"',getDur(id, 80),' repeatCount="indefinite"/><use href="#lines3"/></g>',
      // // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; -180 200 200; 0 200 200" dur=" 23s" repeatCount="indefinite"/><use href="#lines3" transform="translate( 5,  5) scale(0.975)"/></g>',
      // // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200;  180 200 200; 0 200 200" dur=" 29s" repeatCount="indefinite"/><use href="#lines2" transform="translate( 5,  5) scale(0.975)"/></g>',
      // // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; -180 200 200; 0 200 200" dur=" 41s" repeatCount="indefinite"/><use href="#lines1" transform="translate(35, 35) scale(0.825)"/></g>',
      // // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200;  180 200 200; 0 200 200" dur=" 47s" repeatCount="indefinite"/><use href="#lines3" transform="translate(35, 35) scale(0.825)"/></g>',
      // // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200; -180 200 200; 0 200 200" dur=" 61s" repeatCount="indefinite"/><use href="#lines2" transform="translate(40, 40) scale(0.800)"/></g>',
      // // '<g><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0 200 200;  180 200 200; 0 200 200" dur=" 67s" repeatCount="indefinite"/><use href="#lines1" transform="translate(40, 40) scale(0.800)"/></g>',

      '<defs/>'
    ));
    return render;
  }
}
