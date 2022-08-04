library ToColor {
    bytes16 internal constant ALPHABET = '0123456789abcdef';

    function toColor(bytes3 value) internal pure returns (string memory) {
      bytes memory buffer = new bytes(6);
      for (uint256 i = 0; i < 3; i++) {
          buffer[i*2+1] = ALPHABET[uint8(value[i]) & 0xf];
          buffer[i*2] = ALPHABET[uint8(value[i]>>4) & 0xf];
      }
      return string(buffer);
    }

    // TODO: Debug this function, it doesn't appear to work
    function toRGBA(bytes3 value, string memory alpha) internal pure returns (string memory) {
      return string(abi.encodePacked('rgba(',uint8(value[0]),',',uint8(value[1]),',',uint8(value[2]),',',alpha,')'));
    }
}
