// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vials_NFT is ERC721URIStorage, Ownable {
    uint256 public nextTokenId;
    address public baseContract;

    struct Provenance {
        address baseContract;
        uint256 baseTokenId;
    }

    mapping(uint256 => Provenance) public provenance;

    event VialsNFTMinted(
        address indexed to,
        uint256 indexed tokenId,
        address indexed baseContract,
        uint256 baseTokenId,
        string tokenURI
    );

    constructor(
        address _baseContract,
        string memory name,
        string memory symbol,
        address initalOwner
    ) ERC721(name, symbol) Ownable(initalOwner) {
        baseContract = _baseContract;
    }

    function mintVialsNFT(
        address to,
        uint256 baseTokenId,
        string memory tokenURI
    ) external onlyOwner {
        uint256 tokenId = nextTokenId;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);

        provenance[tokenId] = Provenance({
            baseContract: baseContract,
            baseTokenId: baseTokenId
        });

        emit VialsNFTMinted(
            to,
            tokenId,
            baseContract,
            baseTokenId,
            tokenURI
        );

        nextTokenId++;
    }

    function getProvenance(uint256 tokenId) public view returns (Provenance memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return provenance[tokenId];
    }
}
