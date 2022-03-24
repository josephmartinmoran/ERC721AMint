// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./../libraries/Administrated.sol";
import "./ERC721Azuki.sol";

/**
 * @dev NFT factory contract. We are useing it to deploy new NFT collections.
 */
contract ERC721AzukiFactory is Administrated {
    /// @notice Splitter contract address
    address public splitter;

    /// @dev Emits new token address for a single artist NFT
    event CreatedERC721azuki(
        address indexed token,
        string indexed name,
        string indexed symbol
    );

    /// @dev Emits when splitter contract address changed
    event SplitterChanged(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Contract constructor
     * @param _splitter - Address of the splitter contract
     */
    constructor(address _splitter) {
        require(_splitter != address(0), "zero address");
        splitter = _splitter;
    }

    /**
     * @notice Change splitter address
     * @param _splitter - Address of the splitter contract
     */
    function setSplitterContract(address _splitter) external onlyOwner {
        require(_splitter != address(0), "zero address");
        require(_splitter != splitter, "same address");
        address _oldSplitter = splitter;
        splitter = _splitter;
        emit SplitterChanged(_oldSplitter, _splitter);
    }

    /**
     * @notice Deploy new NFT contract for single artist
     * @param _name - Name of the NFT
     * @param _symbol - Symbol of the NFT
     * @param _artist - Address of artist
     * @param _primaryDistRecipients - List of primary addresses for distribution
     * @param _primaryDistShares - List of primary percentages for distribution
     * @param _secondaryDistRecipients - List of secondary addresses for distribution
     * @param _secondaryDistShares - List of secondary percentages for distribution
     */
    function createERC721azuki(
        string memory _name,
        string memory _symbol,
        address _artist,
        address[] memory _primaryDistRecipients,
        uint256[] memory _primaryDistShares,
        address[] memory _secondaryDistRecipients,
        uint256[] memory _secondaryDistShares
    ) external onlyAdmin returns (address) {
        ERC721Azuki _newNFT = new ERC721Azuki(
            _name,
            _symbol,
            admin(),
            owner(),
            splitter,
            _artist,
            _primaryDistRecipients,
            _primaryDistShares,
            _secondaryDistRecipients,
            _secondaryDistShares
        );
        emit CreatedERC721azuki(address(_newNFT), _name, _symbol);
        return address(_newNFT);
    }
}
