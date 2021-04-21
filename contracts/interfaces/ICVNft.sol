// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interfaces/ICVConfigure.sol";

interface ICVNft is IERC721 {
    function getCard(uint256 _id)
        external
        view
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
        );
}
