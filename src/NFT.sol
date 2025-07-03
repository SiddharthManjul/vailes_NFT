// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

contract Vials_NFT is ERC721URIStorage, Ownable {
    uint256 public nextTokenId;

    struct Provenance {
        address baseContract;
        uint256 baseTokenId;
        string vialType;
        uint256 timestamp;
    }

    // Maps derivative tokenId => provenance
    mapping(uint256 => Provenance) public provenance;

    // Tracks if a derivative exists for a given baseContract + baseTokenId
    mapping(address => mapping(uint256 => bool)) public derivativeExists;

    // Stores the derivative token ID for a given base NFT
    mapping(address => mapping(uint256 => uint256)) public baseToDerivative;

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

    constructor(string memory name, string memory symbol, address initialOwner)
        ERC721(name, symbol)
        Ownable(initialOwner)
    {}

    /**
     * @dev Mint a derivative from any ERC721 base contract
     * @param baseContract Address of the base ERC721 contract
     * @param baseTokenId Token ID from the base contract
     * @param vialType Type of transformation (e.g., pixelify, ghibli)
     * @param newTokenURI URI for the new NFT metadata
     */
    function mintDerivative(
        address baseContract,
        uint256 baseTokenId,
        string memory vialType,
        string memory newTokenURI
    ) external {
        require(
            IERC721(baseContract).ownerOf(baseTokenId) == msg.sender,
            "You don't own this base NFT"
        );

        require(
            !derivativeExists[baseContract][baseTokenId],
            "Derivative already exists for this base NFT"
        );

        uint256 tokenId = nextTokenId;

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, newTokenURI);

        provenance[tokenId] = Provenance({
            baseContract: baseContract,
            baseTokenId: baseTokenId,
            vialType: vialType,
            timestamp: block.timestamp
        });

        derivativeExists[baseContract][baseTokenId] = true;
        baseToDerivative[baseContract][baseTokenId] = tokenId;

        emit VialsNFTMinted(
            msg.sender,
            tokenId,
            baseContract,
            baseTokenId,
            vialType,
            newTokenURI
        );

        emit DerivativeCreated(baseContract, baseTokenId, tokenId, vialType);

        nextTokenId++;
    }

    function adminMintDerivative(
        address to,
        address baseContract,
        uint256 baseTokenId,
        string memory vialType,
        string memory newTokenURI
    ) external onlyOwner {
        uint256 tokenId = nextTokenId;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, newTokenURI);

        provenance[tokenId] = Provenance({
            baseContract: baseContract,
            baseTokenId: baseTokenId,
            vialType: vialType,
            timestamp: block.timestamp
        });

        derivativeExists[baseContract][baseTokenId] = true;
        baseToDerivative[baseContract][baseTokenId] = tokenId;

        emit VialsNFTMinted(
            to,
            tokenId,
            baseContract,
            baseTokenId,
            vialType,
            newTokenURI
        );

        emit DerivativeCreated(baseContract, baseTokenId, tokenId, vialType);

        nextTokenId++;
    }

    function getProvenance(uint256 tokenId) public view returns (Provenance memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return provenance[tokenId];
    }

    function hasDerivative(address baseContract, uint256 baseTokenId) public view returns (bool) {
        return derivativeExists[baseContract][baseTokenId];
    }

    function getDerivativeTokenId(address baseContract, uint256 baseTokenId) public view returns (uint256) {
        return baseToDerivative[baseContract][baseTokenId];
    }

    function getOwnedDerivatives(address owner)
        external
        view
        returns (uint256[] memory tokenIds, Provenance[] memory provenances)
    {
        uint256 balance = balanceOf(owner);
        tokenIds = new uint256[](balance);
        provenances = new Provenance[](balance);

        uint256 currentIndex = 0;
        for (uint256 i = 0; i < nextTokenId; i++) {
            if (_ownerOf(i) == owner) {
                tokenIds[currentIndex] = i;
                provenances[currentIndex] = provenance[i];
                currentIndex++;
            }
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return super.tokenURI(tokenId);
    }
}
