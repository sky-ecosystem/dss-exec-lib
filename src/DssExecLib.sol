// SPDX-FileCopyrightText: 2025 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
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

import {CollateralOpts} from "./CollateralOpts.sol";

interface Initializable {
    function init(bytes32) external;
}

interface Authorizable {
    function rely(address) external;
    function deny(address) external;
    function setAuthority(address) external;
}

interface Kissable {
    function kiss(address) external;
    function diss(address) external;
    function bud(address) external view returns (uint256);
}

interface Fileable {
    function file(bytes32, address) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, bytes32, address) external;
}

interface Drippable {
    function drip() external returns (uint256);
    function drip(bytes32) external returns (uint256);
}

interface Pokeable {
    function poke(bytes32) external;
}

interface ERC20 {
    function decimals() external returns (uint8);
}

interface DssVat {
    function hope(address) external;
    function nope(address) external;
    function ilks(bytes32) external returns (uint256 Art, uint256 rate, uint256 spot, uint256 line, uint256 dust);
    function Line() external view returns (uint256);
    function suck(address, address, uint256) external;
}

interface PauseLike {
    function setDelay(uint256) external;
}

interface ClipLike {
    function vat() external returns (address);
    function dog() external returns (address);
    function spotter() external view returns (address);
    function calc() external view returns (address);
    function ilk() external returns (bytes32);
}

interface DogLike {
    function ilks(bytes32) external returns (address clip, uint256 chop, uint256 hole, uint256 dirt);
}

