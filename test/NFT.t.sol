// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Vials_NFT} from "../src/NFT.sol";

contract Vials_NFTTest is Test {
    Vials_NFT public vialsNFT;

    address public owner;
    address public user1;
    address public user2;
    address public baseContract;

    string constant NAME = "VialsNFT";
    string constant SYMBOL = "VIALS";
    string constant BASE_URI = "https://example.com/vials/";
    uint256 public BASE_TOKEN_ID = 123;

    event VialsNFTMinted(
        address indexed to,
        uint256 indexed tokenId,
        address indexed baseContract,
        uint256 baseTokenId,
        string tokenURI
    );

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        baseContract = makeAddr("baseContract");

        vm.prank(owner);
        vialsNFT = new Vials_NFT(baseContract, NAME, SYMBOL, owner);
    }
}
