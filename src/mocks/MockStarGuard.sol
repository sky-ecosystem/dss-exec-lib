// SPDX-License-Identifier: AGPL-3.0-or-later
//
// MockStarGuard.sol -- Mock Star Guard for testing
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

contract MockStarGuard {
    address public plottedAddr;
    bytes32 public plottedTag;
    bool public shouldFail;

    function setShouldFail(bool _shouldFail) external {
        shouldFail = _shouldFail;
    }

    function plot(address addr_, bytes32 tag_) external {
        require(!shouldFail, "MockStarGuard/plot-failed");
        plottedAddr = addr_;
        plottedTag = tag_;
    }

    function drop() external {
        require(!shouldFail, "MockStarGuard/drop-failed");
        plottedAddr = address(0);
        plottedTag = bytes32(0);
    }
}
