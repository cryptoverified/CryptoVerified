// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/ICVConfigure.sol";

contract CVNftBase is Ownable {
    /**
     * @dev random salt
     */
    uint256 public salt;
    /**
     * @dev CVCategoryState: 0: picture; 1: piece
     */
    enum CVCategoryState {PICTURE, PIECE}
    /**
     * @dev incomeAddress
     */
    address public incomeAddress;

    /**
     * @dev BUSD ERC20 contract address
     */
    ERC20 public busd;

    /**
     * @dev CVC ERC20 contract address
     */
    ERC20 public cvcToken;

    /**
     * @dev cv config contract address for extract cards.
     */
    ICVCfg public cvCfg;

    /* ========== PUZZLE STRUCT ========== */

    /**
     * @dev Everything about your Puzzle is stored in here. Each Puzzle's appearance
     * is determined by the gene.
     */
    struct Puzzle {
        //The Puzzle name and desc determined by rolenum
        uint256 roleNum;
        //The Puzzle level
        uint256 level;
        // The Puzzle NFT category
        uint256 category;
        // The piece count of Puzzle
        uint256 pieceCount;
        // The piece number of Puzzle
        uint256 pieceNumber;
        // The power of Puzzle
        uint256 power;
        // The worth of Puzzle
        uint256 worth;
        // the role sequence of Puzzle
        uint256 roleSequence;
        // the piece sequence of Puzzle
        uint256 pieceSequence;
        // the issue capicaty of piece for the role
        uint256 capicaty;
    }

    /**
     * @dev An array containing the Puzzle struct for all Puzzles in existence. The ID
     * of each Puzzle is the index into this array.
     */
    Puzzle[] internal puzzles;

    /**
     * @dev An mapping containing the count of the same role Puzzle and level in existence. The ID
     * of each Puzzle is the rolenum.
     */
    mapping(uint256 => mapping(uint256 => uint256)) internal roleCounts;

    /**
     * @dev An mapping containing the count of the same piece number in existence. The ID
     * of each Puzzle is the rolenum.
     */
    mapping(uint256 => mapping(uint256 => uint256)) internal rolePieceNumCounts;

    /**
     * @dev An mapping containing the NFT tokeID and gene sequence.
     */
    mapping(uint256 => uint256) public genes;
}
