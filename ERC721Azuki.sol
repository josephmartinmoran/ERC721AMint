// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./../libraries/Administrated.sol";
import "./ERC721A.sol";
import "./../marketplace/ISplitterContract.sol";

/// @dev we will bring in the openzeppelin ERC721 NFT functionality
contract ERC721Azuki is Administrated, ERC721A {
    using Strings for uint256;
    string public baseUri;
    string public baseExtension = ".json";

    /// @dev Object with royalty info
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    /// @dev Fallback royalty information
    RoyaltyInfo private _defaultRoyaltyInfo;

    /// @dev Royalty information
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @notice Runs once when the contract is deployed
     * @param _name - NFT token name
     * @param _symbol - NFT token symbol
     * @param _admin - address of the admin
     * @param _splitter - address of the Splitter contract
     * @param _artist - Arrdess of artist
     * @param _primaryDistRecipients - List of primary addresses for distribution
     * @param _primaryDistShares - List of primary percentages for distribution
     * @param _secondaryDistRecipients - List of secondary addresses for distribution
     * @param _secondaryDistShares - List of secondary percentages for distribution
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _admin,
        address _owner,
        address _splitter,
        address _artist,
        address[] memory _primaryDistRecipients,
        uint256[] memory _primaryDistShares,
        address[] memory _secondaryDistRecipients,
        uint256[] memory _secondaryDistShares
    ) ERC721A(_name, _symbol) {
        require(_admin != address(0), "zero_addr");
        require(_splitter != address(0), "zero_addr");
        require(_artist != address(0), "zero_addr");
        require(
            _primaryDistRecipients.length == _primaryDistShares.length,
            "diff_length"
        );
        require(
            _secondaryDistRecipients.length == _secondaryDistShares.length,
            "diff_length"
        );
        changeAdmin(_admin);
        _transferOwnership(_owner);
        ISplitterContract(_splitter).setPrimaryDistribution(
            _artist,
            _primaryDistRecipients,
            _primaryDistShares
        );
        ISplitterContract(_splitter).setSecondaryDistribution(
            _artist,
            _secondaryDistRecipients,
            _secondaryDistShares
        );
        _setDefaultRoyalty(
            _secondaryDistRecipients[0],
            uint96(_secondaryDistShares[0])
        );
    }

    /**
     * @dev Mint tokens to admin wallet
     */
    function mint(uint256 _quantity) external onlyAdmin {
        require(_quantity > 0, "zero_amount");
        _safeMint(admin(), _quantity);
    }

    /**
     * @dev Mint tokens to external address
     */
    function mintTo(address _receiver, uint256 _quantity) external onlyAdmin {
        require(_quantity > 0, "zero_amount");
        _safeMint(_receiver, _quantity);
    }

    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256)
    {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) /
            _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyAdmin {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyAdmin
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyAdmin {
        _deleteDefaultRoyalty();
    }

    function resetTokenRoyalty(uint256 tokenId) external onlyAdmin {
        _resetTokenRoyalty(tokenId);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator)
        internal
    {
        require(feeNumerator <= _feeDenominator(), "fee exceed salePrice");
        require(receiver != address(0), "invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal {
        require(feeNumerator <= _feeDenominator(), "fee exceed salePrice");
        require(receiver != address(0), "invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal {
        delete _tokenRoyaltyInfo[tokenId];
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function setBaseURI(string memory newBaseURI) public onlyAdmin {
        baseUri = newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyAdmin
    {
        baseExtension = _newBaseExtension;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }
}
