// SPDX-License-Identifier: AGPL-3.0-or-later
//
// DssAction.sol -- DSS Executive Spell Action Tests
//
// Copyright (C) 2020-2022 Dai Foundation
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
import "dss-interfaces/Interfaces.sol";

import {CollateralOpts} from "./CollateralOpts.sol";
import {MockDssSpellAction, MockDssSpellActionNoOfficeHours} from "./mocks/MockDssSpellAction.sol";
import {MockToken} from "./mocks/MockToken.sol";
import {MockValue} from "./mocks/MockValue.sol";
import {MockOracle} from "./mocks/MockOracle.sol";
import {MockOsm} from "./mocks/MockOsm.sol";
import {MockStarProxy} from "./mocks/MockStarProxy.sol";
import {MockStarSpell} from "./mocks/MockStarSpell.sol";

interface ChainlogLike is ChainlogAbstract {
    function sha256sum() external view returns (string calldata);
}

interface PipLike {
    function peek() external returns (bytes32, bool);
    function read() external returns (bytes32);
}

interface KissLike {
    function kiss(address) external;
}

interface ClipFabLike {
    function newClip(address owner, address vat, address spotter, address dog, bytes32 ilk)
        external
        returns (address clip);
}

interface GemJoinFabLike {
    function newAuthGemJoin(address owner, bytes32 ilk, address gem) external returns (address join);
    function newGemJoin(address owner, bytes32 ilk, address gem) external returns (address join);
}

interface CalcFabLike {
    function newExponentialDecrease(address owner) external returns (address calc);
    function newLinearDecrease(address owner) external returns (address calc);
    function newStairstepExponentialDecrease(address owner) external returns (address calc);
}

interface RwaLiquidationOracleLike {
    function ilks(bytes32) external view returns (string calldata, address, uint48, uint48);
    function rely(address) external;
    function init(bytes32, uint256, string calldata, uint48) external;
}

interface RwaTokenFactoryLike {
    function createRwaToken(string calldata, string calldata, address) external returns (address token);
}

interface Univ2OracleFactoryLike {
    function build(address, address, bytes32, address, address) external returns (address oracle);
}

interface DDMLike {
    function bar() external view returns (uint256);
    function rely(address) external;
}

interface FlapUniV2Like {
    function want() external view returns (uint256);
}

interface UsdsJoinLike is DaiJoinAbstract {
    function usds() external view returns (address);
}

interface UsdsLike {
    function balanceOf(address) external view returns (uint256);
}

interface SUsdsLike {
    function chi() external view returns (uint192);
    function drip() external returns (uint256 nChi);
    function ssr() external view returns (uint256);
}

interface ProxyLike {
    function exec(address, bytes calldata) external returns (bytes memory);
}

