// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract EineSigns is ERC721A, Ownable {
    string public PROVENANCE;
    bool public saleIsActive = false;
    string private _baseURIextended;

    bool public isAllowListActive = false;
    uint256 public constant collectionsize = 10000;
    uint256 public constant maxBatchsize = 5;
    uint256 public constant PRICE_PER_TOKEN = 0.1 ether;
    uint256 public amountForDevs;

    mapping(address => uint8) private _allowList;

    constructor(uint256 amountForDevs_) ERC721A("name", "symbol", 5, 10000) {
     amountForDevs = amountForDevs_;
    }

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
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
        require(ts + numberOfTokens <= collectionsize, "Purchase would exceed max tokens");
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
        quantity % maxBatchsize == 0,
        "can only mint a multiple of the maxBatchsize"
    );
        uint256 numChunks = quantity / maxBatchsize;
        for (uint256 i = 0; i < numChunks; i++) {
        _safeMint(msg.sender, maxBatchsize);
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
        require(numberOfTokens <= maxBatchsize, "Exceeded max token purchase");
        require(ts + numberOfTokens <= collectionsize, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

  function withdraw() public payable onlyOwner {
    // This will pay saucedoa 20% of the initial sale.
    (bool hs, ) = payable(0x6B3945269CA59F7d65de03E7fbcbcF7570e703fD).call{value: address(this).balance * 20 / 100}("");
    require(hs);
    // =============================================================================
    
    // This will payout the owner 80% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
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