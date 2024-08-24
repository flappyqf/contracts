// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockUSDC is ERC20, Ownable {
    uint8 private constant DECIMALS = 6;
    uint256 private constant DECIMAL_FACTOR = 10 ** DECIMALS;

    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) Ownable(msg.sender) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount * DECIMAL_FACTOR);
    }

    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        require(
            amount % DECIMAL_FACTOR == 0,
            "Amount must be a multiple of 10^6"
        );
        return super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        require(
            amount % DECIMAL_FACTOR == 0,
            "Amount must be a multiple of 10^6"
        );
        return super.transferFrom(from, to, amount);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account);
    }

    function totalSupply() public view override returns (uint256) {
        return super.totalSupply();
    }
}
