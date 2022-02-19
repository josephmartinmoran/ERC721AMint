// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import './ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract NFT is ERC721A, Ownable, ReentrancyGuard {
    string public PROVENANCE;
    bool public saleIsActive = false;
    string private _baseURIextended;

    bool public isAllowListActive = false;
    uint256 public collectionSize;
    uint256 public maxBatchSize;
    uint256 public PRICE_PER_TOKEN;
    uint256 public amountForDevs;

    mapping(address => uint8) private _allowList;

    constructor(uint256 maxBatchSize_, uint256 collectionSize_) 
    ERC721A("name", "symbol", maxBatchSize_, collectionSize_) {
    maxBatchSize = maxBatchSize_;
    collectionSize = collectionSize_; 
    }

    function setPRICE_PER_TOKEN(uint256 PRICE_PER_TOKEN_) external onlyOwner {
        PRICE_PER_TOKEN = PRICE_PER_TOKEN_;
    }

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setamountForDevs(uint256 _amountForDevs) external onlyOwner {
        amountForDevs = _amountForDevs;
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function numAvailableToMint(address addr) external view returns (uint8) {
        return _allowList[addr];
    }

    function mintAllowList(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(numberOfTokens <= _allowList[msg.sender], "Exceeded max available to purchase");
        require(ts + numberOfTokens <= collectionSize, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _allowList[msg.sender] -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    // For marketing etc.
    function devMint(uint256 quantity) external onlyOwner {
        require(
        totalSupply() + quantity <= amountForDevs,
        "too many already minted before dev mint"
    );
        require(
        quantity % maxBatchSize == 0,
        "can only mint a multiple of the maxBatchsize"
    );
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
        _safeMint(msg.sender, maxBatchSize);
    }
  }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function reserve(uint256 n) public onlyOwner {
      uint supply = totalSupply();
      uint i;
      for (i = 0; i < n; i++) {
          _safeMint(msg.sender, supply + i);
      }
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mint(uint numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= maxBatchSize, "Exceeded max token purchase");
        require(ts + numberOfTokens <= collectionSize, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

      function setOwnersExplicit(uint256 quantity) external onlyOwner {
    _setOwnersExplicit(quantity);
  }
  
  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
}
