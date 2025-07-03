// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Vials_NFT} from "../src/NFT.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {
    uint256 private _nextTokenId;

    constructor() ERC721("MockNFT", "MNFT") {}

    function mint(address to) external returns (uint256) {
        uint256 tokenId = _nextTokenId;
        _mint(to, tokenId);
        _nextTokenId++;
        return tokenId;
    }

    function mintTo(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}

contract VialsNFTTest is Test {
    Vials_NFT public vialsNFT;
    MockERC721 public mockERC721;

    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    address public nonOwner = address(0x4);

    string constant VIAL_TYPE = "pixelify";
    string constant TOKEN_URI = "https://example.com/metadata.json";

    event VialsNFTMinted(
        address indexed to,
        uint256 indexed tokenId,
        address indexed baseContract,
        uint256 baseTokenId,
        string vialType,
        string tokenURI
    );

    event DerivativeCreated(
        address indexed baseContract,
        uint256 indexed baseTokenId,
        uint256 indexed derivativeTokenId,
        string vialType
    );

    function setUp() public {
        vm.startPrank(owner);
        vialsNFT = new Vials_NFT("VialsNFT", "VIAL", owner);
        mockERC721 = new MockERC721();
        vm.stopPrank();
    }
}


