// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ICVCfg {
    function getCards(uint256 _seed, uint256 _blindnum)
        external
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );
}
