// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/NFT.sol";
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
}