contract DssActionTest is Test {
    using stdStorage for StdStorage;

    ChainlogLike LOG = ChainlogLike(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    DSPauseAbstract pause;
    VatAbstract vat;
    EndAbstract end;
    VowAbstract vow;
    PotAbstract pot;
    SUsdsLike susds;
    JugAbstract jug;
    DogAbstract dog;
    DaiAbstract daiToken;
    DaiJoinAbstract daiJoin;
    UsdsLike usdsToken;
    UsdsJoinLike usdsJoin;
    SpotAbstract spot;
    FlapUniV2Like flap;
    FlopAbstract flop;
    DSTokenAbstract gov;
    DSTokenAbstract mkr;
    IlkRegistryAbstract reg;
    OsmMomAbstract osmMom;
    ClipperMomAbstract clipperMom;
    DssAutoLineAbstract autoLine;
    LerpFactoryAbstract lerpFab;
    RwaLiquidationOracleLike rwaOracle;

    MedianAbstract oracle;

    MockDssSpellAction action;

    struct Ilk {
        DSValueAbstract pip;
        OsmAbstract osm;
        DSTokenAbstract gem;
        GemJoinAbstract join;
        ClipAbstract clip;
    }

    mapping(bytes32 => Ilk) ilks;

    uint256 public constant THOUSAND = 10 ** 3;
    uint256 public constant MILLION = 10 ** 6;
    uint256 public constant WAD = 10 ** 18;
    uint256 public constant RAY = 10 ** 27;
    uint256 public constant RAD = 10 ** 45;

    uint256 START_TIME;
    string constant doc = "QmcniBv7UQ4gGPQQW2BwbD4ZZHzN3o3tPuNLZCbBchd1zh";

    address constant UNIV2ORACLE_FAB = 0xc968B955BCA6c2a3c828d699cCaCbFDC02402D89;

    function setUp() public {
        vm.createSelectFork("mainnet");

        START_TIME = block.timestamp;

        pause = DSPauseAbstract(LOG.getAddress("MCD_PAUSE"));
        vat = VatAbstract(LOG.getAddress("MCD_VAT"));
        end = EndAbstract(LOG.getAddress("MCD_END"));
        vow = VowAbstract(LOG.getAddress("MCD_VOW"));
        pot = PotAbstract(LOG.getAddress("MCD_POT"));
        susds = SUsdsLike(LOG.getAddress("SUSDS"));
        jug = JugAbstract(LOG.getAddress("MCD_JUG"));
        dog = DogAbstract(LOG.getAddress("MCD_DOG"));
        daiToken = DaiAbstract(LOG.getAddress("MCD_DAI"));
        daiJoin = DaiJoinAbstract(LOG.getAddress("MCD_JOIN_DAI"));
        usdsJoin = UsdsJoinLike(LOG.getAddress("USDS_JOIN"));
        usdsToken = UsdsLike(LOG.getAddress("USDS"));
        spot = SpotAbstract(LOG.getAddress("MCD_SPOT"));
        flap = FlapUniV2Like(LOG.getAddress("MCD_FLAP"));
        flop = FlopAbstract(LOG.getAddress("MCD_FLOP"));
        gov = DSTokenAbstract(LOG.getAddress("MCD_GOV"));
        mkr = DSTokenAbstract(LOG.getAddress("MKR"));
        reg = IlkRegistryAbstract(LOG.getAddress("ILK_REGISTRY"));
        osmMom = OsmMomAbstract(LOG.getAddress("OSM_MOM"));
        clipperMom = ClipperMomAbstract(LOG.getAddress("CLIPPER_MOM"));
        autoLine = DssAutoLineAbstract(LOG.getAddress("MCD_IAM_AUTO_LINE"));
        lerpFab = LerpFactoryAbstract(LOG.getAddress("LERP_FAB"));
        rwaOracle = RwaLiquidationOracleLike(LOG.getAddress("MIP21_LIQUIDATION_ORACLE"));
        oracle = MedianAbstract(address(new MockOracle()));

        vm.label(address(pause), "PAUSE");
        vm.label(address(vat), "VAT");
        vm.label(address(end), "END");
        vm.label(address(vow), "VOW");
        vm.label(address(pot), "POT");
        vm.label(address(susds), "SUSDS");
        vm.label(address(jug), "JUG");
        vm.label(address(dog), "DOG");
        vm.label(address(daiToken), "DAI");
        vm.label(address(usdsToken), "USDS");
        vm.label(address(daiJoin), "DAI_JOIN");
        vm.label(address(usdsJoin), "USDS_JOIN");
        vm.label(address(spot), "SPOT");
        vm.label(address(flap), "FLAP");
        vm.label(address(flop), "FLOP");
        vm.label(address(gov), "GOV");
        vm.label(address(mkr), "MKR");
        vm.label(address(reg), "REG");
        vm.label(address(osmMom), "OSM_MOM");
        vm.label(address(clipperMom), "CLIPPER_MOM");
        vm.label(address(autoLine), "AUTO_LINE");
        vm.label(address(lerpFab), "LERP_FAB");
        vm.label(address(rwaOracle), "RWA_LIQUITATION_ORACLE");

        vm.warp(START_TIME);

        action = new MockDssSpellAction();

        giveAuth(address(vat), address(this));
        giveAuth(address(vat), address(action));
        giveAuth(address(spot), address(this));
        giveAuth(address(spot), address(action));
        giveAuth(address(susds), address(action));
        giveAuth(address(dog), address(this));
        giveAuth(address(dog), address(action));
        giveAuth(address(vow), address(action));
        giveAuth(address(end), address(action));
        giveAuth(address(pot), address(action));
        giveAuth(address(jug), address(this));
        giveAuth(address(jug), address(action));
        giveAuth(address(flap), address(action));
        giveAuth(address(flop), address(action));
        giveAuth(address(daiJoin), address(action));
        giveAuth(address(LOG), address(action));
        giveAuth(address(reg), address(this));
        giveAuth(address(reg), address(action));
        giveAuth(address(autoLine), address(action));
        giveAuth(address(lerpFab), address(action));
        giveAuth(address(rwaOracle), address(this));
        giveAuth(address(rwaOracle), address(action));
        oracle.rely(address(action));

        initCollateral("gold", address(action));
        initRwaCollateral({
            ilk: "6s",
            line: 20_000_000 * RAD,
            tau: 365 days,
            duty: 1000000000937303470807876289, // 3% APY
            mat: 105 * RAY / 100
        });

        vm.store(address(clipperMom), 0, bytes32(uint256(uint160(address(action)))));
        vm.store(address(osmMom), 0, bytes32(uint256(uint160(address(action)))));
    }

    function ray(uint256 wad) internal pure returns (uint256) {
        return wad * 10 ** 9;
    }

    function rad(uint256 wad) internal pure returns (uint256) {
        return wad * RAY;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y / RAY;
    }

    function rpow(uint256 x, uint256 n, uint256 b) internal pure returns (uint256 z) {
        assembly {
            switch n
            case 0 { z := b }
            default {
                switch x
                case 0 { z := 0 }
                default {
                    switch mod(n, 2)
                    case 0 { z := b }
                    default { z := x }
                    let half := div(b, 2) // for rounding.
                    for { n := div(n, 2) } n { n := div(n, 2) } {
                        let xx := mul(x, x)
                        if shr(128, x) { revert(0, 0) }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) { revert(0, 0) }
                        x := div(xxRound, b)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0, 0) }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) { revert(0, 0) }
                            z := div(zxRound, b)
                        }
                    }
                }
            }
        }
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function giveAuth(address _base, address target) internal {
        WardsAbstract base = WardsAbstract(_base);

        // Edge case - ward is already set
        if (base.wards(target) == 1) return;

        for (int256 i = 0; i < 100; i++) {
            // Scan the storage for the ward storage slot
            bytes32 prevValue = vm.load(address(base), keccak256(abi.encode(target, uint256(i))));
            vm.store(address(base), keccak256(abi.encode(target, uint256(i))), bytes32(uint256(1)));
            if (base.wards(target) == 1) {
                // Found it
                return;
            } else {
                // Keep going after restoring the original value
                vm.store(address(base), keccak256(abi.encode(target, uint256(i))), prevValue);
            }
        }

        // We have failed if we reach here
        assertTrue(false);
    }

    function initCollateral(bytes32 name, address _action) internal returns (Ilk memory) {
        DSTokenAbstract gem = DSTokenAbstract(address(new MockToken("")));
        gem.mint(address(this), 20 ether);

        DSValueAbstract pip = DSValueAbstract(address(new MockValue()));
        spot.file(name, "pip", address(pip));
        spot.file(name, "mat", ray(2 ether));
        // initial collateral price of 6
        pip.poke(bytes32(6 * WAD));
        spot.poke(name);

        OsmAbstract osm = OsmAbstract(address(new MockOsm(address(pip))));
        osm.rely(address(clipperMom));

        vat.init(name);
        GemJoinAbstract join =
            GemJoinAbstract(GemJoinFabLike(LOG.getAddress("JOIN_FAB")).newGemJoin(address(this), name, address(gem)));

        vat.file(name, "line", rad(1000 ether));

        gem.approve(address(join), type(uint256).max);

        vat.rely(address(join));

        ClipAbstract clip = ClipAbstract(
            ClipFabLike(LOG.getAddress("CLIP_FAB"))
                .newClip(address(this), address(vat), address(spot), address(dog), name)
        );
        vat.hope(address(clip));
        clip.rely(address(end));
        clip.rely(address(dog));
        dog.rely(address(clip));
        dog.file(name, "clip", address(clip));
        dog.file(name, "chop", 1 ether);
        dog.file("Hole", rad((10 ether) * MILLION));

        reg.add(address(join));

        clip.rely(_action);
        join.rely(_action);
        osm.rely(_action);

        ilks[name].pip = pip;
        ilks[name].osm = osm;
        ilks[name].gem = gem;
        ilks[name].join = join;
        ilks[name].clip = clip;

        return ilks[name];
    }

    function initRwaCollateral(bytes32 ilk, uint256 line, uint48 tau, uint256 duty, uint256 mat) internal {
        uint256 val = rmul(rmul(line / RAY, mat), rpow(duty, 2 * 365 days, RAY));
        rwaOracle.init(ilk, val, doc, tau);
        (, address pip,,) = rwaOracle.ilks(ilk);
        spot.file(ilk, "pip", pip);
        vat.init(ilk);
        jug.init(ilk);
        string memory name = string(abi.encodePacked(ilk));
        DSTokenAbstract token = DSTokenAbstract(
            RwaTokenFactoryLike(LOG.getAddress("RWA_TOKEN_FAB")).createRwaToken(name, name, address(this))
        );
        AuthGemJoinAbstract join = AuthGemJoinAbstract(
            GemJoinFabLike(LOG.getAddress("JOIN_FAB")).newAuthGemJoin(address(this), ilk, address(token))
        );
        vat.rely(address(join));
        vat.rely(address(rwaOracle));
        vat.file(ilk, "line", line);
        vat.file("Line", vat.Line() + line);
        jug.file(ilk, "duty", duty);
        spot.file(ilk, "mat", mat);
        spot.poke(ilk);
    }

    // /******************************/
    // /*** OfficeHours Management ***/
    // /******************************/

    function test_canCast() public view {
        assertTrue(action.canCast_test(1616169600, true)); // Friday   2021/03/19, 4:00:00 PM GMT

        assertTrue(action.canCast_test(1616169600, false)); // Friday   2021/03/19, 4:00:00 PM GMT
        assertTrue(action.canCast_test(1616256000, false)); // Saturday 2021/03/20, 4:00:00 PM GMT

        assertTrue(!action.canCast_test(1616256000, true)); // Saturday 2021/03/20, 4:00:00 PM GMT
    }

    function test_nextCastTime() public view {
        assertEq(action.nextCastTime_test(1616169600, 1616169600, true), 1616169600);
        assertEq(action.nextCastTime_test(1616169600, 1616169600, false), 1616169600);

        assertEq(action.nextCastTime_test(1616256000, 1616256000, true), 1616421600);
        assertEq(action.nextCastTime_test(1616256000, 1616256000, false), 1616256000);
    }

    function test_nextCastTimeEtaZeroReverts() public {
        vm.expectRevert();
        action.nextCastTime_test(0, 1616256000, false);
    }

    function test_nextCastTimeTsZeroReverts() public {
        vm.expectRevert();
        action.nextCastTime_test(1616256000, 0, false);
    }

    // /**********************/
    // /*** Authorizations ***/
    // /**********************/

    function test_authorize() public {
        assertEq(vat.wards(address(1)), 0);
        action.authorize_test(address(vat), address(1));
        assertEq(vat.wards(address(1)), 1);
    }

    function test_deauthorize() public {
        assertEq(vat.wards(address(1)), 0);
        action.authorize_test(address(vat), address(1));
        assertEq(vat.wards(address(1)), 1);

        action.deauthorize_test(address(vat), address(1));
        assertEq(vat.wards(address(1)), 0);
    }

    function test_setAuthority() public {
        assertEq(clipperMom.authority(), address(LOG.getAddress("MCD_ADM")));
        action.setAuthority_test(address(clipperMom), address(1));
        assertEq(clipperMom.authority(), address(1));
    }

    function test_delegateVat() public {
        assertEq(vat.can(address(action), address(1)), 0);
        action.delegateVat_test(address(1));
        assertEq(vat.can(address(action), address(1)), 1);
    }

    function test_undelegateVat() public {
        assertEq(vat.can(address(action), address(1)), 0);
        action.delegateVat_test(address(1));
        assertEq(vat.can(address(action), address(1)), 1);

        action.undelegateVat_test(address(1));
        assertEq(vat.can(address(action), address(1)), 0);
    }

    function test_setAddress() public {
        bytes32 ilk = "silver";
        action.setChangelogAddress_test(ilk, address(this));
        assertEq(LOG.getAddress(ilk), address(this));
    }

    function test_removeAddress() public {
        bytes32 ilk = "silver";
        // First add an address to the changelog
        action.setChangelogAddress_test(ilk, address(this));
        assertEq(LOG.getAddress(ilk), address(this));

        // Then remove it
        action.removeChangelogAddress_test(ilk);

        // Verify it was removed by checking that it reverts when trying to get the address
        vm.expectRevert();
        LOG.getAddress(ilk);
    }

    function test_setVersion() public {
        string memory version = "9001.0.0";
        action.setChangelogVersion_test(version);
        assertEq(LOG.version(), version);
    }

    function test_setIPFS() public {
        string memory ipfs = "QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW";
        action.setChangelogIPFS_test(ipfs);
        assertEq(LOG.ipfs(), ipfs);
    }

    function test_setSHA256() public {
        string memory SHA256 = "e42dc9d043a57705f3f097099e6b2de4230bca9a020c797508da079f9079e35b";
        action.setChangelogSHA256_test(SHA256);
        assertEq(LOG.sha256sum(), SHA256);
    }

    function test_accumulateDSR() public {
        uint256 beforeChi = pot.chi();
        action.setDSR_test(1000000001243680656318820312); // 4%
        assertEq(pot.dsr(), 1000000001243680656318820312);
        vm.warp(START_TIME + 1 days);
        action.accumulateDSR_test();
        uint256 afterChi = pot.chi();

        assertGt(afterChi, beforeChi);
    }

    function test_accumulateSSR() public {
        uint256 beforeChi = susds.chi();
        action.setSSR_test(1000000001243680656318820312); // 4%
        assertEq(susds.ssr(), 1000000001243680656318820312);
        vm.warp(START_TIME + 1 days);
        action.accumulateSSR_test();
        uint256 afterChi = susds.chi();

        assertGt(afterChi, beforeChi);
    }

    function test_accumulateCollateralStabilityFees() public {
        jug.init("gold");
        (, uint256 beforeRate,,,) = vat.ilks("gold");
        action.setIlkStabilityFee_test("gold", 1000000001243680656318820312); // 4%
        (uint256 duty,) = jug.ilks("gold");
        assertEq(duty, 1000000001243680656318820312);
        vm.warp(START_TIME + 1 days);
        action.accumulateCollateralStabilityFees_test("gold");
        (, uint256 afterRate,,,) = vat.ilks("gold");

        assertGt(afterRate, beforeRate);
    }

    function test_updateCollateralPrice() public {
        uint256 _spot;

        (,, _spot,,) = vat.ilks("gold");
        assertEq(_spot, ray(3 ether));
        ilks["gold"].pip.poke(bytes32(10 * WAD));

        action.updateCollateralPrice_test("gold");

        (,, _spot,,) = vat.ilks("gold");
        assertEq(_spot, ray(5 ether)); // $5 at 200%
    }

    function test_setContract() public {
        action.setContract_test(address(jug), "vow", address(1));
        assertEq(jug.vow(), address(1));
    }

    function test_setGlobalDebtCeiling() public {
        action.setGlobalDebtCeiling_test(100 * MILLION); // 100,000,000 Dai
        assertEq(vat.Line(), 100 * MILLION * RAD); // Fixes precision
    }

    function test_increaseGlobalDebtCeiling() public {
        action.setGlobalDebtCeiling_test(100 * MILLION); // setup

        action.increaseGlobalDebtCeiling_test(100 * MILLION); // 100,000,000 Dai
        assertEq(vat.Line(), 200 * MILLION * RAD); // Fixes precision
    }

    function test_decreaseGlobalDebtCeiling() public {
        action.setGlobalDebtCeiling_test(300 * MILLION); // setup

        action.decreaseGlobalDebtCeiling_test(100 * MILLION); // 100,000,000 Dai
        assertEq(vat.Line(), 200 * MILLION * RAD); // Fixes precision
    }

    function test_decreaseGlobalDebtCeilingReverts() public {
        action.setGlobalDebtCeiling_test(100 * MILLION); // setup

        vm.expectRevert();
        action.decreaseGlobalDebtCeiling_test(101 * MILLION); // fail
    }

    function test_setDSR() public {
        uint256 rate = 1000000001243680656318820312;
        action.setDSR_test(rate);
        assertEq(pot.dsr(), rate);
    }

    function test_setSurplusAuctionAmount() public {
        action.setSurplusAuctionAmount_test(100 * THOUSAND);
        assertEq(vow.bump(), 100 * THOUSAND * RAD);
    }

    function test_setSurplusBuffer() public {
        action.setSurplusBuffer_test(1 * MILLION);
        assertEq(vow.hump(), 1 * MILLION * RAD);
    }

    function test_setSurplusAuctionMinPriceThreshold() public {
        action.setSurplusAuctionMinPriceThreshold_test(75_00);
        assertEq(flap.want(), 75 * WAD / 100);
    }

    function test_setDebtAuctionDelay() public {
        action.setDebtAuctionDelay_test(12 hours);
        assertEq(vow.wait(), 12 hours);
    }

    function test_setDebtAuctionDebtAmount() public {
        action.setDebtAuctionDebtAmount_test(100 * THOUSAND);
        assertEq(vow.sump(), 100 * THOUSAND * RAD);
    }

    function test_setDebtAuctionGovAmount() public {
        action.setDebtAuctionGovAmount_test(100);
        assertEq(vow.dump(), 100 * WAD);
    }

    function test_setMinDebtAuctionBidIncrease() public {
        action.setMinDebtAuctionBidIncrease_test(525); // 5.25%
        assertEq(flop.beg(), 1 ether + 5.25 ether / 100); // (1 + pct) * WAD
    }

    function test_setMinDebtAuctionBidIncreaseTooHighReverts() public {
        vm.expectRevert();
        action.setMinDebtAuctionBidIncrease_test(10000); // Fail on 100%
    }

    function test_setDebtAuctionBidDuration() public {
        action.setDebtAuctionBidDuration_test(12 hours);
        assertEq(uint256(flop.ttl()), 12 hours);
    }

    function test_setDebtAuctionBidDurationMaxReverts() public {
        vm.expectRevert();
        action.setDebtAuctionBidDuration_test(type(uint48).max); // Fail on max
    }

    function test_setDebtAuctionDuration() public {
        action.setDebtAuctionDuration_test(12 hours);
        assertEq(uint256(flop.tau()), 12 hours);
    }

    function test_setDebtAuctionDurationMaxReverts() public {
        vm.expectRevert();
        action.setDebtAuctionDuration_test(type(uint48).max); // Fail on max
    }

    function test_setDebtAuctionMKRIncreaseRate() public {
        action.setDebtAuctionMKRIncreaseRate_test(525);
        assertEq(flop.pad(), 105.25 ether / 100); // WAD pct
    }

    function test_setDebtAuctionMKRIncreaseRateTooHighReverts() public {
        vm.expectRevert();
        action.setDebtAuctionMKRIncreaseRate_test(10000); // Fail on 100%
    }

    function test_setMaxTotalDebtLiquidationAmount() public {
        action.setMaxTotalDebtLiquidationAmount_test(50 * MILLION);
        assertEq(dog.Hole(), 50 * MILLION * RAD); // WAD pct
    }

    function test_setEmergencyShutdownProcessingTime() public {
        action.setEmergencyShutdownProcessingTime_test(12 hours);
        assertEq(end.wait(), 12 hours);
    }

    function test_setGlobalStabilityFee() public {
        uint256 rate = 1000000001243680656318820312;
        action.setGlobalStabilityFee_test(rate);
        assertEq(jug.base(), rate);
    }

    function test_setParity() public {
        action.setParity_test(1005); // $1.005
        assertEq(spot.par(), ray(1.005 ether));
    }

    function test_setIlkDebtCeiling() public {
        action.setIlkDebtCeiling_test("gold", 100 * MILLION);
        (,,, uint256 line,) = vat.ilks("gold");
        assertEq(line, 100 * MILLION * RAD);
    }

    function test_increaseIlkDebtCeiling() public {
        action.setGlobalDebtCeiling_test(100 * MILLION);
        action.setIlkDebtCeiling_test("gold", 100 * MILLION); // Setup

        action.increaseIlkDebtCeiling_test("gold", 100 * MILLION);
        (,,, uint256 line,) = vat.ilks("gold");
        assertEq(line, 200 * MILLION * RAD);
        assertEq(vat.Line(), 200 * MILLION * RAD); // also increased
    }

    function test_decreaseIlkDebtCeiling() public {
        action.setGlobalDebtCeiling_test(300 * MILLION);
        action.setIlkDebtCeiling_test("gold", 300 * MILLION); // Setup

        action.decreaseIlkDebtCeiling_test("gold", 100 * MILLION);
        (,,, uint256 line,) = vat.ilks("gold");
        assertEq(line, 200 * MILLION * RAD);
        assertEq(vat.Line(), 200 * MILLION * RAD); // also decreased
    }

    function test_decreaseIlkDebtCeilingReverts() public {
        action.setIlkDebtCeiling_test("gold", 100 * MILLION); // Setup

        vm.expectRevert();
        action.decreaseIlkDebtCeiling_test("gold", 101 * MILLION); // Fail
    }

    function test_setRWAIlkDebtCeiling() public {
        (, address pip,,) = rwaOracle.ilks("6s");
        uint256 price = uint256(PipLike(pip).read());
        assertApproxEqAbs(price, 22_278_900 * WAD, WAD); // 20MM * 1.03^2 * 1.05
        action.setRWAIlkDebtCeiling_test("6s", 50 * MILLION, 55 * MILLION); // Increase
        (,,, uint256 line,) = vat.ilks("6s");
        assertEq(line, 50 * MILLION * RAD);
        price = uint256(PipLike(pip).read());
        assertEq(price, 55 * MILLION * WAD);
        action.setRWAIlkDebtCeiling_test("6s", 40 * MILLION, 55 * MILLION); // Decrease
        (,,, line,) = vat.ilks("6s");
        assertEq(line, 40 * MILLION * RAD);
        price = uint256(PipLike(pip).read());
        assertEq(price, 55 * MILLION * WAD);
    }

    function test_setRWAIlkDebtCeilingReverts() public {
        vm.expectRevert();
        action.setRWAIlkDebtCeiling_test("6s", 50 * MILLION, 20 * MILLION); // Fail
    }

    function test_setIlkAutoLineParameters() public {
        action.setIlkAutoLineParameters_test("gold", 150 * MILLION, 5 * MILLION, 10000); // Setup

        (,,, uint256 line,) = vat.ilks("gold");
        assertEq(line, 1000 * RAD); // does not change line

        autoLine.exec("gold");
        (,,, line,) = vat.ilks("gold");
        assertEq(line, 5 * MILLION * RAD); // Change to match the gap
    }

    function test_setIlkAutoLineParametersKeepTtl() public {
        // First set up with initial values including ttl
        action.setIlkAutoLineParameters_test("gold", 150 * MILLION, 5 * MILLION, 10000);

        // Get the initial ttl value
        (,, uint48 initialTtl,,) = autoLine.ilks("gold");
        assertEq(uint256(initialTtl), 10000);

        // Now use the overloaded function that should keep the ttl unchanged
        action.setIlkAutoLineParameters_test("gold", 200 * MILLION, 10 * MILLION);

        // Verify line and gap were updated but ttl remains the same
        (uint256 line, uint256 gap, uint48 ttl,,) = autoLine.ilks("gold");
        assertEq(line, 200 * MILLION * RAD);
        assertEq(gap, 10 * MILLION * RAD);
        assertEq(uint256(ttl), initialTtl); // ttl should remain unchanged
    }

    function test_RevertSetIlkAutoLineParametersKeepTtl_WhenNotConfigured() public {
        vm.expectRevert();
        action.setIlkAutoLineParameters_test("gold", 200 * MILLION, 10 * MILLION);
    }

    function test_setIlkAutoLineDebtCeiling() public {
        action.setIlkAutoLineParameters_test("gold", 1, 5 * MILLION, 10000); // gap and ttl must be configured already
        action.setIlkAutoLineDebtCeiling_test("gold", 150 * MILLION); // Setup

        (,,, uint256 line,) = vat.ilks("gold");
        assertEq(line, 1000 * RAD); // does not change line

        autoLine.exec("gold");
        (,,, line,) = vat.ilks("gold");
        assertEq(line, 5 * MILLION * RAD); // Change to match the gap
    }

    function test_setRemoveIlkFromAutoLine() public {
        action.setIlkAutoLineParameters_test("gold", 100 * MILLION, 5 * MILLION, 10000); // gap and ttl must be configured already
        action.removeIlkFromAutoLine_test("gold");

        assertEq(autoLine.exec("gold"), 1000 * RAD);
    }

    function test_setIlkMinVaultAmountLt() public {
        action.setIlkMaxLiquidationAmount_test("gold", 100);
        action.setIlkMinVaultAmount_test("gold", 1);
        (,,,, uint256 dust) = vat.ilks("gold");
        assertEq(dust, 1 * RAD);
    }

    function test_setIlkMinVaultAmountEq() public {
        action.setIlkMaxLiquidationAmount_test("gold", 100);
        action.setIlkMinVaultAmount_test("gold", 100);
        (,,,, uint256 dust) = vat.ilks("gold");
        assertEq(dust, 100 * RAD);

        action.setIlkMinVaultAmount_test("gold", 0);
        action.setIlkMaxLiquidationAmount_test("gold", 0);
        (,,,, dust) = vat.ilks("gold");
        assertEq(dust, 0);
    }

    function test_setIlkMinVaultAmountGtReverts() public {
        action.setIlkMaxLiquidationAmount_test("gold", 100);
        vm.expectRevert();
        action.setIlkMinVaultAmount_test("gold", 101); // Fail here
    }

    function test_setIlkLiquidationPenalty() public {
        action.setIlkLiquidationPenalty_test("gold", 1325); // 13.25%
        (, uint256 chop,,) = dog.ilks("gold");
        assertEq(chop, 113.25 ether / 100); // WAD pct 113.25%
    }

    function test_setIlkMaxLiquidationAmount() public {
        action.setIlkMaxLiquidationAmount_test("gold", 50 * THOUSAND);
        (,, uint256 hole,) = dog.ilks("gold");
        assertEq(hole, 50 * THOUSAND * RAD);
    }

    function test_setIlkMaxLiquidationAmountLtReverts() public {
        action.setIlkMaxLiquidationAmount_test("gold", 100);
        action.setIlkMinVaultAmount_test("gold", 100);
        vm.expectRevert();
        action.setIlkMaxLiquidationAmount_test("gold", 99);
    }

    function test_setIlkLiquidationRatio() public {
        action.setIlkLiquidationRatio_test("gold", 15000); // 150% in bp
        (, uint256 mat) = spot.ilks("gold");
        assertEq(mat, ray(150 ether / 100)); // RAY pct
    }

    function test_setStartingPriceMultiplicativeFactor() public {
        action.setStartingPriceMultiplicativeFactor_test("gold", 15000); // 150%
        assertEq(ilks["gold"].clip.buf(), 150 * RAY / 100); // RAY pct
    }

    function test_setAuctionTimeBeforeReset() public {
        action.setAuctionTimeBeforeReset_test("gold", 12 hours);
        assertEq(ilks["gold"].clip.tail(), 12 hours);
    }

    function test_setAuctionPermittedDrop() public {
        action.setAuctionPermittedDrop_test("gold", 8000);
        assertEq(ilks["gold"].clip.cusp(), 80 * RAY / 100);
    }

    function test_setKeeperIncentivePercent() public {
        action.setKeeperIncentivePercent_test("gold", 10); // 0.1 %
        assertEq(ilks["gold"].clip.chip(), 10 * WAD / 10000);
    }

    function test_setKeeperIncentiveFlatRate() public {
        action.setKeeperIncentiveFlatRate_test("gold", 1000); // 1000 Dai
        assertEq(ilks["gold"].clip.tip(), 1000 * RAD);
    }

    function test_setLiquidationBreakerPriceTolerance() public {
        action.setLiquidationBreakerPriceTolerance_test(address(ilks["gold"].clip), 6000);
        assertEq(clipperMom.tolerance(address(ilks["gold"].clip)), 600000000000000000000000000);
    }

    function test_setIlkStabilityFee() public {
        vm.warp(START_TIME + 1 days);
        action.setIlkStabilityFee_test("gold", 1000000001243680656318820312);
        (uint256 duty, uint256 rho) = jug.ilks("gold");
        assertEq(duty, 1000000001243680656318820312);
        assertEq(rho, START_TIME + 1 days);
    }

    function test_setLinearDecrease() public {
        LinearDecreaseAbstract calc =
            LinearDecreaseAbstract(CalcFabLike(LOG.getAddress("CALC_FAB")).newLinearDecrease(address(this)));
        calc.rely(address(action));
        action.setLinearDecrease_test(address(calc), 14 hours);
        assertEq(calc.tau(), 14 hours);
    }

    function test_setStairstepExponentialDecrease() public {
        StairstepExponentialDecreaseAbstract calc = StairstepExponentialDecreaseAbstract(
            CalcFabLike(LOG.getAddress("CALC_FAB")).newStairstepExponentialDecrease(address(this))
        );
        calc.rely(address(action));
        action.setStairstepExponentialDecrease_test(address(calc), 90, 9999); // 90 seconds per step, 99.99% multiplicative
        assertEq(calc.step(), 90);
        assertEq(calc.cut(), 999900000000000000000000000);
    }

    function test_setExponentialDecrease() public {
        ExponentialDecreaseAbstract calc =
            ExponentialDecreaseAbstract(CalcFabLike(LOG.getAddress("CALC_FAB")).newExponentialDecrease(address(this)));
        calc.rely(address(action));
        action.setExponentialDecrease_test(address(calc), 9999); // 99.99% multiplicative
        assertEq(calc.cut(), 999900000000000000000000000);
    }

    function test_addReaderToOSMWhitelist() public {
        OsmAbstract osm = ilks["gold"].osm;
        address reader = address(1);

        assertEq(osm.bud(address(1)), 0);
        action.addToWhitelist_test(address(osm), reader);
        assertEq(osm.bud(address(1)), 1);
    }

    function test_removeReaderFromOSMWhitelist() public {
        OsmAbstract osm = ilks["gold"].osm;
        address reader = address(1);

        assertEq(osm.bud(address(1)), 0);
        action.addToWhitelist_test(address(osm), reader);
        assertEq(osm.bud(address(1)), 1);
        action.removeFromWhitelist_test(address(osm), reader);
        assertEq(osm.bud(address(1)), 0);
    }

    function test_allowOSMFreeze() public {
        OsmAbstract osm = ilks["gold"].osm;
        action.allowOSMFreeze_test(address(osm), "gold");
        assertEq(osmMom.osms("gold"), address(osm));
    }

    function test_setGSMDelay() public {
        // Because of the `wait` modifier in MCD_PAUSE, the call needs to be made from MCD_PAUSE_PROXY.
        // It's not possible to do that using `prank`/`startPrank`. See:
        // https://github.com/foundry-rs/foundry/issues/4266
        // For that reason, we need overwrite the `owner` in MCD_PAUSE_PROXY, so we can call `exec` from there.
        ProxyLike pauseProxy = ProxyLike(LOG.getAddress("MCD_PAUSE_PROXY"));
        stdstore.target(address(pauseProxy)).sig("owner()").checked_write(address(this));

        // Sets an initial value
        pauseProxy.exec(address(action), abi.encodeCall(action.setGSMDelay_test, 12 hours));

        // Checks if the new value is being properly set.
        pauseProxy.exec(address(action), abi.encodeCall(action.setGSMDelay_test, 16 hours));
        assertEq(pause.delay(), 16 hours);

        // Reverts if the value is lower than 12 hours
        vm.expectRevert();
        pauseProxy.exec(address(action), abi.encodeCall(action.setGSMDelay_test, 8 hours));
    }

    function test_setDDMTargetInterestRate() public {
        DDMLike ddm = DDMLike(LOG.getAddress("DIRECT_AAVEV2_DAI_PLAN"));
        giveAuth(address(ddm), address(action));

        action.setDDMTargetInterestRate_test(address(ddm), 500); // set to 5%
        assertEq(ddm.bar(), 5 * RAY / 100);

        action.setDDMTargetInterestRate_test(address(ddm), 0); // set to 0%
        assertEq(ddm.bar(), 0);

        action.setDDMTargetInterestRate_test(address(ddm), 1000); // set to 10%
        assertEq(ddm.bar(), 10 * RAY / 100);
    }

    function test_collateralOnboardingBase() public {
        string memory silk = "silver";
        bytes32 ilk = stringToBytes32(silk);

        DSTokenAbstract token = DSTokenAbstract(address(new MockToken(silk)));
        GemJoinAbstract tokenJoin =
            GemJoinAbstract(GemJoinFabLike(LOG.getAddress("JOIN_FAB")).newGemJoin(address(this), ilk, address(token)));
        ClipAbstract tokenClip = ClipAbstract(
            ClipFabLike(LOG.getAddress("CLIP_FAB"))
                .newClip(address(this), address(vat), address(spot), address(dog), ilk)
        );
        LinearDecreaseAbstract tokenCalc =
            LinearDecreaseAbstract(CalcFabLike(LOG.getAddress("CALC_FAB")).newLinearDecrease(address(this)));
        tokenCalc.file("tau", 1);
        address tokenPip = address(DSValueAbstract(address(new MockValue())));

        tokenPip = address(new MockOsm(address(tokenPip)));
        OsmAbstract(tokenPip).rely(address(action));
        tokenClip.rely(address(action));
        tokenJoin.rely(address(action));
        tokenClip.deny(address(this));
        tokenJoin.deny(address(this));

        action.addCollateralBase_test(
            ilk, address(token), address(tokenJoin), address(tokenClip), address(tokenCalc), tokenPip
        );

        assertEq(vat.wards(address(tokenJoin)), 1);
        assertEq(dog.wards(address(tokenClip)), 1);

        assertEq(tokenClip.wards(address(end)), 1);

        (,, uint256 _class, uint256 _dec, address _gem, address _pip, address _join, address _xlip) = reg.info(ilk);

        assertEq(_class, 1);
        assertEq(_dec, 18);
        assertEq(_gem, address(token));
        assertEq(_pip, address(tokenPip));
        assertEq(_join, address(tokenJoin));
        assertEq(_xlip, address(tokenClip));
        assertEq(address(tokenClip.calc()), address(tokenCalc));
    }

    function _checkCollateralOnboarding(bool liquidatable, bool isOsm, bool oracleSrc) internal {
        string memory silk = "silver";
        bytes32 ilk = stringToBytes32(silk);

        address token = address(new MockToken(silk));
        GemJoinAbstract tokenJoin =
            GemJoinAbstract(GemJoinFabLike(LOG.getAddress("JOIN_FAB")).newGemJoin(address(this), ilk, address(token)));
        ClipAbstract tokenClip = ClipAbstract(
            ClipFabLike(LOG.getAddress("CLIP_FAB"))
                .newClip(address(this), address(vat), address(spot), address(dog), ilk)
        );
        LinearDecreaseAbstract tokenCalc =
            LinearDecreaseAbstract(CalcFabLike(LOG.getAddress("CALC_FAB")).newLinearDecrease(address(this)));
        tokenCalc.file("tau", 1);
        address _pip = address(DSValueAbstract(address(new MockValue())));

        address tokenPip;
        if (isOsm) {
            tokenPip = oracleSrc ? address(new MockOsm(address(oracle))) : address(new MockOsm(address(_pip)));
            if (oracleSrc) KissLike(address(oracle)).kiss(address(tokenPip));
            OsmAbstract(tokenPip).rely(address(action));
        } else {
            tokenPip = _pip;
        }

        tokenClip.rely(address(action));
        tokenJoin.rely(address(action));
        tokenClip.deny(address(this));
        tokenJoin.deny(address(this));

        {
            uint256 globalLine = vat.Line();

            action.addNewCollateral_test(
                CollateralOpts({
                    ilk: ilk,
                    gem: token,
                    join: address(tokenJoin),
                    clip: address(tokenClip),
                    calc: address(tokenCalc),
                    pip: tokenPip,
                    isLiquidatable: liquidatable,
                    isOSM: isOsm,
                    checkWhitelistedOSM: oracleSrc,
                    ilkDebtCeiling: 100 * MILLION,
                    minVaultAmount: 100,
                    maxLiquidationAmount: 50 * THOUSAND,
                    liquidationPenalty: 1300,
                    ilkStabilityFee: 1000000001243680656318820312,
                    startingPriceFactor: 13000,
                    breakerTolerance: 6000,
                    auctionDuration: 6 hours,
                    permittedDrop: 4000,
                    liquidationRatio: 15000,
                    kprFlatReward: 100,
                    kprPctReward: 10
                })
            );

            assertEq(vat.Line(), globalLine + 100 * MILLION * RAD);
        }

        {
            assertEq(vat.wards(address(tokenJoin)), 1);
            assertEq(dog.wards(address(tokenClip)), 1);

            assertEq(tokenClip.wards(address(end)), 1);
            assertEq(tokenClip.wards(address(dog)), 1); // Use "stopped" instead of ward to disable.

            if (liquidatable) {
                assertEq(tokenClip.stopped(), 0);
                assertEq(tokenClip.wards(address(clipperMom)), 1);
            } else {
                assertEq(tokenClip.stopped(), 3);
                assertEq(tokenClip.wards(address(clipperMom)), 0);
            }
        }

        if (isOsm) {
            assertEq(OsmAbstract(tokenPip).wards(address(osmMom)), 1);
            assertEq(OsmAbstract(tokenPip).bud(address(spot)), 1);
            assertEq(OsmAbstract(tokenPip).bud(address(tokenClip)), 1);
            assertEq(OsmAbstract(tokenPip).bud(address(clipperMom)), 1);
            assertEq(OsmAbstract(tokenPip).bud(address(end)), 1);

            assertEq(osmMom.osms(ilk), tokenPip);
        }

        {
            (,,, uint256 line, uint256 dust) = vat.ilks(ilk);
            (, uint256 chop, uint256 hole, uint256 dirt) = dog.ilks(ilk);
            assertEq(line, 100 * MILLION * RAD);
            assertEq(dust, 100 * RAD);
            assertEq(hole, 50 * THOUSAND * RAD);
            assertEq(dirt, 0);
            assertEq(chop, 113 ether / 100); // WAD pct 113%

            (uint256 duty, uint256 rho) = jug.ilks(ilk);
            assertEq(duty, 1000000001243680656318820312);
            assertEq(rho, START_TIME);
        }

        {
            assertEq(tokenClip.buf(), 130 * RAY / 100);
            assertEq(tokenClip.tail(), 6 hours);
            assertEq(tokenClip.cusp(), 40 * RAY / 100);

            assertEq(clipperMom.tolerance(address(tokenClip)), 6000 * RAY / 10000);

            assertEq(uint256(tokenClip.tip()), 100 * RAD);
            assertEq(uint256(tokenClip.chip()), 10 * WAD / 10000);

            (, uint256 mat) = spot.ilks(ilk);
            assertEq(mat, ray(150 ether / 100)); // RAY pct

            bytes32[] memory ilkList = reg.list();
            assertEq(ilkList[ilkList.length - 1], ilk);
        }
    }

    function test_addNewCollateralCase1() public {
        _checkCollateralOnboarding(true, true, true); // Liquidations: ON,  PIP == OSM, osmSrc == oracle
    }

    function test_addNewCollateralCase2() public {
        _checkCollateralOnboarding(true, true, false); // Liquidations: ON,  PIP == OSM, osmSrc != oracle
    }

    function test_addNewCollateralCase3() public {
        _checkCollateralOnboarding(true, false, false); // Liquidations: ON,  PIP != OSM, osmSrc != oracle
    }

    function test_addNewCollateralCase4() public {
        _checkCollateralOnboarding(false, true, true); // Liquidations: OFF, PIP == OSM, osmSrc == oracle
    }

    function test_addNewCollateralCase5() public {
        _checkCollateralOnboarding(false, true, false); // Liquidations: OFF, PIP == OSM, osmSrc != oracle
    }

    function test_addNewCollateralCase6() public {
        _checkCollateralOnboarding(false, false, false); // Liquidations: OFF, PIP != OSM, osmSrc != oracle
    }

    function test_officeHoursCanOverrideInAction() public {
        MockDssSpellActionNoOfficeHours actionNoOfficeHours = new MockDssSpellActionNoOfficeHours();
        actionNoOfficeHours.execute();
        assertTrue(!actionNoOfficeHours.officeHours());
    }

    function test_sendPaymentFromSurplusBuffer_DAI() public {
        address target = address(this);

        action.delegateVat_test(address(daiJoin));

        assertEq(vat.dai(target), 0);
        assertEq(vat.sin(target), 0);
        assertEq(daiToken.balanceOf(target), 0);
        uint256 vowDaiPrev = vat.dai(address(vow));
        uint256 vowSinPrev = vat.sin(address(vow));
        action.sendPaymentFromSurplusBuffer_test(address(daiJoin), target, 100);
        assertEq(vat.dai(target), 0);
        assertEq(vat.sin(target), 0);
        assertEq(daiToken.balanceOf(target), 100 * WAD);
        assertEq(vat.dai(address(vow)), vowDaiPrev);
        assertEq(vat.sin(address(vow)), vowSinPrev + 100 * RAD);
    }

    function test_sendPaymentFromSurplusBuffer_USDS() public {
        address target = address(this);

        action.delegateVat_test(address(usdsJoin));

        assertEq(vat.dai(target), 0);
        assertEq(vat.sin(target), 0);
        assertEq(usdsToken.balanceOf(target), 0);
        uint256 vowDaiPrev = vat.dai(address(vow));
        uint256 vowSinPrev = vat.sin(address(vow));
        action.sendPaymentFromSurplusBuffer_test(address(usdsJoin), target, 100);
        assertEq(vat.dai(target), 0);
        assertEq(vat.sin(target), 0);
        assertEq(usdsToken.balanceOf(target), 100 * WAD);
        assertEq(vat.dai(address(vow)), vowDaiPrev);
        assertEq(vat.sin(address(vow)), vowSinPrev + 100 * RAD);
    }

    function test_lerpLine() public {
        LerpAbstract lerp = LerpAbstract(
            action.linearInterpolation_test(
                "myLerp001", address(vat), "Line", block.timestamp, rad(2400 ether), rad(0 ether), 1 days
            )
        );
        assertEq(lerp.what(), "Line");
        assertEq(lerp.start(), rad(2400 ether));
        assertEq(lerp.end(), rad(0 ether));
        assertEq(lerp.duration(), 1 days);
        assertTrue(!lerp.done());
        assertEq(lerp.startTime(), block.timestamp);
        assertEq(vat.Line(), rad(2400 ether));
        vm.warp(block.timestamp + 1 hours);
        assertEq(vat.Line(), rad(2400 ether));
        lerp.tick();
        assertEq(vat.Line(), rad(2300 ether + 1600)); // Small amount at the end is rounding errors
        vm.warp(block.timestamp + 1 hours);
        lerp.tick();
        assertEq(vat.Line(), rad(2200 ether + 800));
        vm.warp(block.timestamp + 6 hours);
        lerp.tick();
        assertEq(vat.Line(), rad(1600 ether + 800));
        vm.warp(block.timestamp + 1 days);
        assertEq(vat.Line(), rad(1600 ether + 800));
        lerp.tick();
        assertEq(vat.Line(), rad(0 ether));
        assertTrue(lerp.done());
        assertEq(vat.wards(address(lerp)), 0);
    }

    function test_lerpIlkLine() public {
        bytes32 ilk = "gold";
        LerpAbstract lerp = LerpAbstract(
            action.linearInterpolation_test(
                "myLerp001", address(vat), ilk, "line", block.timestamp, rad(2400 ether), rad(0 ether), 1 days
            )
        );
        lerp.tick();
        assertEq(lerp.what(), "line");
        assertEq(lerp.start(), rad(2400 ether));
        assertEq(lerp.end(), rad(0 ether));
        assertEq(lerp.duration(), 1 days);
        assertTrue(!lerp.done());
        (,,, uint256 line,) = vat.ilks(ilk);
        assertEq(lerp.startTime(), block.timestamp);
        assertEq(line, rad(2400 ether));
        vm.warp(block.timestamp + 1 hours);
        (,,, line,) = vat.ilks(ilk);
        assertEq(line, rad(2400 ether));
        lerp.tick();
        (,,, line,) = vat.ilks(ilk);
        assertEq(line, rad(2300 ether + 1600)); // Small amount at the end is rounding errors
        vm.warp(block.timestamp + 1 hours);
        lerp.tick();
        (,,, line,) = vat.ilks(ilk);
        assertEq(line, rad(2200 ether + 800));
        vm.warp(block.timestamp + 6 hours);
        lerp.tick();
        (,,, line,) = vat.ilks(ilk);
        assertEq(line, rad(1600 ether + 800));
        vm.warp(block.timestamp + 1 days);
        (,,, line,) = vat.ilks(ilk);
        assertEq(line, rad(1600 ether + 800));
        lerp.tick();
        (,,, line,) = vat.ilks(ilk);
        assertEq(line, rad(0 ether));
        assertTrue(lerp.done());
        assertEq(vat.wards(address(lerp)), 0);
    }

    function test_executeStarSpell_success() public {
        // Setup mock contracts
        MockStarProxy proxy = new MockStarProxy();
        MockStarSpell spell = new MockStarSpell();

        // Execute the spell through the proxy
        action.executeStarSpell_test(address(proxy), address(spell));

        // Verify the spell was executed successfully
        assertTrue(proxy.executed(), "Spell should have been executed");

        // Verify the proxy recorded the correct target and data
        assertEq(proxy.lastTarget(), address(spell), "Proxy should have recorded the correct target");
        assertEq(
            proxy.lastData(),
            abi.encodeWithSignature("execute()"),
            "Proxy should have recorded the correct function signature"
        );
    }

    function test_executeStarSpell_failure() public {
        // Setup mock contracts
        MockStarProxy proxy = new MockStarProxy();
        MockStarSpell spell = new MockStarSpell();

        // Configure the spell to fail
        proxy.setShouldFail(true);

        // This should revert
        vm.expectRevert("MockStarProxy/delegatecall-error");
        action.executeStarSpell_test(address(proxy), address(spell));
    }

    function test_tryExecuteStarSpell_success() public {
        // Setup mock contracts
        MockStarProxy proxy = new MockStarProxy();
        MockStarSpell spell = new MockStarSpell();

        // Try to execute the spell through the proxy
        (bool success,) = action.tryExecuteStarSpell_test(address(proxy), address(spell));

        // Verify the execution was successful
        assertTrue(success, "tryExecuteStarSpell should return success=true for successful execution");

        // Verify the spell was executed
        assertTrue(proxy.executed(), "Spell should have been executed");
    }

    function test_tryExecuteStarSpell_failure() public {
        // Setup mock contracts
        MockStarProxy proxy = new MockStarProxy();
        MockStarSpell spell = new MockStarSpell();

        // Configure the spell to fail
        proxy.setShouldFail(true);

        // Try to execute the spell through the proxy
        (bool success,) = action.tryExecuteStarSpell_test(address(proxy), address(spell));

        // Verify the execution failed but the call itself didn't revert
        assertFalse(success, "tryExecuteStarSpell should return success=false for failed execution");

        // Verify the spell was not executed
        assertFalse(proxy.executed(), "Spell should not have been executed when configured to fail");
    }
}
