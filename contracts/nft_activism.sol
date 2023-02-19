// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

error OwnerOnlyError();
error WhitelistLevelError(uint8 minRequiredLevel, uint8 currentLevel, address adr);
error TokenPermissionError(uint256 tokenId);
error UriAlreadyExists(string uri, uint256 tokenId);
error CannotMintToSelf();

contract UpstandContract is ERC1155URIStorage {
  address private owner;
  uint256 private nftCounter;
  mapping(address => uint8) private whitelist; // a tier list (default level 0)
                                              // level 1: Allows to issue activism NFTs as rewards to people who completed tasks
                                              // level 2: Allows to create brand-new activism NFTs and allow others to award it
  mapping(uint256 => mapping(address => bool)) private nftMintWhitelist; // who is allowed to reward which token. the token creator can change this list
  mapping(string  => uint256) private uriToTokenId;

  event TokenAwarded(uint256 tokenId, address beneficiary, address awarder);
  event TokenCreated(uint256 tokenId, string uri, address creator);

  constructor() ERC1155("") {
    nftCounter = 1; // set this to 1 since `uriToTokenId` mapping defaults to 0
    owner = msg.sender;
    whitelist[owner] = 3;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert OwnerOnlyError();
    }
    _;
  }

  modifier atLeastWhitelistLevel(uint8 wLevel) {
    if (whitelist[msg.sender] < wLevel) {
      revert WhitelistLevelError(wLevel, whitelist[msg.sender], msg.sender);
    }
    _;
  }

  modifier allowedToAwardToken(uint256 tokenId) {
    if (nftMintWhitelist[tokenId][msg.sender] == false) {
      revert TokenPermissionError(tokenId);
    }
    _;
  }

  // Write functions
  function setWhitelistLevel(address adr, uint8 wLevel) public onlyOwner {
    whitelist[adr] = wLevel;
  }

  function createActivismNft(string calldata uri) public atLeastWhitelistLevel(2) {
    if (uriToTokenId[uri] != 0) {
      revert UriAlreadyExists(uri, uriToTokenId[uri]);
    }
    _setURI(nftCounter, uri);
    nftMintWhitelist[nftCounter][msg.sender] = true;
    uriToTokenId[uri] = nftCounter;
    emit TokenCreated(nftCounter, uri, msg.sender);
    nftCounter = nftCounter + 1;
  }

  function createActivismNftBatch(string[] calldata uris) public atLeastWhitelistLevel(2) {
    for (uint i = 0; i < uris.length; i+= 1) {
      createActivismNft(uris[i]);
    }
  }

  function awardActivismNft(uint256 tokenId, address beneficiary) public atLeastWhitelistLevel(1) allowedToAwardToken(tokenId) {
    if (beneficiary == msg.sender) {
      revert CannotMintToSelf();
    }
    _mint(beneficiary, tokenId, 1, "");
    emit TokenAwarded(tokenId, beneficiary, msg.sender);
  }

  function toggleNftMintAllowance(uint256 tokenId, address minter) public atLeastWhitelistLevel(2) {
    if (whitelist[minter] == 0) {
      revert WhitelistLevelError(1, 0, minter);
    }
    if (whitelist[msg.sender] < whitelist[minter]) {
      revert WhitelistLevelError(whitelist[minter], whitelist[msg.sender], msg.sender);
    }
    if (minter == msg.sender || nftMintWhitelist[tokenId][msg.sender] == false) {
      revert TokenPermissionError(tokenId);
    }

    nftMintWhitelist[tokenId][minter] = !nftMintWhitelist[tokenId][minter];
  }

  // Read functions
  function getWhitelistLevel(address adr) public view returns(uint8) {
    return whitelist[adr];
  }

  function getNftMintAllowance(uint256 tokenId, address minter) public view returns(bool) {
    return nftMintWhitelist[tokenId][minter];
  }

  function getNftCounter() public view returns(uint256) {
    return nftCounter;
  }

  function getTokenIdByUri(string calldata uri) public view returns(uint256) {
    return uriToTokenId[uri];
  }
}
