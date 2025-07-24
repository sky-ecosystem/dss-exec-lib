// SPDX-License-Identifier: AGPL-3.0-or-later
//
// MockDssSpellAction.sol -- Mock for testing DssExecLib
//
// Copyright (C) 2020-2025 Dai Foundation
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

import {DssExecLib} from "../DssExecLib.sol";
import {DssAction} from "../DssAction.sol";
import {CollateralOpts} from "../CollateralOpts.sol";

contract MockDssSpellActionNoOfficeHours is DssAction {
    function description() public pure override returns (string memory) {
        return "No Office Hours Action";
    }

    function actions() public pure override {
        require(!officeHours());
    }

    function officeHours() public pure override returns (bool) {
        return false;
    }
}

contract MockDssSpellAction is DssAction {
    function description() external pure override returns (string memory) {
        return "DssTestAction";
    }

    function actions() public override {}

    function canCast_test(uint40 ts, bool officeHours) public pure returns (bool) {
        return DssExecLib.canCast(ts, officeHours);
    }

    function nextCastTime_test(uint40 eta, uint40 ts, bool officeHours) public pure returns (uint256) {
        return DssExecLib.nextCastTime(eta, ts, officeHours);
    }

    function authorize_test(address base, address ward) public {
        DssExecLib.authorize(base, ward);
    }

    function deauthorize_test(address base, address ward) public {
        DssExecLib.deauthorize(base, ward);
    }

    function setAuthority_test(address base, address authority) public {
        DssExecLib.setAuthority(base, authority);
    }

    function delegateVat_test(address usr) public {
        DssExecLib.delegateVat(usr);
    }

    function undelegateVat_test(address usr) public {
        DssExecLib.undelegateVat(usr);
    }

    function accumulateDSR_test() public {
        DssExecLib.accumulateDSR();
    }

    function accumulateSSR_test() public {
        DssExecLib.accumulateSSR();
    }

    function accumulateCollateralStabilityFees_test(bytes32 ilk) public {
        DssExecLib.accumulateCollateralStabilityFees(ilk);
    }

    function setChangelogAddress_test(bytes32 key, address val) public {
        DssExecLib.setChangelogAddress(key, val);
    }

    function removeChangelogAddress_test(bytes32 key) public {
        DssExecLib.removeChangelogAddress(key);
    }

    function setChangelogVersion_test(string memory version) public {
        DssExecLib.setChangelogVersion(version);
    }

    function setChangelogIPFS_test(string memory ipfs) public {
        DssExecLib.setChangelogIPFS(ipfs);
    }

    function setChangelogSHA256_test(string memory SHA256) public {
        DssExecLib.setChangelogSHA256(SHA256);
    }

    function updateCollateralPrice_test(bytes32 ilk) public {
        DssExecLib.updateCollateralPrice(ilk);
    }

    function setContract_test(address base, bytes32 what, address addr) public {
        DssExecLib.setContract(base, what, addr);
    }

    function setContract_test(address base, bytes32 ilk, bytes32 what, address addr) public {
        DssExecLib.setContract(base, ilk, what, addr);
    }

    function setGlobalDebtCeiling_test(uint256 amount) public {
        DssExecLib.setGlobalDebtCeiling(amount);
    }

    function increaseGlobalDebtCeiling_test(uint256 amount) public {
        DssExecLib.increaseGlobalDebtCeiling(amount);
    }

    function decreaseGlobalDebtCeiling_test(uint256 amount) public {
        DssExecLib.decreaseGlobalDebtCeiling(amount);
    }

    function setDSR_test(uint256 rate) public {
        DssExecLib.setDSR(rate, true);
    }

    function setSSR_test(uint256 rate) public {
        DssExecLib.setSSR(rate, true);
    }

    function setSurplusAuctionAmount_test(uint256 amount) public {
        DssExecLib.setSurplusAuctionAmount(amount);
    }

    function setSurplusBuffer_test(uint256 amount) public {
        DssExecLib.setSurplusBuffer(amount);
    }

    function setSurplusAuctionMinPriceThreshold_test(uint256 _pct_bps) public {
        DssExecLib.setSurplusAuctionMinPriceThreshold(_pct_bps);
    }

    function setDebtAuctionDelay_test(uint256 duration) public {
        DssExecLib.setDebtAuctionDelay(duration);
    }

    function setDebtAuctionDebtAmount_test(uint256 amount) public {
        DssExecLib.setDebtAuctionDebtAmount(amount);
    }

    function setDebtAuctionGovAmount_test(uint256 amount) public {
        DssExecLib.setDebtAuctionGovAmount(amount);
    }

    function setMinDebtAuctionBidIncrease_test(uint256 pct_bps) public {
        DssExecLib.setMinDebtAuctionBidIncrease(pct_bps);
    }

    function setDebtAuctionBidDuration_test(uint256 duration) public {
        DssExecLib.setDebtAuctionBidDuration(duration);
    }

    function setDebtAuctionDuration_test(uint256 duration) public {
        DssExecLib.setDebtAuctionDuration(duration);
    }

    function setDebtAuctionMKRIncreaseRate_test(uint256 pct_bps) public {
        DssExecLib.setDebtAuctionMKRIncreaseRate(pct_bps);
    }

    function setMaxTotalDebtLiquidationAmount_test(uint256 amount) public {
        DssExecLib.setMaxTotalDebtLiquidationAmount(amount);
    }

    function setEmergencyShutdownProcessingTime_test(uint256 duration) public {
        DssExecLib.setEmergencyShutdownProcessingTime(duration);
    }

    function setGlobalStabilityFee_test(uint256 rate) public {
        DssExecLib.setGlobalStabilityFee(rate);
    }

    function setParity_test(uint256 value) public {
        DssExecLib.setParity(value);
    }

    function setIlkDebtCeiling_test(bytes32 ilk, uint256 amount) public {
        DssExecLib.setIlkDebtCeiling(ilk, amount);
    }

    function increaseIlkDebtCeiling_test(bytes32 ilk, uint256 amount) public {
        DssExecLib.increaseIlkDebtCeiling(ilk, amount, true);
    }

    function decreaseIlkDebtCeiling_test(bytes32 ilk, uint256 amount) public {
        DssExecLib.decreaseIlkDebtCeiling(ilk, amount, true);
    }

    function setRWAIlkDebtCeiling_test(bytes32 ilk, uint256 ceiling, uint256 price) public {
        DssExecLib.setRWAIlkDebtCeiling(ilk, ceiling, price);
    }

    function setIlkAutoLineParameters_test(bytes32 ilk, uint256 amount, uint256 gap, uint256 ttl) public {
        DssExecLib.setIlkAutoLineParameters(ilk, amount, gap, ttl);
    }

    function setIlkAutoLineParameters_test(bytes32 ilk, uint256 amount, uint256 gap) public {
        DssExecLib.setIlkAutoLineParameters(ilk, amount, gap);
    }

    function setIlkAutoLineDebtCeiling_test(bytes32 ilk, uint256 amount) public {
        DssExecLib.setIlkAutoLineDebtCeiling(ilk, amount);
    }

    function removeIlkFromAutoLine_test(bytes32 ilk) public {
        DssExecLib.removeIlkFromAutoLine(ilk);
    }

    function setIlkMinVaultAmount_test(bytes32 ilk, uint256 amount) public {
        DssExecLib.setIlkMinVaultAmount(ilk, amount);
    }

    function setIlkLiquidationPenalty_test(bytes32 ilk, uint256 pct_bps) public {
        DssExecLib.setIlkLiquidationPenalty(ilk, pct_bps);
    }

    function setStartingPriceMultiplicativeFactor_test(bytes32 ilk, uint256 pct_bps) public {
        DssExecLib.setStartingPriceMultiplicativeFactor(ilk, pct_bps); // clip.buf
    }

    function setAuctionTimeBeforeReset_test(bytes32 ilk, uint256 duration) public {
        DssExecLib.setAuctionTimeBeforeReset(ilk, duration);
    }

    function setAuctionPermittedDrop_test(bytes32 ilk, uint256 pct_bps) public {
        DssExecLib.setAuctionPermittedDrop(ilk, pct_bps);
    }

    function setIlkMaxLiquidationAmount_test(bytes32 ilk, uint256 amount) public {
        DssExecLib.setIlkMaxLiquidationAmount(ilk, amount);
    }

    function setIlkLiquidationRatio_test(bytes32 ilk, uint256 pct_bps) public {
        DssExecLib.setIlkLiquidationRatio(ilk, pct_bps);
    }

    function setKeeperIncentivePercent_test(bytes32 ilk, uint256 pct_bps) public {
        DssExecLib.setKeeperIncentivePercent(ilk, pct_bps);
    }

    function setKeeperIncentiveFlatRate_test(bytes32 ilk, uint256 amount) public {
        DssExecLib.setKeeperIncentiveFlatRate(ilk, amount);
    }

    function setLiquidationBreakerPriceTolerance_test(address clip, uint256 pct_bps) public {
        DssExecLib.setLiquidationBreakerPriceTolerance(clip, pct_bps);
    }

    function setIlkStabilityFee_test(bytes32 ilk, uint256 rate) public {
        DssExecLib.setIlkStabilityFee(ilk, rate, true);
    }

    function setLinearDecrease_test(address calc, uint256 duration) public {
        DssExecLib.setLinearDecrease(calc, duration);
    }

    function setStairstepExponentialDecrease_test(address calc, uint256 duration, uint256 pct_bps) public {
        DssExecLib.setStairstepExponentialDecrease(calc, duration, pct_bps);
    }

    function setExponentialDecrease_test(address calc, uint256 pct_bps) public {
        DssExecLib.setExponentialDecrease(calc, pct_bps);
    }

    function addToWhitelist_test(address osm, address reader) public {
        DssExecLib.addToWhitelist(osm, reader);
    }

    function removeFromWhitelist_test(address osm, address reader) public {
        DssExecLib.removeFromWhitelist(osm, reader);
    }

    function allowOSMFreeze_test(address osm, bytes32 ilk) public {
        DssExecLib.allowOSMFreeze(osm, ilk);
    }

    function setGSMDelay_test(uint256 _delay) public {
        DssExecLib.setGSMDelay(_delay);
    }

    function setDDMTargetInterestRate_test(address ddm, uint256 pct_bps) public {
        DssExecLib.setDDMTargetInterestRate(ddm, pct_bps);
    }

    function addCollateralBase_test(bytes32 ilk, address gem, address join, address clip, address calc, address pip)
        public
    {
        DssExecLib.addCollateralBase(ilk, gem, join, clip, calc, pip);
    }

    function addNewCollateral_test(CollateralOpts memory co) public {
        DssExecLib.addNewCollateral(co);
    }

    function sendPaymentFromSurplusBuffer_test(address join, address target, uint256 amount) public {
        DssExecLib.sendPaymentFromSurplusBuffer(join, target, amount);
    }

    function linearInterpolation_test(
        bytes32 _name,
        address _target,
        bytes32 _what,
        uint256 _startTime,
        uint256 _start,
        uint256 _end,
        uint256 _duration
    ) public returns (address) {
        return DssExecLib.linearInterpolation(_name, _target, _what, _startTime, _start, _end, _duration);
    }

    function linearInterpolation_test(
        bytes32 _name,
        address _target,
        bytes32 _ilk,
        bytes32 _what,
        uint256 _startTime,
        uint256 _start,
        uint256 _end,
        uint256 _duration
    ) public returns (address) {
        return DssExecLib.linearInterpolation(_name, _target, _ilk, _what, _startTime, _start, _end, _duration);
    }

    function executeStarSpell_test(address starProxy, address starSpell) public returns (bytes memory) {
        return DssExecLib.executeStarSpell(starProxy, starSpell);
    }

    function tryExecuteStarSpell_test(address starProxy, address starSpell) public returns (bool, bytes memory) {
        return DssExecLib.tryExecuteStarSpell(starProxy, starSpell);
    }
}
