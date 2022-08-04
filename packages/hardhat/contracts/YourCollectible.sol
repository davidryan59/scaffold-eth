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

contract YourCollectible is ERC721, Ownable {

  using Strings for uint256;
  using HexStrings for uint160;
  using ToColor for bytes3;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  constructor() public ERC721("Loogies", "LOOG") {
    // RELEASE THE LOOGIES!
  }

  mapping (uint256 => bytes3) public color;
  mapping (uint256 => uint256) public chubbiness;
  mapping (uint256 => bool) public iteration2ternary;
  mapping (uint256 => bool) public iteration3ternary;
  mapping (uint256 => bool) public rotatoor;

  uint256 mintDeadline = block.timestamp + 24 hours;

  function mintItem()
      public
      returns (uint256)
  {
      require( block.timestamp < mintDeadline, "DONE MINTING");
      _tokenIds.increment();

      uint256 id = _tokenIds.current();
      _mint(msg.sender, id);

      bytes32 predictableRandom = keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this), id ));
      color[id] = bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[1]) >> 8 ) | ( bytes3(predictableRandom[2]) >> 16 );
      chubbiness[id] = 35+((55*uint256(uint8(predictableRandom[3])))/255);
      iteration2ternary[id] = uint8(predictableRandom[4]) & 0x1 == 1;
      iteration3ternary[id] = uint8(predictableRandom[4]) & 0x2 == 2;
      rotatoor[id] = uint8(predictableRandom[4]) & 0x4 == 4;
      return id;
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
      require(_exists(id), "not exist");
      string memory name = string(abi.encodePacked('Loogie #',id.toString()));
      string memory description = string(abi.encodePacked('This Loogie is the color #',color[id].toColor(),' with a chubbiness of ',uint2str(chubbiness[id]),'!!!'));
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
                              color[id].toColor(),
                              '"},{"trait_type": "chubbiness", "value": ',
                              uint2str(chubbiness[id]),
                              '}], "owner":"',
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

  function getIteration0Line(
    string memory label,
    string memory transl,
    string memory x,
    string memory y
  ) private pure returns (string memory) {
    return string(abi.encodePacked(
      '<g>',
        '<animateTransform attributeName="transform" attributeType="XML" type="translate" values="0; ',transl,'; 0" dur="10s" repeatCount="indefinite" additive="sum"/>',
        '<animateTransform attributeName="transform" attributeType="XML" type="scale" values="1 1; 0.5 1; 1 1" dur="10s" repeatCount="indefinite" additive="sum"/>',
        '<use href="#',label,'0" x="',x,'" y="',y,'"/>',
      '</g>'
    ));
  }

  function makeNextIteration4Square(
    uint256 id,
    string memory label,
    string memory thisIt,
    string memory prevIt
  ) private view returns (string memory) {
    string memory labelThisIt = string(abi.encodePacked(label, thisIt));
    string memory labelPrevIt = string(abi.encodePacked(label, prevIt));
    return string(abi.encodePacked(
      '<g id="',labelThisIt,'" transform="scale(0.5)">',
        rotatoor[id]?'<animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0; -90; 0" dur="10s" repeatCount="indefinite" additive="sum"/>':'',
        '<use href="#',labelPrevIt,'" x="-0.5" y=" 0.5"/>',
        '<use href="#',labelPrevIt,'" x=" 0.5" y=" 0.5"/>',
        '<use href="#',labelPrevIt,'" x="-0.5" y="-0.5"/>',
        '<g transform="rotate(0 0.5 -0.5)"><use href="#',labelPrevIt,'" x=" 0.5" y="-0.5"/></g>',
      '</g>'
    ));
  }

  function makeNextIteration9Square(
    uint256 id,
    string memory label,
    string memory thisIt,
    string memory prevIt
  ) private view returns (string memory) {
    string memory labelThisIt = string(abi.encodePacked(label, thisIt));
    string memory labelPrevIt = string(abi.encodePacked(label, prevIt));
    return string(abi.encodePacked(
      '<g id="',labelThisIt,'" transform="scale(0.3333)">',
        rotatoor[id]?'<animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0; 90; 0" dur="10s" repeatCount="indefinite" additive="sum"/>':'',
        '<use href="#',labelPrevIt,'" x="-1" y=" 1"/>',
        '<use href="#',labelPrevIt,'" x=" 0" y=" 1"/>',
        '<g transform="rotate(0 1 1)"><use href="#',labelPrevIt,'" x=" 1" y=" 1"/></g>',
        '<g transform="rotate(0 -1 0)"><use href="#',labelPrevIt,'" x="-1" y=" 0"/></g>',
        '<g transform="rotate(0 0 0)"><use href="#',labelPrevIt,'" x=" 0" y=" 0"/></g>',
        '<use href="#',labelPrevIt,'" x=" 1" y=" 0"/>',
        '<use href="#',labelPrevIt,'" x="-1" y="-1"/>',
        '<use href="#',labelPrevIt,'" x=" 0" y="-1"/>',
        '<use href="#',labelPrevIt,'" x=" 1" y="-1"/>',
      '</g>'
    ));
  }

  function getFractal(
    uint256 id,
    string memory label,
    string memory lineCol,
    string memory fillCol,
    string memory t1,
    string memory t2
  ) private view returns (string memory) {
    string memory iteration0 = string(abi.encodePacked(
      '<rect id="',label,'0" x="-0.5" y="-0.5" width="1" height="1" stroke="',lineCol,'" fill="',fillCol,'" stroke-width="0.1"/>'
    ));
    string memory iteration1 = string(abi.encodePacked(
      '<g id="',label,'1" transform="scale(0.5)">',
        getIteration0Line(label, t1, "-0.5", " 0.5"),
        getIteration0Line(label, t1, " 0.5", " 0.5"),
        getIteration0Line(label, t2, "-0.5", "-0.5"),
        getIteration0Line(label, t2, " 0.5", "-0.5"),
      '</g>'
    ));
    string memory iteration2 = iteration2ternary[id] ? makeNextIteration9Square(id, label, "2", "1") : makeNextIteration4Square(id, label, "2", "1");
    string memory iteration3 = iteration3ternary[id] ? makeNextIteration9Square(id, label, "3", "2") : makeNextIteration4Square(id, label, "3", "2");
    return string(abi.encodePacked(
      iteration0,
      iteration1,
      iteration2,
      iteration3
    ));
  }

  // Function visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenById(uint256 id) public view returns (string memory) {
    string memory render = string(abi.encodePacked(
      '<rect id="rect_bg" x="2" y="2" rx="150" ry="150" width="396" height="396" stroke="#',color[id].toColor(),'" fill="rgba(160, 160, 160, 1)" stroke-width="5"/>',
      '<g visibility="hidden">',
        getFractal(id, 'f', 'rgba(0, 0, 0, 0.75)', 'rgba(0, 0, 255, 0.5)', '-0.5', '0.5'),
        getFractal(id, 'g', 'rgba(128, 80, 0, 0.75)', 'rgba(255, 240, 128, 0.5)', '0.5', '-0.5'),
      '</g>',
      '<g>',
        '<animateTransform attributeName="transform" attributeType="XML" type="translate" values="0; 95; 0" dur="10s" repeatCount="indefinite" additive="sum"/>',
        '<use href="#f3" transform="translate(105, 200) scale(125, 250) rotate(45)"/>',
      '</g>',
      '<g>',
        '<animateTransform attributeName="transform" attributeType="XML" type="translate" values="0; -95; 0" dur="10s" repeatCount="indefinite" additive="sum"/>',
        '<use href="#g3" transform="translate(295, 200) scale(125, 250) rotate(45)"/>',
      '</g>'
    ));
    return render;
  }

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
      if (_i == 0) {
          return "0";
      }
      uint j = _i;
      uint len;
      while (j != 0) {
          len++;
          j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len;
      while (_i != 0) {
          k = k-1;
          uint8 temp = (48 + uint8(_i - _i / 10 * 10));
          bytes1 b1 = bytes1(temp);
          bstr[k] = b1;
          _i /= 10;
      }
      return string(bstr);
  }
}
