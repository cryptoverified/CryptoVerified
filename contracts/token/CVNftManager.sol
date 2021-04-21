// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./CVNft.sol";
import "../interfaces/ICVNft.sol";
import "../interfaces/ICVConfigure.sol";

contract CVNftManager is CVNft, ICVNft, ReentrancyGuard, Pausable {
    /**
     * @dev Initializes Puzzle core contract.
     * @param _busd BUSD ERC20 contract address
     * @param _dev income address.
     * @param _cvCfg Puzzle strategy contract address.
     */
    constructor(
        address _busd,
        address _cvc,
        ICVCfg _cvCfg,
        address _dev
    ) public {
        _registerInterface(_INTERFACE_ID_ERC721);

        busd = ERC20(_busd);
        cvcToken = ERC20(_cvc);
        cvCfg = _cvCfg;
        incomeAddress = _dev;
    }

    /* ========== EVENTS ========== */

    // The Lotteryed event is fired when extract a new card.
    event EventLottery(uint256 indexed tokenId, uint256 geneId);

    // The Puzzled event is fired when puzzled a new card.
    event EventCompoundedBatch(uint256 indexed tokenId, uint256 geneId);

    // create an new order
    event PostOrder(
        address indexed seller,
        uint256 indexed tokenId,
        address indexed token,
        uint256 price
    );
    // cancel a selling order
    event CancelOrder(address indexed seller, uint256 indexed tokenId);
    // deal a selling order
    event DealOrder(
        address indexed buyer,
        address indexed seller,
        uint256 indexed tokenId,
        address token,
        uint256 price
    );

    /* ========== VIEWS ========== */

    /**
     * Returns all the relevant information about a specific Puzzle.
     * @param _id The token ID of the Puzzle of interest.
     */
    function getCard(uint256 _id)
        external
        view
        override
        returns (
            uint256 tokenid,
            uint256 geneid,
            uint256 roleid,
            uint256 category,
            uint256 level,
            uint256 piececount,
            uint256 piecenumber,
            uint256 power,
            uint256 worth,
            uint256 roleSequence,
            uint256 pieceSequence,
            uint256 capicaty
        )
    {
        tokenid = _id;
        geneid = genes[_id];
        require(geneid > 0, "CVNftManager: GeneID is invalid");
        Puzzle storage _puzzle = puzzles[tokenid];
        roleid = _puzzle.roleNum;
        category = _puzzle.category;
        level = _puzzle.level;
        piececount = _puzzle.pieceCount;
        piecenumber = _puzzle.pieceNumber;
        power = _puzzle.power;
        worth = _puzzle.worth;
        roleSequence = _puzzle.roleSequence;
        pieceSequence = _puzzle.pieceSequence;
        capicaty = _puzzle.capicaty;
    }

    /**
     * @dev buy blind box by cost busd
     * @param _blindNum a blind number od blind box
     */
    function buyBlind(uint256 _blindNum, uint256 _count) external {
        address msgsender = msg.sender;
        require(
            _blindNum > 0 && _blindNum < 4,
            "CVNftManager: blindnum is invalid"
        );

        require(_count > 0, "CVNftManager: count must be more than zero");

        (uint256 costvalue, bool isBusd) = cvCfg.getPrice(_blindNum);
        uint256 totalAmount = costvalue.mul(_count);

        if (isBusd) {
            totalAmount = totalAmount.mul(10**uint256(busd.decimals()));
            require(
                busd.allowance(msgsender, address(this)) >= totalAmount,
                "CVNftManager: Required BUSD fee has not been approved"
            );

            require(busd.transferFrom(msg.sender, incomeAddress, totalAmount));
        }
    }

    /**
     * @dev lotteryed a new card
     * @param _blindnum a blind number od blind box
     * @param _randnum a random seed
     * @return tokenID The lotteryed tokenid and geneid
     */
    function lottery(uint256 _blindnum, uint256 _randnum)
        external
        returns (uint256 tokenID, uint256 geneID)
    {
        address msgsender = msg.sender;
        require(_randnum > 0, "CVNftManager: randnum is zero");

        //call Puzzle strategy contract
        salt = _randnum;

        (
            uint256 roleNum,
            uint256 level,
            uint256 pieceCount,
            uint256 pieceNumber
        ) = cvCfg.getCards(salt, _blindnum);
        require(pieceCount > 0, "CVNftManager: the count of piece is not set");

        uint256 pieceCap = cvCfg.getPieceCap(roleNum);

        uint256 rolePieceCount = rolePieceNumCounts[roleNum][pieceNumber];

        require(
            rolePieceCount < pieceCap,
            "CVNftManager: the piece count is more than the capicaty"
        );

        uint256 power = cvCfg.powerBy(level);
        uint256 value = cvCfg.valueBy(level);

        Puzzle memory _puzzle =
            Puzzle({
                roleNum: roleNum,
                level: level,
                category: uint256(CVCategoryState.PIECE),
                pieceCount: pieceCount,
                pieceNumber: pieceNumber,
                power: power,
                worth: value,
                roleSequence: 0,
                pieceSequence: rolePieceCount,
                capicaty: pieceCap
            });

        //category is piece
        (tokenID, geneID) = _createPiece(_puzzle, msgsender);

        rolePieceNumCounts[roleNum][pieceNumber] = rolePieceCount.add(1);

        emit EventLottery(tokenID, geneID);

        return (tokenID, geneID);
    }

    /**
     * @dev multi compount Puzzle
     * @param _tokenList an array of tokenid
     * @return The tokenid and geneid of the compound Puzzle
     */
    function compoundBatch(uint256[] memory _tokenList)
        external
        returns (uint256, uint256)
    {
        require(
            (_tokenList.length % 2) == 0,
            "CVNftManager: Length is not valid"
        );

        require(
            _tokenList.length > 1,
            "CVNftManager: Length is not more than one"
        );
        Puzzle memory _puzzle0 = puzzles[_tokenList[0]];
        _burn(_tokenList[0]);

        uint256 roleNum = _puzzle0.roleNum;
        uint256 level = _puzzle0.level;
        uint256 pieceCount = _puzzle0.pieceCount;
        uint256 pieceNumber = _puzzle0.pieceNumber;

        require(
            pieceCount == _tokenList.length,
            "CVNftManager: Piece count is not equal"
        );

        Puzzle memory _puzzle =
            Puzzle({
                roleNum: roleNum,
                level: level,
                category: uint256(CVCategoryState.PICTURE),
                pieceCount: pieceCount,
                pieceNumber: 0,
                power: _puzzle0.power,
                worth: _puzzle0.worth,
                roleSequence: 0,
                pieceSequence: 0,
                capicaty: 0
            });

        for (uint256 i = 1; i < _tokenList.length; ++i) {
            uint256 _tokenID = _tokenList[i];
            Puzzle memory _puzzleitem = puzzles[_tokenID];
            require(
                roleNum == _puzzleitem.roleNum,
                "CVNftManager: The type of role is not same"
            );

            require(
                level == _puzzleitem.level,
                "CVNftManager: The level of Puzzle is not same"
            );

            require(
                _puzzleitem.pieceCount == pieceCount,
                "CVNftManager: The piece count of the Puzzle is not two"
            );

            require(
                pieceNumber != _puzzleitem.pieceNumber,
                "CVNftManager: The piece number of Puzzle piece is same"
            );

            pieceNumber = _puzzleitem.pieceNumber;

            _puzzle.power = _puzzle.power.add(_puzzleitem.power);
            _puzzle.worth = _puzzle.worth.add(_puzzleitem.worth);

            require(
                _isApprovedOrOwner(address(this), _tokenID),
                "CVNftManager: Permission is not allow"
            );
            _burn(_tokenID);
        }

        (uint256 tokenID, uint256 geneID) = _createPicture(_puzzle, msg.sender);

        emit EventCompoundedBatch(tokenID, geneID);
        return (tokenID, geneID);
    }

    /**
     * @dev burn NFT
     * @param _tokenID nft tokenID
     * @param  _from the token address of platform
     */
    function burn(uint256 _tokenID, address _from) external {
        require(
            ownerOf(_tokenID) == msg.sender,
            "CVNftManager: Sender is not owner"
        );

        Puzzle storage _puzzle = puzzles[_tokenID];
        uint256 amount = _puzzle.worth;

        amount = amount.mul(10**uint256(cvcToken.decimals()));

        require(
            cvcToken.allowance(_from, address(this)) >= amount,
            "CVNftManager: Required CVC fee not allowance"
        );

        require(
            cvcToken.transferFrom(_from, msg.sender, amount),
            "CVNftManager: CVC token not sent"
        );

        require(
            _isApprovedOrOwner(address(this), _tokenID),
            "CVNftManager: Permission is not allow"
        );
        _burn(_tokenID);
    }

    function setIncomeAccount(address _dev) external onlyOwner {
        incomeAddress = _dev;
    }
}
