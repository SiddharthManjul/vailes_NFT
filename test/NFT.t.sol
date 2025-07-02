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
    string constant TOKEN_URI = "https://example.com/vials/";
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

    function test_deployment_SetsCorrectNameAndSymbol() view public {
        assertEq(vialsNFT.name(), NAME);
        assertEq(vialsNFT.symbol(), SYMBOL);
    }

    function test_Deployment_SetsCorrectOwner() view public {
        assertEq(vialsNFT.owner(), owner);
    }

    function test_Deployment_SetsCorrectBaseContract() view public {
        assertEq(vialsNFT.baseContract(), baseContract);
    }

    function test_Deployment_InitializeNextTokenIdToZero() view public {
        assertEq(vialsNFT.nextTokenId(), 0);
    }

    function test_MintVialsNFT_Success() public {
        vm.prank(owner);

        vm.expectEmit(true, true, true, true);
        emit VialsNFTMinted(user1, 0, baseContract, BASE_TOKEN_ID, TOKEN_URI);
        vialsNFT.mintVialsNFT(user1, BASE_TOKEN_ID, TOKEN_URI);
        
        assertEq(vialsNFT.ownerOf(0), user1);
        assertEq(vialsNFT.tokenURI(0), TOKEN_URI);
        assertEq(vialsNFT.nextTokenId(), 1);
    }

    function test_MintVialsNFT_MultipleTokensIncrementId() public {
        string memory tokenURI2 = "https://example.com/vials/2";
        uint256 baseTokenId2 = 456;

        vm.startPrank(owner);

        vialsNFT.mintVialsNFT(user1, BASE_TOKEN_ID, TOKEN_URI);
        vialsNFT.mintVialsNFT(user2, baseTokenId2, tokenURI2);

        vm.stopPrank();

        assertEq(vialsNFT.ownerOf(0), user1);
        assertEq(vialsNFT.ownerOf(1), user2);
        assertEq(vialsNFT.nextTokenId(), 2);
        assertEq(vialsNFT.tokenURI(0), TOKEN_URI);
        assertEq(vialsNFT.tokenURI(1), tokenURI2);
    }

    function test_MintVialsNFT_RevertWhenNotOwner() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user1));
        vialsNFT.mintVialsNFT(user1, BASE_TOKEN_ID, TOKEN_URI);
    }
    
    function test_MintVialsNFT_RevertWhenMintingToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("ERC721InvalidReceiver(address)", address(0)));
        vialsNFT.mintVialsNFT(address(0), BASE_TOKEN_ID, TOKEN_URI);
    }
    
    function test_MintVialsNFT_EmitsCorrectEvent() public {
        vm.prank(owner);
        
        vm.expectEmit(true, true, true, true);
        emit VialsNFTMinted(user1, 0, baseContract, BASE_TOKEN_ID, TOKEN_URI);
        
        vialsNFT.mintVialsNFT(user1, BASE_TOKEN_ID, TOKEN_URI);
    }

    function test_GetProvenance_Success() public {
        vm.prank(owner);
        vialsNFT.mintVialsNFT(user1, BASE_TOKEN_ID, TOKEN_URI);

        Vials_NFT.Provenance memory prov = vialsNFT.getProvenance(0);

        assertEq(prov.baseContract, baseContract);
        assertEq(prov.baseTokenId, BASE_TOKEN_ID);
    }

    function test_GetProvenance_MappingAccess() public {
        vm.prank(owner);
        vialsNFT.mintVialsNFT(user1, BASE_TOKEN_ID, TOKEN_URI);

        (address retrievedBaseContract, uint256 retrievedBaseTokenId) = vialsNFT.provenance(0);

        assertEq(retrievedBaseContract, baseContract);
        assertEq(retrievedBaseTokenId, BASE_TOKEN_ID);
    }
}