interface JoinLike {
    function vat() external returns (address);
    function ilk() external returns (bytes32);
    function gem() external returns (address);
    function dec() external returns (uint256);
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

interface OsmLike is Kissable {
    function src() external view returns (address);
}

interface OsmMomLike {
    function setOsm(bytes32, address) external;
}

interface ClipperMomLike {
    function setPriceTolerance(address, uint256) external;
}

interface RegistryLike {
    function add(address) external;
    function xlip(bytes32) external view returns (address);
}

// https://github.com/makerdao/dss-chain-log
interface ChainlogLike {
    function setVersion(string calldata) external;
    function setIPFS(string calldata) external;
    function setSha256sum(string calldata) external;
    function getAddress(bytes32) external view returns (address);
    function setAddress(bytes32, address) external;
    function removeAddress(bytes32) external;
}

interface IAMLike {
    function ilks(bytes32) external view returns (uint256, uint256, uint48, uint48, uint48);
    function setIlk(bytes32, uint256, uint256, uint256) external;
    function remIlk(bytes32) external;
}

interface LerpFactoryLike {
    function newLerp(
        bytes32 name_,
        address target_,
        bytes32 what_,
        uint256 startTime_,
        uint256 start_,
        uint256 end_,
        uint256 duration_
    ) external returns (address);
    function newIlkLerp(
        bytes32 name_,
        address target_,
        bytes32 ilk_,
        bytes32 what_,
        uint256 startTime_,
        uint256 start_,
        uint256 end_,
        uint256 duration_
    ) external returns (address);
}

interface LerpLike {
    function tick() external returns (uint256);
}

interface RwaOracleLike {
    function bump(bytes32 ilk, uint256 val) external;
}

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

/// @title DssExecLib - Sky Protocol's Executive Spellcrafting Library
/// @notice This library provides a suite of functions for managing the Sky Protocol.
/// @dev Includes functions for collateral management, system configuration, governance, and more.
library DssExecLib {
    /* ----- Constants ----- */

    address public constant LOG = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;

    uint256 internal constant THOUSAND = 10 ** 3;
    uint256 internal constant MILLION = 10 ** 6;
    uint256 internal constant WAD = 10 ** 18;
    uint256 internal constant RAY = 10 ** 27;
    uint256 internal constant RAD = 10 ** 45;

    uint256 internal constant BPS_ONE_HUNDRED_PCT = 100_00;
    uint256 internal constant RATES_ONE_HUNDRED_PCT = 1000000021979553151239153027;

    /* ----- Math Functions ----- */

    /// @dev WAD division. The final result is rounded to the nearest integer.
    /// Examples:
    ///     wdiv(1, 2) = 0.5      * WAD = 500000000000000000
    ///     wdiv(2, 3) = 0.666... * WAD = 666666666666666667
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * WAD + y / 2) / y;
    }

    /// @dev RAY division. The final result is rounded to the nearest integer.
    /// Examples:
    ///     rdiv(1, 2) = 0.5      * RAY = 500000000000000000000000000
    ///     rdiv(2, 3) = 0.666... * RAY = 666666666666666666666666667
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * RAY + y / 2) / y;
    }

    /* ----- Core Address Helpers ----- */

    /// @notice Get the DAI token contract address from the changelog
    /// @return The address of the DAI token contract
    function dai() public view returns (address) {
        return getChangelogAddress("MCD_DAI");
    }

    /// @notice Get the USDS token contract address from the changelog
    /// @return The address of the USDS token contract
    function usds() public view returns (address) {
        return getChangelogAddress("USDS");
    }

    /// @notice Get the MKR token contract address from the changelog
    /// @return The address of the MKR token contract
    function mkr() public view returns (address) {
        return getChangelogAddress("MKR");
    }

    /// @notice Get the SKY token contract address from the changelog
    /// @return The address of the SKY token contract
    function sky() public view returns (address) {
        return getChangelogAddress("SKY");
    }

    /// @notice Get the VAT (accounting core) contract address from the changelog
    /// @return The address of the VAT contract
    function vat() public view returns (address) {
        return getChangelogAddress("MCD_VAT");
    }

    /// @notice Get the DOG (liquidation module) contract address from the changelog
    /// @return The address of the DOG contract
    function dog() public view returns (address) {
        return getChangelogAddress("MCD_DOG");
    }

    /// @notice Get the JUG (stability fee collector) contract address from the changelog
    /// @return The address of the JUG contract
    function jug() public view returns (address) {
        return getChangelogAddress("MCD_JUG");
    }

    /// @notice Get the POT (DAI Savings Rate) contract address from the changelog
    /// @return The address of the POT contract
    function pot() public view returns (address) {
        return getChangelogAddress("MCD_POT");
    }

    /// @notice Get the SUSDS (SKY Savings Rate) contract address from the changelog
    /// @return The address of the SUSDS contract
    function susds() public view returns (address) {
        return getChangelogAddress("SUSDS");
    }

    /// @notice Get the VOW (system surplus and debt manager) contract address from the changelog
    /// @return The address of the VOW contract
    function vow() public view returns (address) {
        return getChangelogAddress("MCD_VOW");
    }

    /// @notice Get the END (emergency shutdown) contract address from the changelog
    /// @return The address of the END contract
    function end() public view returns (address) {
        return getChangelogAddress("MCD_END");
    }

    /// @notice Get the ESM (emergency shutdown module) contract address from the changelog
    /// @return The address of the ESM contract
    function esm() public view returns (address) {
        return getChangelogAddress("MCD_ESM");
    }

    /// @notice Get the ILK_REGISTRY (collateral registry) contract address from the changelog
    /// @return The address of the ILK_REGISTRY contract
    function reg() public view returns (address) {
        return getChangelogAddress("ILK_REGISTRY");
    }

    /// @notice Get the SPOTTER (price feed interface) contract address from the changelog
    /// @return The address of the SPOTTER contract
    function spotter() public view returns (address) {
        return getChangelogAddress("MCD_SPOT");
    }

    /// @notice Get the FLAP (surplus auction) contract address from the changelog
    /// @return The address of the FLAP contract
    function flap() public view returns (address) {
        return getChangelogAddress("MCD_FLAP");
    }

    /// @notice Get the FLOP (debt auction) contract address from the changelog
    /// @return The address of the FLOP contract
    function flop() public view returns (address) {
        return getChangelogAddress("MCD_FLOP");
    }

    /// @notice Get the OSM_MOM (oracle security module mom) contract address from the changelog
    /// @return The address of the OSM_MOM contract
    function osmMom() public view returns (address) {
        return getChangelogAddress("OSM_MOM");
    }

    /// @notice Get the GOV_GUARD (governance guard) contract address from the changelog
    /// @return The address of the GOV_GUARD contract
    function govGuard() public view returns (address) {
        return getChangelogAddress("GOV_GUARD");
    }

    /// @notice Get the CLIPPER_MOM (liquidation circuit breaker) contract address from the changelog
    /// @return The address of the CLIPPER_MOM contract
    function clipperMom() public view returns (address) {
        return getChangelogAddress("CLIPPER_MOM");
    }

    /// @notice Get the PAUSE_PROXY (governance proxy) contract address from the changelog
    /// @return The address of the PAUSE_PROXY contract
    function pauseProxy() public view returns (address) {
        return getChangelogAddress("MCD_PAUSE_PROXY");
    }

    /// @notice Get the IAM_AUTO_LINE (auto debt ceiling adjuster) contract address from the changelog
    /// @return The address of the IAM_AUTO_LINE contract
    function autoLine() public view returns (address) {
        return getChangelogAddress("MCD_IAM_AUTO_LINE");
    }

    /// @notice Get the DAI_JOIN (DAI token adapter) contract address from the changelog
    /// @return The address of the DAI_JOIN contract
    function daiJoin() public view returns (address) {
        return getChangelogAddress("MCD_JOIN_DAI");
    }

    /// @notice Get the USDS_JOIN (USDS token adapter) contract address from the changelog
    /// @return The address of the USDS_JOIN contract
    function usdsJoin() public view returns (address) {
        return getChangelogAddress("USDS_JOIN");
    }

    /// @notice Get the LERP_FAB (linear interpolation factory) contract address from the changelog
    /// @return The address of the LERP_FAB contract
    function lerpFab() public view returns (address) {
        return getChangelogAddress("LERP_FAB");
    }

    /// @notice Get the PAUSE (governance delay) contract address from the changelog
    /// @return The address of the PAUSE contract
    function pause() public view returns (address) {
        return getChangelogAddress("MCD_PAUSE");
    }

    /// @notice Get the collateral liquidation contract address for a given ilk
    /// @param _ilk The collateral type identifier
    /// @return _clip The address of the liquidation contract for the given ilk
    function clip(bytes32 _ilk) public view returns (address _clip) {
        _clip = RegistryLike(reg()).xlip(_ilk);
    }

    /// @notice Get the collateral auction contract address for a given ilk (legacy)
    /// @param _ilk The collateral type identifier
    /// @return _flip The address of the auction contract for the given ilk
    function flip(bytes32 _ilk) public view returns (address _flip) {
        _flip = RegistryLike(reg()).xlip(_ilk);
    }

    /// @notice Get the pricing calculator contract address for a given ilk
    /// @param _ilk The collateral type identifier
    /// @return _calc The address of the pricing calculator contract for the given ilk
    function calc(bytes32 _ilk) public view returns (address _calc) {
        _calc = ClipLike(clip(_ilk)).calc();
    }

    /// @dev Get an address from the chainlog.
    /// @dev Reverts if the key does not exist
    /// @param _key Access key for the address (e.g. "MCD_VAT")
    /// @return The address associated with the key
    function getChangelogAddress(bytes32 _key) public view returns (address) {
        return ChainlogLike(LOG).getAddress(_key);
    }

    /* ----- Changelog Management ----- */

    /// @dev Set an address in the Sky Protocol on-chain changelog.
    /// @param _key Access key for the address (e.g. "MCD_VAT")
    /// @param _val The address associated with the _key
    function setChangelogAddress(bytes32 _key, address _val) public {
        ChainlogLike(LOG).setAddress(_key, _val);
    }

    /// @dev Remove an address from the Sky Protocol on-chain changelog.
    /// @param _key Access key for the address to remove (e.g. "MCD_VAT")
    function removeChangelogAddress(bytes32 _key) public {
        ChainlogLike(LOG).removeAddress(_key);
    }

    /// @dev Set version in the Sky Protocol on-chain changelog.
    /// @param _version Changelog version (e.g. "1.1.2")
    function setChangelogVersion(string memory _version) public {
        ChainlogLike(LOG).setVersion(_version);
    }

    /// @dev Set IPFS hash of IPFS changelog in Sky Protocol on-chain changelog.
    /// @param _ipfsHash IPFS hash (e.g. "QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW")
    function setChangelogIPFS(string memory _ipfsHash) public {
        ChainlogLike(LOG).setIPFS(_ipfsHash);
    }

    /// @dev Set SHA256 hash in Sky Protocol on-chain changelog.
    /// @param _SHA256Sum SHA256 hash (e.g. "e42dc9d043a57705f3f097099e6b2de4230bca9a020c797508da079f9079e35b")
    function setChangelogSHA256(string memory _SHA256Sum) public {
        ChainlogLike(LOG).setSha256sum(_SHA256Sum);
    }

    /* ----- Authorizations ----- */

    /// @dev Give an address authorization to perform auth actions on the contract.
    /// @param _base The address of the contract where the authorization will be set
    /// @param _ward Address to be authorized
    function authorize(address _base, address _ward) public {
        Authorizable(_base).rely(_ward);
    }

    /// @dev Revoke contract authorization from an address.
    /// @param _base The address of the contract where the authorization will be revoked
    /// @param _ward Address to be deauthorized
    function deauthorize(address _base, address _ward) public {
        Authorizable(_base).deny(_ward);
    }

    /// @dev Adds an address to a contract's whitelist
    /// @param _target Address of a contract that implements the kiss() function
    /// @param _usr Address to add to whitelist
    function addToWhitelist(address _target, address _usr) public {
        Kissable(_target).kiss(_usr);
    }

    /// @dev Removes an address from a contract's whitelist
    /// @param _target Address of a contract that implements the diss() function
    /// @param _usr Address to remove from whitelist
    function removeFromWhitelist(address _target, address _usr) public {
        Kissable(_target).diss(_usr);
    }

    /// @dev Set the authority contract that manages access control for the target contract.
    /// @param _base The address of the contract where the authority will be set
    /// @param _authority Address of the authority contract that will manage privileged access (e.g., Chief managing who can call the Pause contract)
    function setAuthority(address _base, address _authority) public {
        Authorizable(_base).setAuthority(_authority);
    }

    /// @dev Delegate vat authority to the specified address.
    /// @param _usr Address to be authorized
    function delegateVat(address _usr) public {
        DssVat(vat()).hope(_usr);
    }

    /// @dev Revoke vat authority to the specified address.
    /// @param _usr Address to be deauthorized
    function undelegateVat(address _usr) public {
        DssVat(vat()).nope(_usr);
    }

    /* ----- OfficeHours Management ----- */

    /// @dev Returns true if a time is within office hours range
    /// @param _ts The timestamp to check, usually block.timestamp
    /// @param _officeHours true if office hours is enabled.
    /// @return true if time is in castable range
    function canCast(uint40 _ts, bool _officeHours) public pure returns (bool) {
        if (_officeHours) {
            uint256 day = (_ts / 1 days + 3) % 7;
            if (day >= 5) return false; // Can only be cast on a weekday
            uint256 hour = _ts / 1 hours % 24;
            if (hour < 14 || hour >= 21) return false; // Outside office hours
        }
        return true;
    }

    /// @dev Calculate the next available cast time in epoch seconds
    /// @param _eta The scheduled time of the spell plus the pause delay
    /// @param _ts The current timestamp, usually block.timestamp
    /// @param _officeHours true if office hours is enabled.
    /// @return castTime The next available cast timestamp
    function nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) public pure returns (uint256 castTime) {
        require(_eta != 0); // "DssExecLib/invalid eta"
        require(_ts != 0); // "DssExecLib/invalid ts"
        castTime = _ts > _eta ? _ts : _eta; // Any day at XX:YY

        if (_officeHours) {
            uint256 day = (castTime / 1 days + 3) % 7;
            uint256 hour = castTime / 1 hours % 24;
            uint256 minute = castTime / 1 minutes % 60;
            uint256 second = castTime % 60;

            if (day >= 5) {
                castTime += (6 - day) * 1 days; // Go to Sunday XX:YY
                castTime += (24 - hour + 14) * 1 hours; // Go to 14:YY UTC Monday
                castTime -= minute * 1 minutes + second; // Go to 14:00 UTC
            } else {
                if (hour >= 21) {
                    if (day == 4) castTime += 2 days; // If Friday, fast forward to Sunday XX:YY
                    castTime += (24 - hour + 14) * 1 hours; // Go to 14:YY UTC next day
                    castTime -= minute * 1 minutes + second; // Go to 14:00 UTC
                } else if (hour < 14) {
                    castTime += (14 - hour) * 1 hours; // Go to 14:YY UTC same day
                    castTime -= minute * 1 minutes + second; // Go to 14:00 UTC
                }
            }
        }
    }

    /* ----- Accumulating Rates ----- */

    /// @dev Update rate accumulation for the Dai Savings Rate (DSR).
    function accumulateDSR() public {
        Drippable(pot()).drip();
    }

    /// @dev Update rate accumulation for the Sky Savings Rate (SSR).
    function accumulateSSR() public {
        Drippable(susds()).drip();
    }

    /// @dev Update rate accumulation for the stability fees of a given collateral type.
    /// @param _ilk Collateral type
    function accumulateCollateralStabilityFees(bytes32 _ilk) public {
        Drippable(jug()).drip(_ilk);
    }

    /* ----- Price Updates ----- */

    /// @dev Update price of a given collateral type.
    /// @param _ilk Collateral type
    function updateCollateralPrice(bytes32 _ilk) public {
        Pokeable(spotter()).poke(_ilk);
    }

    /* ----- System Configuration ----- */

    /// @dev Set a contract in another contract, defining the relationship (ex. set a new Calc contract in Clip)
    /// @param _base The address of the contract where the new contract address will be filed
    /// @param _what Name of contract to file
    /// @param _addr Address of contract to file
    function setContract(address _base, bytes32 _what, address _addr) public {
        Fileable(_base).file(_what, _addr);
    }

    /// @dev Set a contract in another contract, defining the relationship (ex. set a new Calc contract in a Clip)
    /// @param _base The address of the contract where the new contract address will be filed
    /// @param _ilk Collateral type
    /// @param _what Name of contract to file
    /// @param _addr Address of contract to file
    function setContract(address _base, bytes32 _ilk, bytes32 _what, address _addr) public {
        Fileable(_base).file(_ilk, _what, _addr);
    }

    /// @dev Set a value in a contract, via a governance authorized File pattern.
    /// @param _base The address of the contract where the new contract address will be filed
    /// @param _what Name of tag for the value (e.g. "Line")
    /// @param _amt The value to set or update
    function setValue(address _base, bytes32 _what, uint256 _amt) public {
        Fileable(_base).file(_what, _amt);
    }

    /// @dev Set an ilk-specific value in a contract, via a governance authorized File pattern.
    /// @param _base The address of the contract where the new value will be filed
    /// @param _ilk Collateral type
    /// @param _what Name of tag for the value (e.g. "Line")
    /// @param _amt The value to set or update
    function setValue(address _base, bytes32 _ilk, bytes32 _what, uint256 _amt) public {
        Fileable(_base).file(_ilk, _what, _amt);
    }

    /* ----- System Risk Parameters ----- */

    /// @dev Set the global debt ceiling. Amount will be converted to the correct internal precision.
    /// @param _amount The amount to set (ex. 10m amount == 10000000)
    function setGlobalDebtCeiling(uint256 _amount) public {
        require(_amount < WAD); // "LibDssExec/incorrect-global-Line-precision"
        setValue(vat(), "Line", _amount * RAD);
    }

    /// @dev Increase the global debt ceiling by a specific amount. Amount will be converted to the correct internal precision.
    /// @param _amount The amount to add (ex. 10m amount == 10000000)
    function increaseGlobalDebtCeiling(uint256 _amount) public {
        require(_amount < WAD); // "LibDssExec/incorrect-Line-increase-precision"
        address _vat = vat();
        setValue(_vat, "Line", DssVat(_vat).Line() + _amount * RAD);
    }

    /// @dev Decrease the global debt ceiling by a specific amount. Amount will be converted to the correct internal precision.
    /// @param _amount The amount to reduce (ex. 10m amount == 10000000)
    function decreaseGlobalDebtCeiling(uint256 _amount) public {
        require(_amount < WAD); // "LibDssExec/incorrect-Line-decrease-precision"
        address _vat = vat();
        setValue(_vat, "Line", DssVat(_vat).Line() - _amount * RAD);
    }

    /// @dev Set the Dai Savings Rate. See: docs/rates.txt
    /// @param _rate The accumulated rate (ex. 4% => 1000000001243680656318820312)
    /// @param _doDrip `true` to accumulate interest owed
    function setDSR(uint256 _rate, bool _doDrip) public {
        require((_rate >= RAY) && (_rate <= RATES_ONE_HUNDRED_PCT)); // "LibDssExec/dsr-out-of-bounds"
        if (_doDrip) Drippable(pot()).drip();
        setValue(pot(), "dsr", _rate);
    }

    /// @dev Set the SKY Savings Rate. See: docs/rates.txt
    /// @param _rate The accumulated rate (ex. 4% => 1000000001243680656318820312)
    /// @param _doDrip `true` to accumulate interest owed
    function setSSR(uint256 _rate, bool _doDrip) public {
        require((_rate >= RAY) && (_rate <= RATES_ONE_HUNDRED_PCT)); // "LibDssExec/ssr-out-of-bounds"
        if (_doDrip) Drippable(susds()).drip();
        setValue(susds(), "ssr", _rate);
    }

    /// @dev Set the amount for system surplus auctions. Amount will be converted to the correct internal precision.
    /// @param _amount The amount to set (ex. 10m amount == 10000000)
    function setSurplusAuctionAmount(uint256 _amount) public {
        require(_amount < WAD); // "LibDssExec/incorrect-vow-bump-precision"
        setValue(vow(), "bump", _amount * RAD);
    }

    /// @dev Set the amount for system surplus buffer, must be exceeded before surplus auctions start. Amount will be converted to the correct internal precision.
    /// @param _amount The amount to set (ex. 10m amount == 10000000)
    function setSurplusBuffer(uint256 _amount) public {
        require(_amount < WAD); // "LibDssExec/incorrect-vow-hump-precision"
        setValue(vow(), "hump", _amount * RAD);
    }

    /// @dev Set the minimum price threshold for surplus auctions. Amount will be converted to the correct internal precision.
    /// @dev Equation used for conversion is (pct / 10,000) * WAD
    /// @param _pct_bps The pct, in basis points, to set in integer form (x100). (ex. 5% = 5 * 100 = 500)
    function setSurplusAuctionMinPriceThreshold(uint256 _pct_bps) public {
        require(_pct_bps < BPS_ONE_HUNDRED_PCT); // "LibDssExec/incorrect-flap-beg-precision"
        setValue(flap(), "want", wdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
    }

    /// @dev Set the number of seconds that pass before system debt is auctioned for MKR tokens.
    /// @param _duration Duration in seconds
    function setDebtAuctionDelay(uint256 _duration) public {
        setValue(vow(), "wait", _duration);
    }

    /// @dev Set the debt amount for system debt to be covered by each debt auction. Amount will be converted to the correct internal precision.
    /// @param _amount The amount to set (ex. 10m debt amount == 10000000)
    function setDebtAuctionDebtAmount(uint256 _amount) public {
        require(_amount < WAD); // "LibDssExec/incorrect-vow-sump-precision"
        setValue(vow(), "sump", _amount * RAD);
    }

    /// @dev Set the starting governance token amount to be auctioned off to cover system debt in debt auctions. Amount will be converted to the correct internal precision.
    /// @param _amount The amount to set in governance tokens (ex. 250 governance token amount == 250)
    function setDebtAuctionGovAmount(uint256 _amount) public {
        require(_amount < WAD); // "LibDssExec/incorrect-vow-dump-precision"
        setValue(vow(), "dump", _amount * WAD);
    }

    /// @dev Set minimum bid increase for debt auctions. Amount will be converted to the correct internal precision.
    /// @dev Equation used for conversion is (1 + pct / 10,000) * WAD
    /// @param _pct_bps The pct, in basis points, to set in integer form (x100). (ex. 5% = 5 * 100 = 500)
    function setMinDebtAuctionBidIncrease(uint256 _pct_bps) public {
        require(_pct_bps < BPS_ONE_HUNDRED_PCT); // "LibDssExec/incorrect-flop-beg-precision"
        setValue(flop(), "beg", WAD + wdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
    }

    /// @dev Set bid duration for debt auctions.
    /// @param _duration Amount of time for bids. (seconds)
    function setDebtAuctionBidDuration(uint256 _duration) public {
        require(_duration < type(uint48).max); // "LibDssExec/incorrect-flop-ttl-precision"
        setValue(flop(), "ttl", _duration);
    }

    /// @dev Set total auction duration for debt auctions.
    /// @param _duration Amount of time for auctions. (seconds)
    function setDebtAuctionDuration(uint256 _duration) public {
        require(_duration < type(uint48).max); // "LibDssExec/incorrect-flop-tau-precision"
        setValue(flop(), "tau", _duration);
    }

    /// @dev Set the rate of increasing amount of MKR out for auction during debt auctions. Amount will be converted to the correct internal precision.
    /// @dev MKR amount is increased by this rate every "tick" (if auction duration has passed and no one has bid on the MKR)
    /// @dev Equation used for conversion is (1 + pct / 10,000) * WAD
    /// @param _pct_bps The pct, in basis points, to set in integer form (x100). (ex. 5% = 5 * 100 = 500)
    function setDebtAuctionMKRIncreaseRate(uint256 _pct_bps) public {
        require(_pct_bps < BPS_ONE_HUNDRED_PCT); // "LibDssExec/incorrect-flop-pad-precision"
        setValue(flop(), "pad", WAD + wdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
    }

    /// @dev Set the maximum total debt amount that can be out for liquidation in the system at any point. Amount will be converted to the correct internal precision.
    /// @param _amount The amount to set (ex. 250,000 debt units == 250000)
    function setMaxTotalDebtLiquidationAmount(uint256 _amount) public {
        require(_amount < WAD); // "LibDssExec/incorrect-dog-Hole-precision"
        setValue(dog(), "Hole", _amount * RAD);
    }

    /// @dev Set the duration of time that has to pass during emergency shutdown before collateral can start being claimed by DAI holders.
    /// @param _duration Time in seconds to set for ES processing time
    function setEmergencyShutdownProcessingTime(uint256 _duration) public {
        setValue(end(), "wait", _duration);
    }

    /// @dev Set the global stability fee (is not typically used, currently is 0).
    ///        Many of the settings that change weekly rely on the rate accumulator
    ///        described at https://docs.makerdao.com/smart-contract-modules/rates-module
    ///        To check this yourself, use the following rate calculation (example 8%):
    ///
    ///        $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    ///
    ///        A table of rates can also be found at:
    ///        https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    /// @param _rate The accumulated rate (ex. 4% => 1000000001243680656318820312)
    function setGlobalStabilityFee(uint256 _rate) public {
        require((_rate >= RAY) && (_rate <= RATES_ONE_HUNDRED_PCT)); // "LibDssExec/global-stability-fee-out-of-bounds"
        setValue(jug(), "base", _rate);
    }

    /// @dev Set the value of the stablecoin in the reference asset (e.g. $1 per unit). Value will be converted to the correct internal precision.
    /// @dev Equation used for conversion is value * RAY / 1000
    /// @param _value The value to set as integer (x1000) (ex. $1.025 == 1025)
    function setParity(uint256 _value) public {
        require(_value < WAD); // "LibDssExec/incorrect-par-precision"
        setValue(spotter(), "par", rdiv(_value, 1000));
    }

    /* ----- Collateral Management ----- */

    /// @dev Set a collateral debt ceiling. Amount will be converted to the correct internal precision.
    /// @param _ilk The ilk to update (ex. bytes32("ETH-A"))
    /// @param _amount The amount to set (ex. 10m amount == 10000000)
    function setIlkDebtCeiling(bytes32 _ilk, uint256 _amount) public {
        require(_amount < WAD); // "LibDssExec/incorrect-ilk-line-precision"
        setValue(vat(), _ilk, "line", _amount * RAD);
    }

    /// @dev Increase a collateral debt ceiling. Amount will be converted to the correct internal precision.
    /// @param _ilk The ilk to update (ex. bytes32("ETH-A"))
    /// @param _amount The amount to increase (ex. 10m amount == 10000000)
    /// @param _global If true, increases the global debt ceiling by _amount
    function increaseIlkDebtCeiling(bytes32 _ilk, uint256 _amount, bool _global) public {
        require(_amount < WAD); // "LibDssExec/incorrect-ilk-line-precision"
        address _vat = vat();
        (,,, uint256 line_,) = DssVat(_vat).ilks(_ilk);
        setValue(_vat, _ilk, "line", line_ + _amount * RAD);
        if (_global) increaseGlobalDebtCeiling(_amount);
    }

    /// @dev Decrease a collateral debt ceiling. Amount will be converted to the correct internal precision.
    /// @param _ilk The ilk to update (ex. bytes32("ETH-A"))
    /// @param _amount The amount to decrease (ex. 10m amount == 10000000)
    /// @param _global If true, decreases the global debt ceiling by _amount
    function decreaseIlkDebtCeiling(bytes32 _ilk, uint256 _amount, bool _global) public {
        require(_amount < WAD); // "LibDssExec/incorrect-ilk-line-precision"
        address _vat = vat();
        (,,, uint256 line_,) = DssVat(_vat).ilks(_ilk);
        setValue(_vat, _ilk, "line", line_ - _amount * RAD);
        if (_global) decreaseGlobalDebtCeiling(_amount);
    }

    /// @dev Set a RWA collateral debt ceiling by specifying its new oracle price.
    /// @param _ilk The ilk to update (ex. bytes32("RWA001-A"))
    /// @param _ceiling The new debt ceiling in natural units (e.g. set 10m as 10_000_000)
    /// @param _price The new oracle price in natural units
    /// @dev note: currently only DAI is supported in RWA vaults.
    /// @dev note: _price should enable DAI to be drawn over the loan period while taking into
    ///                 account the configured ink amount, interest rate and liquidation ratio
    /// @dev note: _price * WAD should be greater than or equal to the current oracle price
    function setRWAIlkDebtCeiling(bytes32 _ilk, uint256 _ceiling, uint256 _price) public {
        require(_price < WAD);
        setIlkDebtCeiling(_ilk, _ceiling);
        RwaOracleLike(getChangelogAddress("MIP21_LIQUIDATION_ORACLE")).bump(_ilk, _price * WAD);
        updateCollateralPrice(_ilk);
    }

    /// @dev Set the parameters for an ilk in the "MCD_IAM_AUTO_LINE" auto-line
    /// @param _ilk The ilk to update (ex. bytes32("ETH-A"))
    /// @param _amount The Maximum value (ex. 100m amount == 100000000)
    /// @param _gap The amount per step (ex. 5m gap == 5000000)
    /// @param _ttl The amount of time (in seconds)
    function setIlkAutoLineParameters(bytes32 _ilk, uint256 _amount, uint256 _gap, uint256 _ttl) public {
        require(_amount < WAD); // "LibDssExec/incorrect-auto-line-amount-precision"
        require(_gap < WAD); // "LibDssExec/incorrect-auto-line-gap-precision"
        IAMLike(autoLine()).setIlk(_ilk, _amount * RAD, _gap * RAD, _ttl);
    }

    /// @dev Set the parameters for an ilk in the "MCD_IAM_AUTO_LINE" auto-line. Keeps the ttl unchanged.
    ///      Requires the auto-line to be already configured for the ilk.
    /// @param _ilk The ilk to update (ex. bytes32("ETH-A"))
    /// @param _amount The Maximum value (ex. 100m amount == 100000000)
    /// @param _gap The amount per step (ex. 5m gap == 5000000)
    function setIlkAutoLineParameters(bytes32 _ilk, uint256 _amount, uint256 _gap) public {
        require(_amount < WAD); // "LibDssExec/incorrect-auto-line-amount-precision"
        require(_gap < WAD); // "LibDssExec/incorrect-auto-line-gap-precision"
        address _autoLine = autoLine();
        (,, uint48 ttl,,) = IAMLike(_autoLine).ilks(_ilk);
        require(ttl != 0); // "LibDssExec/auto-line-not-configured"
        IAMLike(_autoLine).setIlk(_ilk, _amount * RAD, _gap * RAD, uint256(ttl));
    }

    /// @dev Set the debt ceiling for an ilk in the "MCD_IAM_AUTO_LINE" auto-line without updating the time values
    /// @param _ilk The ilk to update (ex. bytes32("ETH-A"))
    /// @param _amount The Maximum value (ex. 100m amount == 100000000)
    function setIlkAutoLineDebtCeiling(bytes32 _ilk, uint256 _amount) public {
        address _autoLine = autoLine();
        (, uint256 gap, uint48 ttl,,) = IAMLike(_autoLine).ilks(_ilk);
        require(gap != 0 && ttl != 0); // "LibDssExec/auto-line-not-configured"
        IAMLike(_autoLine).setIlk(_ilk, _amount * RAD, uint256(gap), uint256(ttl));
    }

    /// @dev Remove an ilk in the "MCD_IAM_AUTO_LINE" auto-line
    /// @param _ilk The ilk to remove (ex. bytes32("ETH-A"))
    function removeIlkFromAutoLine(bytes32 _ilk) public {
        IAMLike(autoLine()).remIlk(_ilk);
    }

    /// @dev Set a collateral minimum vault amount. Amount will be converted to the correct internal precision.
    /// @param _ilk The ilk to update (ex. bytes32("ETH-A"))
    /// @param _amount The amount to set (ex. 10m amount == 10000000)
    function setIlkMinVaultAmount(bytes32 _ilk, uint256 _amount) public {
        require(_amount < WAD); // "LibDssExec/incorrect-ilk-dust-precision"
        (,, uint256 _hole,) = DogLike(dog()).ilks(_ilk);
        require(_amount <= _hole / RAD); // Ensure ilk.hole >= dust
        setValue(vat(), _ilk, "dust", _amount * RAD);
        clip(_ilk).call(abi.encodeWithSignature("upchost()"));
    }

    /// @dev Set a collateral liquidation penalty. Amount will be converted to the correct internal precision.
    /// @dev Equation used for conversion is (1 + pct / 10,000) * WAD
    /// @param _ilk The ilk to update (ex. bytes32("ETH-A"))
    /// @param _pct_bps The pct, in basis points, to set in integer form (x100). (ex. 10.25% = 10.25 * 100 = 1025)
    function setIlkLiquidationPenalty(bytes32 _ilk, uint256 _pct_bps) public {
        require(_pct_bps < BPS_ONE_HUNDRED_PCT); // "LibDssExec/incorrect-ilk-chop-precision"
        setValue(dog(), _ilk, "chop", WAD + wdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
        clip(_ilk).call(abi.encodeWithSignature("upchost()"));
    }

    /// @dev Set max amount for liquidation per vault for collateral. Amount will be converted to the correct internal precision.
    /// @param _ilk The ilk to update (ex. bytes32("ETH-A"))
    /// @param _amount The amount to set (ex. 10m amount == 10000000)
    function setIlkMaxLiquidationAmount(bytes32 _ilk, uint256 _amount) public {
        require(_amount < WAD); // "LibDssExec/incorrect-ilk-hole-precision"
        (,,,, uint256 _dust) = DssVat(vat()).ilks(_ilk);
        require(_amount * RAD >= _dust); // Ensure hole >= ilk.dust
        setValue(dog(), _ilk, "hole", _amount * RAD);
    }

    /// @dev Set a collateral liquidation ratio. Amount will be converted to the correct internal precision.
    /// @dev Equation used for conversion is pct * RAY / 10,000
    /// @param _ilk The ilk to update (ex. bytes32("ETH-A"))
    /// @param _pct_bps The pct, in basis points, to set in integer form (x100). (ex. 150% = 150 * 100 = 15000)
    function setIlkLiquidationRatio(bytes32 _ilk, uint256 _pct_bps) public {
        require(_pct_bps < 10 * BPS_ONE_HUNDRED_PCT); // "LibDssExec/incorrect-ilk-mat-precision" // Fails if pct >= 1000%
        require(_pct_bps >= BPS_ONE_HUNDRED_PCT); // the liquidation ratio has to be bigger or equal to 100%
        setValue(spotter(), _ilk, "mat", rdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
    }

    /// @dev Set an auction starting multiplier. Amount will be converted to the correct internal precision.
    /// @dev Equation used for conversion is pct * RAY / 10,000
    /// @param _ilk The ilk to update (ex. bytes32("ETH-A"))
    /// @param _pct_bps The pct, in basis points, to set in integer form (x100). (ex. 1.3x starting multiplier = 130% = 13000)
    function setStartingPriceMultiplicativeFactor(bytes32 _ilk, uint256 _pct_bps) public {
        require(_pct_bps < 10 * BPS_ONE_HUNDRED_PCT); // "LibDssExec/incorrect-ilk-buf-precision" // Fails if gt 10x
        require(_pct_bps >= BPS_ONE_HUNDRED_PCT); // fail if start price is less than OSM price
        setValue(clip(_ilk), "buf", rdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
    }

    /// @dev Set the amount of time before an auction resets.
    /// @param _ilk The ilk to update (ex. bytes32("ETH-A"))
    /// @param _duration Amount of time before auction resets (in seconds).
    function setAuctionTimeBeforeReset(bytes32 _ilk, uint256 _duration) public {
        setValue(clip(_ilk), "tail", _duration);
    }

    /// @dev Percentage drop permitted before auction reset
    /// @param _ilk The ilk to update (ex. bytes32("ETH-A"))
    /// @param _pct_bps The pct, in basis points, of drop to permit (x100).
    function setAuctionPermittedDrop(bytes32 _ilk, uint256 _pct_bps) public {
        require(_pct_bps < BPS_ONE_HUNDRED_PCT); // "LibDssExec/incorrect-clip-cusp-value"
        setValue(clip(_ilk), "cusp", rdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
    }

    /// @dev Percentage of tab to suck from vow to incentivize keepers. Amount will be converted to the correct internal precision.
    /// @param _ilk The ilk to update (ex. bytes32("ETH-A"))
    /// @param _pct_bps The pct, in basis points, of the tab to suck. (0.01% == 1)
    function setKeeperIncentivePercent(bytes32 _ilk, uint256 _pct_bps) public {
        require(_pct_bps < BPS_ONE_HUNDRED_PCT); // "LibDssExec/incorrect-clip-chip-precision"
        setValue(clip(_ilk), "chip", wdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
    }

    /// @dev Sets the amount for flat rate keeper incentive. Amount will be converted to the correct internal precision.
    /// @param _ilk The ilk to update (ex. bytes32("ETH-A"))
    /// @param _amount The amount to set (ex. 1000 amount == 1000)
    function setKeeperIncentiveFlatRate(bytes32 _ilk, uint256 _amount) public {
        require(_amount < WAD); // "LibDssExec/incorrect-clip-tip-precision"
        require(_amount * RAD <= type(uint192).max); // "LibDssExec/clip-tip-precision-overflow"
        setValue(clip(_ilk), "tip", _amount * RAD);
    }

    /// @dev Sets the circuit breaker price tolerance in the clipper mom.
    ///          This is somewhat counter-intuitive,
    ///           to accept a 25% price drop, use a value of 75%
    /// @param _clip The clipper to set the tolerance for
    /// @param _pct_bps The pct, in basis points, to set in integer form (x100). (ex. 5% = 5 * 100 = 500)
    function setLiquidationBreakerPriceTolerance(address _clip, uint256 _pct_bps) public {
        require(_pct_bps < BPS_ONE_HUNDRED_PCT); // "LibDssExec/incorrect-clippermom-price-tolerance"
        ClipperMomLike(clipperMom()).setPriceTolerance(_clip, rdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
    }

    /// @dev Set the stability fee for a given ilk.
    ///          Many of the settings that change weekly rely on the rate accumulator
    ///          described at https://docs.makerdao.com/smart-contract-modules/rates-module
    ///          To check this yourself, use the following rate calculation (example 8%):
    ///
    ///          $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    ///
    ///          A table of rates can also be found at:
    ///          https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    ///
    /// @param _ilk The ilk to update (ex. bytes32("ETH-A"))
    /// @param _rate The accumulated rate (ex. 4% => 1000000001243680656318820312)
    /// @param _doDrip `true` to accumulate stability fees for the collateral
    function setIlkStabilityFee(bytes32 _ilk, uint256 _rate, bool _doDrip) public {
        require((_rate >= RAY) && (_rate <= RATES_ONE_HUNDRED_PCT)); // "LibDssExec/ilk-stability-fee-out-of-bounds"
        address _jug = jug();
        if (_doDrip) Drippable(_jug).drip(_ilk);

        setValue(_jug, _ilk, "duty", _rate);
    }

    /* ----- Abacus Management ----- */

    /// @dev Set the number of seconds from the start when the auction reaches zero price.
    /// @dev Abacus:LinearDecrease only.
    /// @param _calc The address of the LinearDecrease pricing contract
    /// @param _duration Amount of time for auctions.
    function setLinearDecrease(address _calc, uint256 _duration) public {
        setValue(_calc, "tau", _duration);
    }

    /// @dev Set the number of seconds for each price step.
    /// @dev Abacus:StairstepExponentialDecrease only.
    /// @param _calc The address of the StairstepExponentialDecrease pricing contract
    /// @param _duration Length of time between price drops [seconds]
    /// @param _pct_bps Per-step multiplicative factor in basis points. (ex. 99% == 9900)
    function setStairstepExponentialDecrease(address _calc, uint256 _duration, uint256 _pct_bps) public {
        require(_pct_bps < BPS_ONE_HUNDRED_PCT); // DssExecLib/cut-too-high
        setValue(_calc, "cut", rdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
        setValue(_calc, "step", _duration);
    }

    /// @dev Set the number of seconds for each price step. (99% cut = 1% price drop per step)
    ///           Amounts will be converted to the correct internal precision.
    /// @dev Abacus:ExponentialDecrease only
    /// @param _calc The address of the ExponentialDecrease pricing contract
    /// @param _pct_bps Per-step multiplicative factor in basis points. (ex. 99% == 9900)
    function setExponentialDecrease(address _calc, uint256 _pct_bps) public {
        require(_pct_bps < BPS_ONE_HUNDRED_PCT); // DssExecLib/cut-too-high
        setValue(_calc, "cut", rdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
    }

    /* ----- Oracle Management ----- */

    /// @dev Add OSM address to OSM mom, allowing it to be frozen by governance
    /// @param _osm Oracle Security Module (OSM) core contract address
    /// @param _ilk Collateral type using OSM
    function allowOSMFreeze(address _osm, bytes32 _ilk) public {
        OsmMomLike(osmMom()).setOsm(_ilk, _osm);
    }

    /* ----- Governance Security Module ----- */

    /// @dev Sets the time delay between governance votes and execution in MCD_PAUSE.
    /// @dev Enforces an arbitrary minimum delay of 12 hours.
    /// @param _delay The time delay in seconds.
    function setGSMDelay(uint256 _delay) public {
        require(_delay >= 12 hours); // DssExecLib/delay-too-low
        PauseLike(pause()).setDelay(_delay);
    }

    /* ----- Direct Deposit Module ----- */

    /// @dev Sets the target rate threshold for a direct deposit module (ddm)
    /// @dev Aave: Targets the variable borrow rate
    /// @param _ddm The address of the DDM contract
    /// @param _pct_bps Target rate in basis points. (ex. 4% == 400)
    function setDDMTargetInterestRate(address _ddm, uint256 _pct_bps) public {
        require(_pct_bps < BPS_ONE_HUNDRED_PCT); // DssExecLib/bar-too-high
        setValue(_ddm, "bar", rdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
    }

    /* ----- Collateral Onboarding ----- */

    /// @dev Performs basic collateral setup with core contract integrations and authorizations.
    /// @dev This function handles the fundamental integration of a new collateral type into the core Sky Protocol
    ///      contracts (VAT, DOG, JUG, etc.) without setting risk parameters. Use this when you need basic setup
    ///      without full parameter configuration, or as a building block for more complex onboarding.
    /// @param _ilk      Collateral type key code [Ex. "ETH-A"]
    /// @param _gem      Address of token contract
    /// @param _join     Address of join adapter
    /// @param _clip     Address of liquidation agent
    /// @param _calc     Address of the pricing function
    /// @param _pip      Address of price feed
    function addCollateralBase(bytes32 _ilk, address _gem, address _join, address _clip, address _calc, address _pip)
        public
    {
        // Sanity checks
        address _vat = vat();
        address _dog = dog();
        address _spotter = spotter();
        uint256 _dec = ERC20(_gem).decimals();

        require(JoinLike(_join).vat() == _vat); // "join-vat-not-match"
        require(JoinLike(_join).ilk() == _ilk); // "join-ilk-not-match"
        require(JoinLike(_join).gem() == _gem); // "join-gem-not-match"
        require(JoinLike(_join).dec() == _dec); // "join-dec-not-match"
        require(ClipLike(_clip).vat() == _vat); // "clip-vat-not-match"
        require(ClipLike(_clip).dog() == _dog); // "clip-dog-not-match"
        require(ClipLike(_clip).ilk() == _ilk); // "clip-ilk-not-match"
        require(ClipLike(_clip).spotter() == _spotter); // "clip-ilk-not-match"

        // Set the token PIP in the Spotter
        setContract(spotter(), _ilk, "pip", _pip);

        // Set the ilk Clipper in the Dog
        setContract(_dog, _ilk, "clip", _clip);
        // Set vow in the clip
        setContract(_clip, "vow", vow());
        // Set the pricing function for the Clipper
        setContract(_clip, "calc", _calc);

        // Init ilk in Vat & Jug
        Initializable(_vat).init(_ilk);
        Initializable(jug()).init(_ilk);

        // Allow ilk Join to modify Vat registry
        authorize(_vat, _join);
        // Allow ilk Join to suck dai for keepers
        authorize(_vat, _clip);
        // Allow the ilk Clipper to reduce the Dog hole on deal()
        authorize(_dog, _clip);
        // Allow Dog to kick auctions in ilk Clipper
        authorize(_clip, _dog);
        // Allow End to yank auctions in ilk Clipper
        authorize(_clip, end());
        // Authorize the ESM to execute in the clipper
        authorize(_clip, esm());

        // Add new ilk to the IlkRegistry
        RegistryLike(reg()).add(_join);
    }

    /// @dev Complete collateral onboarding with all necessary configurations and authorizations.
    /// @dev This function performs comprehensive collateral setup including debt ceilings, liquidation parameters,
    ///      stability fees, and oracle configurations. Use this for complete collateral onboarding.
    /// @param co Struct containing all collateral configuration options and parameters
    function addNewCollateral(CollateralOpts memory co) public {
        // Add the collateral to the system.
        addCollateralBase(co.ilk, co.gem, co.join, co.clip, co.calc, co.pip);
        address clipperMom_ = clipperMom();

        if (!co.isLiquidatable) {
            // Disallow Dog to kick auctions in ilk Clipper
            setValue(co.clip, "stopped", 3);
        } else {
            // Grant ClipperMom access to the ilk Clipper
            authorize(co.clip, clipperMom_);
        }

        if (co.isOSM) {
            // If pip == OSM
            if (co.checkWhitelistedOSM) {
                // Check whether the OSM was kissed in the underlying oracle
                require(Kissable(OsmLike(co.pip).src()).bud(co.pip) == 1); // DssExecLib/osm-not-kissed
            }
            // Allow OsmMom to access to the TOKEN OSM
            authorize(co.pip, osmMom());
            // Whitelist Spotter to read the OSM data (only necessary if it is the first time the token is being added to an ilk)
            addToWhitelist(co.pip, spotter());
            // Whitelist Clipper on pip
            addToWhitelist(co.pip, co.clip);
            // Allow the clippermom to access the feed
            addToWhitelist(co.pip, clipperMom_);
            // Whitelist End to read the OSM data (only necessary if it is the first time the token is being added to an ilk)
            addToWhitelist(co.pip, end());
            // Set TOKEN OSM in the OsmMom for new ilk
            allowOSMFreeze(co.pip, co.ilk);
        }

        // Increase the global debt ceiling by the ilk ceiling
        increaseGlobalDebtCeiling(co.ilkDebtCeiling);
        // Set the ilk debt ceiling
        setIlkDebtCeiling(co.ilk, co.ilkDebtCeiling);
        // Set the hole size
        setIlkMaxLiquidationAmount(co.ilk, co.maxLiquidationAmount);
        // Set the ilk dust
        setIlkMinVaultAmount(co.ilk, co.minVaultAmount);
        // Set the ilk liquidation penalty
        setIlkLiquidationPenalty(co.ilk, co.liquidationPenalty);
        // Set the ilk stability fee
        setIlkStabilityFee(co.ilk, co.ilkStabilityFee, true);
        // Set the auction starting price multiplier
        setStartingPriceMultiplicativeFactor(co.ilk, co.startingPriceFactor);
        // Set the amount of time before an auction resets.
        setAuctionTimeBeforeReset(co.ilk, co.auctionDuration);
        // Set the allowed auction drop percentage before reset
        setAuctionPermittedDrop(co.ilk, co.permittedDrop);
        // Set the ilk min collateralization ratio
        setIlkLiquidationRatio(co.ilk, co.liquidationRatio);
        // Set the price tolerance in the liquidation circuit breaker
        setLiquidationBreakerPriceTolerance(co.clip, co.breakerTolerance);
        // Set a flat rate for the keeper reward
        setKeeperIncentiveFlatRate(co.ilk, co.kprFlatReward);
        // Set the percentage of liquidation as keeper award
        setKeeperIncentivePercent(co.ilk, co.kprPctReward);
        // Update ilk spot value in Vat
        updateCollateralPrice(co.ilk);
    }

    /* ----- Payment ----- */

    /// @dev Send a payment in either ERC20 USDS or DAI from the surplus buffer.
    /// @param _join The join adapter to exit the payment from.
    /// @param _target The target address to send the payment to.
    /// @param _amount The amount to send (ex. 10m amount == 10000000)
    function sendPaymentFromSurplusBuffer(address _join, address _target, uint256 _amount) public {
        require(_amount < WAD); // "LibDssExec/incorrect-ilk-line-precision"
        DssVat(vat()).suck(vow(), address(this), _amount * RAD);
        JoinLike(_join).exit(_target, _amount * WAD);
    }

    /* ----- Misc ----- */

    /// @dev Initiate linear interpolation on an administrative value over time.
    /// @param _name The label for this lerp instance
    /// @param _target The target contract
    /// @param _what The target parameter to adjust
    /// @param _startTime The time for this lerp
    /// @param _start The start value for the target parameter
    /// @param _end The end value for the target parameter
    /// @param _duration The duration of the interpolation
    /// @return The address of the created lerp contract
    function linearInterpolation(
        bytes32 _name,
        address _target,
        bytes32 _what,
        uint256 _startTime,
        uint256 _start,
        uint256 _end,
        uint256 _duration
    ) public returns (address) {
        address lerp = LerpFactoryLike(lerpFab()).newLerp(_name, _target, _what, _startTime, _start, _end, _duration);
        Authorizable(_target).rely(lerp);
        LerpLike(lerp).tick();
        return lerp;
    }

    /// @dev Initiate linear interpolation on an administrative value over time.
    /// @param _name The label for this lerp instance
    /// @param _target The target contract
    /// @param _ilk The ilk to target
    /// @param _what The target parameter to adjust
    /// @param _startTime The time for this lerp
    /// @param _start The start value for the target parameter
    /// @param _end The end value for the target parameter
    /// @param _duration The duration of the interpolation
    /// @return The address of the created lerp contract
    function linearInterpolation(
        bytes32 _name,
        address _target,
        bytes32 _ilk,
        bytes32 _what,
        uint256 _startTime,
        uint256 _start,
        uint256 _end,
        uint256 _duration
    ) public returns (address) {
        address lerp = LerpFactoryLike(lerpFab())
            .newIlkLerp(_name, _target, _ilk, _what, _startTime, _start, _end, _duration);
        Authorizable(_target).rely(lerp);
        LerpLike(lerp).tick();
        return lerp;
    }

    /* ----- SubDAO/Star Spells ----- */

    /// @dev Execute a star spell through its star proxy.
    /// @param _starProxy The proxy to execute the spell through.
    /// @param _starSpell The spell to execute.
    /// @return The return data from the spell execution.
    function executeStarSpell(address _starProxy, address _starSpell) public returns (bytes memory) {
        return ProxyLike(_starProxy).exec(_starSpell, abi.encodeWithSignature("execute()"));
    }

    /// @dev Tries to execute a spell through its star proxy.
    ///      Uses low-level call to avoid reverts in case of an error.
    ///      Callers are expected to deal with failed calls.
    /// @param _starProxy The proxy to execute the spell through.
    /// @param _starSpell The spell to execute.
    /// @return ok Whether the spell was executed successfully.
    /// @return data The return data from the spell execution or error message.
    function tryExecuteStarSpell(address _starProxy, address _starSpell) public returns (bool ok, bytes memory data) {
        // Simple low-level call to handle errors without reverting
        (bool success, bytes memory result) =
            _starProxy.call(abi.encodeCall(ProxyLike.exec, (_starSpell, abi.encodeWithSignature("execute()"))));

        return (success, result);
    }
}
