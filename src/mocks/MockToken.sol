// SPDX-License-Identifier: AGPL-3.0-or-later
//
// MockToken.sol -- Mock Token for testing
//
// Copyright (C) 2022-2025 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.16;

contract MockToken {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    string public symbol;
    uint8 public decimals = 18; // standard token precision. override to customize
    string public name = ""; // Optional token name

    constructor(string memory symbol_) {
        symbol = symbol_;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        return true;
    }

    function transfer(address dst, uint256 wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint256 wad) public returns (bool) {
        if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
            require(allowance[src][msg.sender] >= wad, "ds-token-insufficient-approval");
            allowance[src][msg.sender] = allowance[src][msg.sender] - wad;
        }

        require(balanceOf[src] >= wad, "ds-token-insufficient-balance");
        balanceOf[src] = balanceOf[src] - wad;
        balanceOf[dst] = balanceOf[dst] + wad;

        return true;
    }

    function mint(address guy, uint256 wad) public {
        balanceOf[guy] = balanceOf[guy] + wad;
        totalSupply = totalSupply + wad;
    }

    function burn(address guy, uint256 wad) public {
        if (guy != msg.sender && allowance[guy][msg.sender] != type(uint256).max) {
            require(allowance[guy][msg.sender] >= wad, "ds-token-insufficient-approval");
            allowance[guy][msg.sender] = allowance[guy][msg.sender] - wad;
        }

        require(balanceOf[guy] >= wad, "ds-token-insufficient-balance");
        balanceOf[guy] = balanceOf[guy] - wad;
        totalSupply = totalSupply - wad;
    }
}
