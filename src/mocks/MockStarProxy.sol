// SPDX-License-Identifier: AGPL-3.0-or-later
//
// MockStarProxy.sol -- Mock Star Proxy for testing
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

contract MockStarProxy {
    // Storage layout must match MockStarSpell for delegatecall to work properly
    bool public executed;
    bool public shouldFail;

    // Proxy-specific storage (must come after the shared storage)
    address public lastTarget;
    bytes public lastData;

    function setShouldFail(bool _shouldFail) external {
        shouldFail = _shouldFail;
    }

    function exec(address target, bytes calldata args) external returns (bytes memory out) {
        lastTarget = target;
        lastData = args;

        // Use delegatecall to execute the spell's function
        bool ok;
        (ok, out) = target.delegatecall(args);
        require(ok, "MockStarProxy/delegatecall-error");
    }
}
