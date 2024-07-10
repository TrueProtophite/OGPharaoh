// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC2981} from '@openzeppelin/contracts/interfaces/IERC2981.sol';
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract OGPharaoh is ERC721, Ownable, IERC2981, ERC721URIStorage, IERC721Receiver, ERC721Enumerable {

    enum NFTType {
        Normal,
        Shield,
        Spirit,
        God
    }

    uint256 private constant BASIS_POINTS_DECIMALS = 2;
    uint256 private constant ONE_HUNDRED_PERCENT = 100 * (10 ** BASIS_POINTS_DECIMALS); //100% + padded zeros

    uint256 public constant MAX_ROYALTY_PERCENTAGE = 10 * (10 ** BASIS_POINTS_DECIMALS); //10% + padded zeros

    address public admin;

    address private magicContract;

    address public royaltyCollector;
    mapping (NFTType => uint256) private royalties;

    struct TokenInfo {
        string uri;
        NFTType _type;
        uint256 boost;
        uint256 shimmerId;
    }

    mapping (uint256 => uint256) public magicToPharaoh;
    mapping (uint256 => TokenInfo) public tokenInfos;

    event NewAdmin(address indexed newAdmin);
    event RoyaltyCollector(address indexed recipient);

    constructor(address owner, address _royaltyCollector, address _magicContract, string memory collectionName, string memory collectionSymbol) ERC721(collectionName, collectionSymbol) Ownable(owner) {
        admin = msg.sender;
        magicContract = _magicContract;
        royaltyCollector = _royaltyCollector;
    }

    ////////////////////////////////////
    //            USERS               //
    ////////////////////////////////////
    function importFromMagic(uint256[] memory tokenIds) external {
        for(uint256 i = 0; i < tokenIds.length; i++){
            IERC721(magicContract).safeTransferFrom(msg.sender, address(this), tokenInfos[tokenIds[i]].shimmerId);
            IERC721(address(this)).safeTransferFrom(address(this), msg.sender, tokenIds[i]);
        }
    }

    function exportToMagic(uint256[] memory tokenIds) external {
        for(uint256 i = 0; i < tokenIds.length; i++){
            IERC721(magicContract).safeTransferFrom(address(this), msg.sender, tokenInfos[tokenIds[i]].shimmerId);
            IERC721(address(this)).safeTransferFrom(msg.sender, address(this), tokenIds[i]);
        }
    }

    function getBoost(uint256 tokenId) public view returns(uint256){
        return tokenInfos[tokenId].boost;
    }

    function getType(uint256 tokenId) public view returns(NFTType) {
        return tokenInfos[tokenId]._type;
    }

    function getMagicPharaohId(uint256 tokenId) public view returns(uint256) {
        return tokenInfos[tokenId].shimmerId;
    }

    ////////////////////////////////////
    //            OWNER               //
    ////////////////////////////////////
    function setRoyaltyCollector(address _royaltyCollector) external onlyOwner {
        royaltyCollector = _royaltyCollector;
        emit RoyaltyCollector(_royaltyCollector);
    }

    function setRoyalty(NFTType _type, uint256 _royaltyPercentage) external onlyOwner {
        require(_royaltyPercentage <= MAX_ROYALTY_PERCENTAGE, "Max royalty breached");
        royalties[_type] = _royaltyPercentage;
    }

    function setAdmin(address _newAdmin) external onlyOwner {
        admin = _newAdmin;
        emit NewAdmin(_newAdmin);
    }

    ////////////////////////////////////
    //             ADMIN              //
    ////////////////////////////////////
    modifier onlyAdmin {
        _checkAdmin();
        _;
    }

    function _checkAdmin() internal view virtual {
        if (_msgSender() != admin) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function setNFT(uint256 tokenId, uint256 shimmerId, uint256 boost, string memory uri) public onlyAdmin {
        require(tokenId <= 4701, "Max supply");
        require(shimmerId != 0, "Shimmer ID 0");

        if(tokenInfos[tokenId].shimmerId == 0){
            _safeMint(address(this), tokenId);
        }

        tokenInfos[tokenId].shimmerId = shimmerId;

        tokenInfos[tokenId].boost = boost;
        NFTType _type = NFTType.Normal; 
        if (boost >= 200 && boost < 400){
            _type = NFTType.Shield; 
        } else if (boost >= 400 && boost <= 1000) {
            _type = NFTType.Spirit;
        } else if (boost == 2500){
            _type = NFTType.God;
        }
        tokenInfos[tokenId]._type = _type;
        tokenInfos[tokenId].uri = uri;

        _setTokenURI(tokenId, uri);
    }

    ////////////////////////////////////
    //           OVERRIDES            //
    ////////////////////////////////////
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address, uint256) {
        require(_tokenId <= 4701, "Out of bounds");
        return (royaltyCollector, (_salePrice * royalties[getType(_tokenId)]) / ONE_HUNDRED_PERCENT);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage, IERC165, ERC721Enumerable) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || ERC721URIStorage.supportsInterface(interfaceId) || ERC721Enumerable.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {   
        return ERC721Enumerable._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 amount) internal override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._increaseBalance(account, amount);
    }

}
