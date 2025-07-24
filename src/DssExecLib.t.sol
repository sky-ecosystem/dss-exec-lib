// SPDX-License-Identifier: AGPL-3.0-or-later
//
// DssExecLib.t.sol -- DssExecLib Tests
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

import "forge-std/Test.sol";
import {DssExecLib} from "./DssExecLib.sol";

// This contract uses DssExecLib to verify it can be used in a contract
contract DssExecLibUser {
    using DssExecLib for *;

    function checkLibraryCall() public pure returns (uint256) {
        // Just call a simple function from the library to ensure it's usable
        return DssExecLib.WAD;
    }
}

contract DssExecLibTest is Test {
    function setUp() public {}

    function test_DssExecLibSize() public {
        // Get the creation code of DssExecLib
        bytes memory creationCode = type(DssExecLib).creationCode;
        uint256 creationSize = creationCode.length;

        // Get the runtime code of DssExecLib
        bytes memory runtimeCode = type(DssExecLib).runtimeCode;
        uint256 runtimeSize = runtimeCode.length;

        // Log the sizes for debugging
        emit log_named_uint("DssExecLib creation code size (bytes)", creationSize);
        emit log_named_uint("DssExecLib runtime code size (bytes)", runtimeSize);

        // Ethereum contract size limit is 24KB (24576 bytes)
        uint256 MAX_CONTRACT_SIZE = 24576;

        // Assert that the runtime size is within limits
        assertTrue(
            runtimeSize <= MAX_CONTRACT_SIZE,
            string(
                abi.encodePacked(
                    "DssExecLib exceeds maximum contract size limit: ",
                    vm.toString(runtimeSize),
                    " > ",
                    vm.toString(MAX_CONTRACT_SIZE)
                )
            )
        );

        // Create a contract that uses the library to ensure it's usable
        DssExecLibUser user = new DssExecLibUser();
        assertEq(user.checkLibraryCall(), 10 ** 18, "Library function call failed");
    }
}
