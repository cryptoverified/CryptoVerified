// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CVDToken is ERC20Burnable, Ownable {
    constructor(string memory name, string memory symbol)
        public
        ERC20(name, symbol)
    {}

    function burn(uint256 _amount) public virtual override {
        _burn(_msgSender(), _amount);
    }

    function burnFrom(address _from, uint256 _amount) public virtual override {
        uint256 decreasedAllowance =
            allowance(_from, _msgSender()).sub(
                _amount,
                "ERC20: burn amount exceeds allowance"
            );

        _approve(_from, _msgSender(), decreasedAllowance);
        _burn(_from, _amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }
}
