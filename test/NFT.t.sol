// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Vials_NFT.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Mock ERC721 contract for testing
contract MockERC721 is ERC721 {
    uint256 private _nextTokenId;
    
    constructor() ERC721("MockNFT", "MOCK") {}
    
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
    string constant TOKEN_URI = "https://example.com/metadata/1";
    
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
        vialsNFT = new Vials_NFT("Vials NFT", "VIALS", owner);
        mockERC721 = new MockERC721();
        vm.stopPrank();
    }

    function test_DeploymentSuccess() view public {
        assertEq(vialsNFT.name(), "Vials NFT");
        assertEq(vialsNFT.symbol(), "VIALS");
        assertEq(vialsNFT.owner(), owner);
        assertEq(vialsNFT.nextTokenId(), 0);
    }

    function test_MintDerivative_Success() public {
        // Setup: mint base NFT to user1
        uint256 baseTokenId = mockERC721.mint(user1);
        
        // Test: mint derivative
        vm.startPrank(user1);
        vm.expectEmit(true, true, true, true);
        emit VialsNFTMinted(user1, 0, address(mockERC721), baseTokenId, VIAL_TYPE, TOKEN_URI);
        
        vm.expectEmit(true, true, true, true);
        emit DerivativeCreated(address(mockERC721), baseTokenId, 0, VIAL_TYPE);
        
        vialsNFT.mintDerivative(address(mockERC721), baseTokenId, VIAL_TYPE, TOKEN_URI);
        vm.stopPrank();
        
        // Verify results
        assertEq(vialsNFT.balanceOf(user1), 1);
        assertEq(vialsNFT.ownerOf(0), user1);
        assertEq(vialsNFT.tokenURI(0), TOKEN_URI);
        assertEq(vialsNFT.nextTokenId(), 1);
        
        // Verify provenance
        Vials_NFT.Provenance memory prov = vialsNFT.getProvenance(0);
        assertEq(prov.baseContract, address(mockERC721));
        assertEq(prov.baseTokenId, baseTokenId);
        assertEq(prov.vialType, VIAL_TYPE);
        assertGt(prov.timestamp, 0);
        
        // Verify derivative tracking
        assertTrue(vialsNFT.hasDerivative(address(mockERC721), baseTokenId));
        assertEq(vialsNFT.getDerivativeTokenId(address(mockERC721), baseTokenId), 0);
    }

    function test_MintDerivative_RevertWhenNotOwner() public {
        // Setup: mint base NFT to user1
        uint256 baseTokenId = mockERC721.mint(user1);
        
        // Test: user2 tries to mint derivative of user1's NFT
        vm.startPrank(user2);
        vm.expectRevert("You don't own this base NFT");
        vialsNFT.mintDerivative(address(mockERC721), baseTokenId, VIAL_TYPE, TOKEN_URI);
        vm.stopPrank();
    }
    
    function test_MintDerivative_RevertWhenDerivativeExists() public {
        // Setup: mint base NFT to user1
        uint256 baseTokenId = mockERC721.mint(user1);
        
        // First derivative mint
        vm.startPrank(user1);
        vialsNFT.mintDerivative(address(mockERC721), baseTokenId, VIAL_TYPE, TOKEN_URI);
        
        // Try to mint another derivative of same base NFT
        vm.expectRevert("Derivative already exists for this base NFT");
        vialsNFT.mintDerivative(address(mockERC721), baseTokenId, "ghibli", TOKEN_URI);
        vm.stopPrank();
    }
    
    function test_MintDerivative_RevertWhenBaseTokenNotExists() public {
        // Test: try to mint derivative of non-existent base token
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, 999));
        vialsNFT.mintDerivative(address(mockERC721), 999, VIAL_TYPE, TOKEN_URI);
        vm.stopPrank();
    }

    function test_AdminMintDerivative_Success() public {
        // Setup: mint base NFT to user1
        uint256 baseTokenId = mockERC721.mint(user1);
        
        // Test: admin mints derivative to user2
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit VialsNFTMinted(user2, 0, address(mockERC721), baseTokenId, VIAL_TYPE, TOKEN_URI);
        
        vm.expectEmit(true, true, true, true);
        emit DerivativeCreated(address(mockERC721), baseTokenId, 0, VIAL_TYPE);
        
        vialsNFT.adminMintDerivative(user2, address(mockERC721), baseTokenId, VIAL_TYPE, TOKEN_URI);
        vm.stopPrank();
        
        // Verify results
        assertEq(vialsNFT.balanceOf(user2), 1);
        assertEq(vialsNFT.ownerOf(0), user2);
        assertEq(vialsNFT.tokenURI(0), TOKEN_URI);
        assertEq(vialsNFT.nextTokenId(), 1);
        
        // Verify provenance
        Vials_NFT.Provenance memory prov = vialsNFT.getProvenance(0);
        assertEq(prov.baseContract, address(mockERC721));
        assertEq(prov.baseTokenId, baseTokenId);
        assertEq(prov.vialType, VIAL_TYPE);
        assertGt(prov.timestamp, 0);
        
        // Verify derivative tracking
        assertTrue(vialsNFT.hasDerivative(address(mockERC721), baseTokenId));
        assertEq(vialsNFT.getDerivativeTokenId(address(mockERC721), baseTokenId), 0);
    }
    
    function test_AdminMintDerivative_RevertWhenNotOwner() public {
        // Setup: mint base NFT to user1
        uint256 baseTokenId = mockERC721.mint(user1);
        
        // Test: non-owner tries to admin mint
        vm.startPrank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        vialsNFT.adminMintDerivative(user2, address(mockERC721), baseTokenId, VIAL_TYPE, TOKEN_URI);
        vm.stopPrank();
    }
    
    function test_AdminMintDerivative_CanOverrideOwnershipCheck() public {
        // Setup: mint base NFT to user1
        uint256 baseTokenId = mockERC721.mint(user1);
        
        // Test: admin can mint derivative to user2 even though user2 doesn't own base NFT
        vm.startPrank(owner);
        vialsNFT.adminMintDerivative(user2, address(mockERC721), baseTokenId, VIAL_TYPE, TOKEN_URI);
        vm.stopPrank();
        
        // Verify user2 owns the derivative
        assertEq(vialsNFT.ownerOf(0), user2);
    }

    function test_GetProvenance_Success() public {
        // Setup: mint base NFT and derivative
        uint256 baseTokenId = mockERC721.mint(user1);
        
        vm.startPrank(user1);
        vialsNFT.mintDerivative(address(mockERC721), baseTokenId, VIAL_TYPE, TOKEN_URI);
        vm.stopPrank();
        
        // Test: get provenance
        Vials_NFT.Provenance memory prov = vialsNFT.getProvenance(0);
        assertEq(prov.baseContract, address(mockERC721));
        assertEq(prov.baseTokenId, baseTokenId);
        assertEq(prov.vialType, VIAL_TYPE);
        assertGt(prov.timestamp, 0);
    }
    
    function test_GetProvenance_RevertWhenTokenNotExists() public {
        // Test: get provenance of non-existent token
        vm.expectRevert("Token does not exist");
        vialsNFT.getProvenance(999);
    }
    
    function test_HasDerivative_ReturnsCorrectly() public {
        // Setup: mint base NFT
        uint256 baseTokenId = mockERC721.mint(user1);
        
        // Test: initially no derivative
        assertFalse(vialsNFT.hasDerivative(address(mockERC721), baseTokenId));
        
        // Mint derivative
        vm.startPrank(user1);
        vialsNFT.mintDerivative(address(mockERC721), baseTokenId, VIAL_TYPE, TOKEN_URI);
        vm.stopPrank();
        
        // Test: now has derivative
        assertTrue(vialsNFT.hasDerivative(address(mockERC721), baseTokenId));
    }
    
    function test_GetDerivativeTokenId_ReturnsCorrectly() public {
        // Setup: mint base NFT and derivative
        uint256 baseTokenId = mockERC721.mint(user1);
        
        vm.startPrank(user1);
        vialsNFT.mintDerivative(address(mockERC721), baseTokenId, VIAL_TYPE, TOKEN_URI);
        vm.stopPrank();
        
        // Test: get derivative token ID
        uint256 derivativeTokenId = vialsNFT.getDerivativeTokenId(address(mockERC721), baseTokenId);
        assertEq(derivativeTokenId, 0);
    }

    function test_GetOwnedDerivatives_Success() public {
        // Setup: mint multiple base NFTs and derivatives
        uint256 baseTokenId1 = mockERC721.mint(user1);
        uint256 baseTokenId2 = mockERC721.mint(user1);
        
        vm.startPrank(user1);
        vialsNFT.mintDerivative(address(mockERC721), baseTokenId1, VIAL_TYPE, TOKEN_URI);
        vialsNFT.mintDerivative(address(mockERC721), baseTokenId2, "ghibli", TOKEN_URI);
        vm.stopPrank();
        
        // Test: get owned derivatives
        (uint256[] memory tokenIds, Vials_NFT.Provenance[] memory provenances) = 
            vialsNFT.getOwnedDerivatives(user1);
        
        assertEq(tokenIds.length, 2);
        assertEq(provenances.length, 2);
        
        // Verify first derivative
        assertEq(tokenIds[0], 0);
        assertEq(provenances[0].baseContract, address(mockERC721));
        assertEq(provenances[0].baseTokenId, baseTokenId1);
        assertEq(provenances[0].vialType, VIAL_TYPE);
        
        // Verify second derivative
        assertEq(tokenIds[1], 1);
        assertEq(provenances[1].baseContract, address(mockERC721));
        assertEq(provenances[1].baseTokenId, baseTokenId2);
        assertEq(provenances[1].vialType, "ghibli");
    }
    
    function test_GetOwnedDerivatives_EmptyForNoOwnership() view public {
        // Test: get owned derivatives for user with no derivatives
        (uint256[] memory tokenIds, Vials_NFT.Provenance[] memory provenances) = 
            vialsNFT.getOwnedDerivatives(user2);
        
        assertEq(tokenIds.length, 0);
        assertEq(provenances.length, 0);
    }

    function test_TokenURI_Success() public {
        // Setup: mint base NFT and derivative
        uint256 baseTokenId = mockERC721.mint(user1);
        
        vm.startPrank(user1);
        vialsNFT.mintDerivative(address(mockERC721), baseTokenId, VIAL_TYPE, TOKEN_URI);
        vm.stopPrank();
        
        // Test: get token URI
        string memory uri = vialsNFT.tokenURI(0);
        assertEq(uri, TOKEN_URI);
    }
    
    function test_TokenURI_RevertWhenTokenNotExists() public {
        // Test: get token URI of non-existent token
        vm.expectRevert("Token does not exist");
        vialsNFT.tokenURI(999);
    }

    function test_MintDerivative_WithEmptyVialType() public {
        // Setup: mint base NFT
        uint256 baseTokenId = mockERC721.mint(user1);
        
        // Test: mint derivative with empty vial type
        vm.startPrank(user1);
        vialsNFT.mintDerivative(address(mockERC721), baseTokenId, "", TOKEN_URI);
        vm.stopPrank();
        
        // Verify empty vial type is stored
        Vials_NFT.Provenance memory prov = vialsNFT.getProvenance(0);
        assertEq(prov.vialType, "");
    }
    
    function test_MintDerivative_WithEmptyTokenURI() public {
        // Setup: mint base NFT
        uint256 baseTokenId = mockERC721.mint(user1);
        
        // Test: mint derivative with empty token URI
        vm.startPrank(user1);
        vialsNFT.mintDerivative(address(mockERC721), baseTokenId, VIAL_TYPE, "");
        vm.stopPrank();
        
        // Verify empty token URI is stored
        assertEq(vialsNFT.tokenURI(0), "");
    }
    
    function test_MultipleDerivativesFromDifferentBaseContracts() public {
        // Setup: create another mock ERC721 contract
        MockERC721 mockERC721_2 = new MockERC721();
        
        // Mint base NFTs from different contracts
        uint256 baseTokenId1 = mockERC721.mint(user1);
        uint256 baseTokenId2 = mockERC721_2.mint(user1);
        
        // Test: mint derivatives from different base contracts
        vm.startPrank(user1);
        vialsNFT.mintDerivative(address(mockERC721), baseTokenId1, VIAL_TYPE, TOKEN_URI);
        vialsNFT.mintDerivative(address(mockERC721_2), baseTokenId2, "ghibli", TOKEN_URI);
        vm.stopPrank();
        
        // Verify both derivatives exist
        assertEq(vialsNFT.balanceOf(user1), 2);
        assertTrue(vialsNFT.hasDerivative(address(mockERC721), baseTokenId1));
        assertTrue(vialsNFT.hasDerivative(address(mockERC721_2), baseTokenId2));
    }
}