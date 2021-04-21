// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./CVNftBase.sol";

contract CVNft is CVNftBase, ERC721("CV NFT", "CV") {
    using SafeMath for uint256;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 internal constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /**
     * @dev Magic value of a smart contract that can recieve NFT.
     * Equal to: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")).
     */
    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    /* ========== VIEWS ========== */

    /* ========== OWNER MUTATIVE FUNCTION ========== */

    /**
     * @dev Allow contract owner to create Puzzle
     */
    function _createPiece(Puzzle memory _puzzle, address _owner)
        internal
        returns (uint256, uint256)
    {
        puzzles.push(_puzzle);
        uint256 tokenID = puzzles.length - 1;

        _mint(_owner, tokenID);

        uint256 geneRole = uint256((_puzzle.roleNum & uint256(0xff)) << 16);
        uint256 geneLevel = uint256((_puzzle.level & uint256(0xff)) << 8);

        uint256 geneID = geneRole.add(geneLevel);
        genes[tokenID] = geneID;
        return (tokenID, geneID);
    }

    /**
     * @dev Allow contract owner to create Puzzle
     */
    function _createPicture(Puzzle memory _puzzle, address _owner)
        internal
        returns (uint256, uint256)
    {
        _puzzle.power = _puzzle.power.mul(cvCfg.getPowerOverflow()).div(10);
        _puzzle.worth = _puzzle.worth.mul(cvCfg.getValueOverflow()).div(10);

        uint256 _combinedSequence = roleCounts[_puzzle.roleNum][_puzzle.level];
        _puzzle.roleSequence = _combinedSequence;

        puzzles.push(_puzzle);
        uint256 tokenID = puzzles.length - 1;

        _mint(_owner, tokenID);

        roleCounts[_puzzle.roleNum][_puzzle.level] = _combinedSequence.add(1);

        uint256 geneRole = uint256((_puzzle.roleNum & uint256(0xff)) << 16);
        uint256 geneLevel = uint256((_puzzle.level & uint256(0xff)) << 284);

        uint256 geneID = geneRole.add(geneLevel);

        genes[tokenID] = geneID;

        return (tokenID, geneID);
    }
}
