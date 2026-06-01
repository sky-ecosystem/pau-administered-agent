// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.34;

import { Test } from "../../lib/forge-std/src/Test.sol";

import { EnumerableSet } from "../../lib/openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { IAdministeredAgent } from "../../src/interfaces/IAdministeredAgent.sol";

import { AdministeredAgent } from "../../src/AdministeredAgent.sol";

contract AdministeredActorHarness is AdministeredAgent {

    using EnumerableSet for EnumerableSet.AddressSet;

    constructor(address admin_) AdministeredAgent(admin_) {}

    function __addAdmin(address account) external {
        _addAdmin(account);
    }

    function __removeAdmin(address account) external {
        _admins.remove(account);
    }

    function __addActor(address account) external {
        _actors.add(account);
    }

    function __removeActor(address account) external {
        _actors.remove(account);
    }

    function __addGrantor(address account) external {
        _grantors.add(account);
    }

    function __removeGrantor(address account) external {
        _grantors.remove(account);
    }

    function __addRevoker(address account) external {
        _revokers.add(account);
    }

    function __removeRevoker(address account) external {
        _revokers.remove(account);
    }

    function __getAdmin(uint256 index) external view returns (address) {
        return _admins.at(index);
    }

    function __getActor(uint256 index) external view returns (address) {
        return _actors.at(index);
    }

    function __getGrantor(uint256 index) external view returns (address) {
        return _grantors.at(index);
    }

    function __getRevoker(uint256 index) external view returns (address) {
        return _revokers.at(index);
    }

    function __isAdmin(address account) external view returns (bool) {
        return _admins.contains(account);
    }

    function __isActor(address account) external view returns (bool) {
        return _actors.contains(account);
    }

    function __isGrantor(address account) external view returns (bool) {
        return _grantors.contains(account);
    }

    function __isRevoker(address account) external view returns (bool) {
        return _revokers.contains(account);
    }

}

contract AdministeredActor_UnitTests is Test {

    address internal actor        = makeAddr("actor");
    address internal admin        = makeAddr("admin");
    address internal deployer     = makeAddr("deployer");
    address internal grantor      = makeAddr("grantor");
    address internal otherAdmin   = makeAddr("otherAdmin");
    address internal revoker      = makeAddr("revoker");
    address internal unauthorized = makeAddr("unauthorized");

    AdministeredActorHarness internal administeredActor;

    function setUp() external {
        vm.prank(deployer);
        administeredActor = new AdministeredActorHarness(admin);
    }

    /**********************************************************************************************/
    /*** Constructor Tests                                                                      ***/
    /**********************************************************************************************/

    function test_constructor_zeroAccount() external {
        vm.expectRevert(IAdministeredAgent.ZeroAccount.selector);
        new AdministeredAgent(address(0));
    }

    function test_constructor() external {
        vm.expectEmit();
        emit IAdministeredAgent.AdminAdded(admin, deployer);

        vm.prank(deployer);
        AdministeredActorHarness administeredActor_ = new AdministeredActorHarness(admin);

        assertEq(administeredActor_.adminCount(),     1);
        assertEq(administeredActor_.__isAdmin(admin), true);
        assertEq(administeredActor_.__getAdmin(0),    admin);
    }

    /**********************************************************************************************/
    /*** addAdmin Tests                                                                         ***/
    /**********************************************************************************************/

    function test_addAdmin_notAdmin() external {
        vm.expectRevert(IAdministeredAgent.NotAdmin.selector);

        vm.prank(unauthorized);
        administeredActor.addAdmin(otherAdmin);
    }

    function test_addAdmin_zeroAccount() external {
        vm.expectRevert(IAdministeredAgent.ZeroAccount.selector);

        vm.prank(admin);
        administeredActor.addAdmin(address(0));
    }

    function test_addAdmin_accountAlreadyAdmin() external {
        vm.expectRevert(IAdministeredAgent.AccountAlreadyAdmin.selector);

        vm.prank(admin);
        administeredActor.addAdmin(admin);
    }

    function test_addAdmin() external {
        assertEq(administeredActor.adminCount(),          1);
        assertEq(administeredActor.__isAdmin(otherAdmin), false);

        vm.expectEmit(address(administeredActor));
        emit IAdministeredAgent.AdminAdded(otherAdmin, admin);

        vm.prank(admin);
        administeredActor.addAdmin(otherAdmin);

        assertEq(administeredActor.adminCount(),          2);
        assertEq(administeredActor.__isAdmin(otherAdmin), true);
    }

    /**********************************************************************************************/
    /*** removeAdmin Tests                                                                      ***/
    /**********************************************************************************************/

    function test_removeAdmin_notAdmin() external {
        vm.expectRevert(IAdministeredAgent.NotAdmin.selector);

        vm.prank(unauthorized);
        administeredActor.removeAdmin(admin);
    }

    function test_removeAdmin_accountNotAdmin() external {
        vm.expectRevert(IAdministeredAgent.AccountNotAdmin.selector);

        vm.prank(admin);
        administeredActor.removeAdmin(unauthorized);
    }

    function test_removeAdmin_noAdminsRemaining() external {
        vm.expectRevert(IAdministeredAgent.NoAdminsRemaining.selector);

        vm.prank(admin);
        administeredActor.removeAdmin(admin);
    }

    function test_removeAdmin() external {
        administeredActor.__addAdmin(otherAdmin);

        assertEq(administeredActor.adminCount(),          2);
        assertEq(administeredActor.__isAdmin(otherAdmin), true);

        vm.expectEmit(address(administeredActor));
        emit IAdministeredAgent.AdminRemoved(otherAdmin, admin);

        vm.prank(admin);
        administeredActor.removeAdmin(otherAdmin);

        assertEq(administeredActor.adminCount(),          1);
        assertEq(administeredActor.__isAdmin(otherAdmin), false);
    }

    /**********************************************************************************************/
    /*** addGrantor Tests                                                                       ***/
    /**********************************************************************************************/

    function test_addGrantor_notAdmin() external {
        vm.expectRevert(IAdministeredAgent.NotAdmin.selector);

        vm.prank(unauthorized);
        administeredActor.addGrantor(grantor);
    }

    function test_addGrantor_zeroAccount() external {
        vm.expectRevert(IAdministeredAgent.ZeroAccount.selector);

        vm.prank(admin);
        administeredActor.addGrantor(address(0));
    }

    function test_addGrantor_accountAlreadyGrantor() external {
        administeredActor.__addGrantor(grantor);

        vm.expectRevert(IAdministeredAgent.AccountAlreadyGrantor.selector);

        vm.prank(admin);
        administeredActor.addGrantor(grantor);
    }

    function test_addGrantor() external {
        assertEq(administeredActor.grantorCount(),       0);
        assertEq(administeredActor.__isGrantor(grantor), false);

        vm.expectEmit(address(administeredActor));
        emit IAdministeredAgent.GrantorAdded(grantor, admin);

        vm.prank(admin);
        administeredActor.addGrantor(grantor);

        assertEq(administeredActor.grantorCount(),       1);
        assertEq(administeredActor.__isGrantor(grantor), true);
    }

    /**********************************************************************************************/
    /*** removeGrantor Tests                                                                    ***/
    /**********************************************************************************************/

    function test_removeGrantor_notAdmin() external {
        vm.expectRevert(IAdministeredAgent.NotAdmin.selector);

        vm.prank(unauthorized);
        administeredActor.removeGrantor(grantor);
    }

    function test_removeGrantor_accountNotGrantor() external {
        vm.expectRevert(IAdministeredAgent.AccountNotGrantor.selector);

        vm.prank(admin);
        administeredActor.removeGrantor(grantor);
    }

    function test_removeGrantor() external {
        administeredActor.__addGrantor(grantor);

        assertEq(administeredActor.grantorCount(),       1);
        assertEq(administeredActor.__isGrantor(grantor), true);

        vm.expectEmit(address(administeredActor));
        emit IAdministeredAgent.GrantorRemoved(grantor, admin);

        vm.prank(admin);
        administeredActor.removeGrantor(grantor);

        assertEq(administeredActor.grantorCount(),       0);
        assertEq(administeredActor.__isGrantor(grantor), false);
    }

    /**********************************************************************************************/
    /*** addRevoker Tests                                                                       ***/
    /**********************************************************************************************/

    function test_addRevoker_notAdmin() external {
        vm.expectRevert(IAdministeredAgent.NotAdmin.selector);

        vm.prank(unauthorized);
        administeredActor.addRevoker(revoker);
    }

    function test_addRevoker_zeroAccount() external {
        vm.expectRevert(IAdministeredAgent.ZeroAccount.selector);

        vm.prank(admin);
        administeredActor.addRevoker(address(0));
    }

    function test_addRevoker_accountAlreadyRevoker() external {
        administeredActor.__addRevoker(revoker);

        vm.expectRevert(IAdministeredAgent.AccountAlreadyRevoker.selector);

        vm.prank(admin);
        administeredActor.addRevoker(revoker);
    }

    function test_addRevoker() external {
        assertEq(administeredActor.revokerCount(),       0);
        assertEq(administeredActor.__isRevoker(revoker), false);

        vm.expectEmit(address(administeredActor));
        emit IAdministeredAgent.RevokerAdded(revoker, admin);

        vm.prank(admin);
        administeredActor.addRevoker(revoker);

        assertEq(administeredActor.revokerCount(),       1);
        assertEq(administeredActor.__isRevoker(revoker), true);
    }

    /**********************************************************************************************/
    /*** removeRevoker Tests                                                                    ***/
    /**********************************************************************************************/

    function test_removeRevoker_notAdmin() external {
        vm.expectRevert(IAdministeredAgent.NotAdmin.selector);

        vm.prank(unauthorized);
        administeredActor.removeRevoker(revoker);
    }

    function test_removeRevoker_accountNotRevoker() external {
        vm.expectRevert(IAdministeredAgent.AccountNotRevoker.selector);

        vm.prank(admin);
        administeredActor.removeRevoker(revoker);
    }

    function test_removeRevoker() external {
        administeredActor.__addRevoker(revoker);

        assertEq(administeredActor.revokerCount(),       1);
        assertEq(administeredActor.__isRevoker(revoker), true);

        vm.expectEmit(address(administeredActor));
        emit IAdministeredAgent.RevokerRemoved(revoker, admin);

        vm.prank(admin);
        administeredActor.removeRevoker(revoker);

        assertEq(administeredActor.revokerCount(),       0);
        assertEq(administeredActor.__isRevoker(revoker), false);
    }

    /**********************************************************************************************/
    /*** addActor Tests                                                                         ***/
    /**********************************************************************************************/

    function test_addActor_notGrantor() external {
        vm.expectRevert(IAdministeredAgent.NotGrantor.selector);

        vm.prank(unauthorized);
        administeredActor.addActor(actor);
    }

    function test_addActor_zeroAccount() external {
        vm.expectRevert(IAdministeredAgent.ZeroAccount.selector);

        vm.prank(admin);
        administeredActor.addActor(address(0));
    }

    function test_addActor_accountAlreadyActor() external {
        administeredActor.__addActor(actor);

        vm.expectRevert(IAdministeredAgent.AccountAlreadyActor.selector);

        vm.prank(admin);
        administeredActor.addActor(actor);
    }

    function test_addActor_asAdmin() external {
        assertEq(administeredActor.actorCount(),     0);
        assertEq(administeredActor.__isActor(actor), false);

        vm.expectEmit(address(administeredActor));
        emit IAdministeredAgent.ActorAdded(actor, admin);

        vm.prank(admin);
        administeredActor.addActor(actor);

        assertEq(administeredActor.actorCount(),     1);
        assertEq(administeredActor.__isActor(actor), true);
    }

    function test_addActor_asGrantor() external {
        administeredActor.__addGrantor(grantor);

        assertEq(administeredActor.actorCount(),     0);
        assertEq(administeredActor.__isActor(actor), false);

        vm.expectEmit(address(administeredActor));
        emit IAdministeredAgent.ActorAdded(actor, grantor);

        vm.prank(grantor);
        administeredActor.addActor(actor);

        assertEq(administeredActor.actorCount(),     1);
        assertEq(administeredActor.__isActor(actor), true);
    }

    /**********************************************************************************************/
    /*** removeActor Tests                                                                      ***/
    /**********************************************************************************************/

    function test_removeActor_notRevoker() external {
        vm.expectRevert(IAdministeredAgent.NotRevoker.selector);

        vm.prank(unauthorized);
        administeredActor.removeActor(actor);
    }

    function test_removeActor_accountNotActor() external {
        vm.expectRevert(IAdministeredAgent.AccountNotActor.selector);

        vm.prank(admin);
        administeredActor.removeActor(actor);
    }

    function test_removeActor_asAdmin() external {
        administeredActor.__addActor(actor);

        assertEq(administeredActor.actorCount(),     1);
        assertEq(administeredActor.__isActor(actor), true);

        vm.expectEmit(address(administeredActor));
        emit IAdministeredAgent.ActorRemoved(actor, admin);

        vm.prank(admin);
        administeredActor.removeActor(actor);

        assertEq(administeredActor.actorCount(),     0);
        assertEq(administeredActor.__isActor(actor), false);
    }

    function test_removeActor_asRevoker() external {
        administeredActor.__addActor(actor);
        administeredActor.__addRevoker(revoker);

        assertEq(administeredActor.actorCount(),     1);
        assertEq(administeredActor.__isActor(actor), true);

        vm.expectEmit(address(administeredActor));
        emit IAdministeredAgent.ActorRemoved(actor, revoker);

        vm.prank(revoker);
        administeredActor.removeActor(actor);

        assertEq(administeredActor.actorCount(),     0);
        assertEq(administeredActor.__isActor(actor), false);
    }

    /**********************************************************************************************/
    /*** call Tests                                                                             ***/
    /**********************************************************************************************/

    function test_call_notActor() external {
        vm.expectRevert(IAdministeredAgent.NotActor.selector);

        vm.prank(unauthorized);
        administeredActor.call(makeAddr("target"), hex"12345678");
    }

    function test_call_reverts() external {
        administeredActor.__addActor(actor);

        address target = makeAddr("target");

        bytes memory data = hex"12345678";

        vm.mockCallRevert(target, data, hex"87654321");

        vm.expectRevert(bytes(hex"87654321"));

        vm.prank(actor);
        administeredActor.call(address(target), data);
    }

    function test_call_withNoValue() external {
        administeredActor.__addActor(actor);

        address target = makeAddr("target");

        bytes memory data = hex"12345678";

        vm.mockCall(target,   data, hex"87654321");
        vm.expectCall(target, data);

        vm.prank(actor);
        bytes memory result = administeredActor.call(address(target), data);

        assertEq(keccak256(result), keccak256(hex"87654321"));
    }

    function test_call_withValue() external {
        administeredActor.__addActor(actor);

        address target = makeAddr("target");

        bytes memory data = hex"12345678";

        vm.deal(actor, 1 ether);

        vm.mockCall(target,   0.5 ether, data, hex"87654321");
        vm.expectCall(target, 0.5 ether, data);

        vm.prank(actor);
        bytes memory result = administeredActor.call{ value: 0.5 ether }(address(target), data);

        assertEq(keccak256(result), keccak256(hex"87654321"));
    }

    /**********************************************************************************************/
    /*** batchCall Tests                                                                        ***/
    /**********************************************************************************************/

    function test_batchCall_notActor() external {
        vm.expectRevert(IAdministeredAgent.NotActor.selector);

        vm.prank(unauthorized);
        administeredActor.batchCall(new address[](0), new bytes[](0), new uint256[](0));
    }

    function test_batchCall_mismatchedArrayLengths() external {
        administeredActor.__addActor(actor);

        vm.expectRevert(IAdministeredAgent.MismatchedArrayLengths.selector);

        vm.prank(actor);
        administeredActor.batchCall(new address[](2), new bytes[](1), new uint256[](1));

        vm.expectRevert(IAdministeredAgent.MismatchedArrayLengths.selector);

        vm.prank(actor);
        administeredActor.batchCall(new address[](1), new bytes[](2), new uint256[](1));

        vm.expectRevert(IAdministeredAgent.MismatchedArrayLengths.selector);

        vm.prank(actor);
        administeredActor.batchCall(new address[](1), new bytes[](1), new uint256[](2));
    }

    function test_batchCall_reverts() external {
        administeredActor.__addActor(actor);

        address[] memory targets = new address[](3);
        targets[0] = makeAddr("target1");
        targets[1] = makeAddr("target2");
        targets[2] = makeAddr("target2");

        bytes[] memory data = new bytes[](3);
        data[0] = hex"12345678";
        data[1] = hex"87654321";
        data[2] = hex"11111111";

        uint256[] memory values = new uint256[](3);
        values[0] = 0;
        values[1] = 0;
        values[2] = 0;

        vm.mockCallRevert(targets[0], data[0], hex"22222222");

        vm.expectRevert(bytes(hex"22222222"));

        vm.prank(actor);
        administeredActor.batchCall(targets, data, values);

        vm.mockCall(targets[0],       data[0], "");
        vm.mockCallRevert(targets[1], data[1], hex"33333333");

        vm.expectRevert(bytes(hex"33333333"));

        vm.prank(actor);
        administeredActor.batchCall(targets, data, values);

        vm.mockCall(targets[0],       data[0], "");
        vm.mockCall(targets[1],       data[1], "");
        vm.mockCallRevert(targets[2], data[2], hex"44444444");

        vm.expectRevert(bytes(hex"44444444"));

        vm.prank(actor);
        administeredActor.batchCall(targets, data, values);
    }

    function test_batchCall_withNoValue() external {
        administeredActor.__addActor(actor);

        address[] memory targets = new address[](3);
        targets[0] = makeAddr("target1");
        targets[1] = makeAddr("target2");
        targets[2] = makeAddr("target2");

        bytes[] memory data = new bytes[](3);
        data[0] = hex"12345678";
        data[1] = hex"87654321";
        data[2] = hex"11111111";

        uint256[] memory values = new uint256[](3);
        values[0] = 0;
        values[1] = 0;
        values[2] = 0;

        vm.mockCall(targets[0],   data[0], hex"22222222");
        vm.expectCall(targets[0], data[0]);
        vm.mockCall(targets[1],   data[1], hex"33333333");
        vm.expectCall(targets[1], data[1]);
        vm.mockCall(targets[2],   data[2], hex"44444444");
        vm.expectCall(targets[2], data[2]);

        vm.prank(actor);
        bytes[] memory results = administeredActor.batchCall(targets, data, values);

        assertEq(results.length, 3);

        assertEq(keccak256(results[0]), keccak256(hex"22222222"));
        assertEq(keccak256(results[1]), keccak256(hex"33333333"));
        assertEq(keccak256(results[2]), keccak256(hex"44444444"));
    }

    function test_batchCall_withValue() external {
        administeredActor.__addActor(actor);

        address[] memory targets = new address[](3);
        targets[0] = makeAddr("target1");
        targets[1] = makeAddr("target2");
        targets[2] = makeAddr("target2");

        bytes[] memory data = new bytes[](3);
        data[0] = hex"12345678";
        data[1] = hex"87654321";
        data[2] = hex"11111111";

        uint256[] memory values = new uint256[](3);
        values[0] = 0.2 ether;
        values[1] = 0;
        values[2] = 0.5 ether;

        vm.deal(actor, 0.7 ether);

        vm.mockCall(targets[0],   0.2 ether, data[0], hex"22222222");
        vm.expectCall(targets[0], 0.2 ether, data[0]);
        vm.mockCall(targets[1],   0 ether,   data[1], hex"33333333");
        vm.expectCall(targets[1], 0 ether,   data[1]);
        vm.mockCall(targets[2],   0.5 ether, data[2], hex"44444444");
        vm.expectCall(targets[2], 0.5 ether, data[2]);

        vm.prank(actor);
        bytes[] memory results = administeredActor.batchCall{ value: 0.7 ether }(targets, data, values);

        assertEq(results.length, 3);

        assertEq(keccak256(results[0]), keccak256(hex"22222222"));
        assertEq(keccak256(results[1]), keccak256(hex"33333333"));
        assertEq(keccak256(results[2]), keccak256(hex"44444444"));
    }

    /**********************************************************************************************/
    /*** sendValue Tests                                                                        ***/
    /**********************************************************************************************/

    function test_sendValue_notActor() external {
        vm.expectRevert(IAdministeredAgent.NotActor.selector);

        vm.prank(unauthorized);
        administeredActor.sendValue(makeAddr("recipient"), 1 ether);
    }

    function test_sendValue() external {
        administeredActor.__addActor(actor);

        address recipient = makeAddr("recipient");

        vm.deal(address(administeredActor), 1 ether);

        vm.prank(actor);
        administeredActor.sendValue(recipient, 0.5 ether);

        assertEq(address(administeredActor).balance, 0.5 ether);
        assertEq(recipient.balance,                  0.5 ether);
    }

    /**********************************************************************************************/
    /*** adminCount Tests                                                                       ***/
    /**********************************************************************************************/

    function test_adminCount() external {
        assertEq(administeredActor.adminCount(), 1);

        administeredActor.__addAdmin(otherAdmin);

        assertEq(administeredActor.adminCount(), 2);

        administeredActor.__removeAdmin(otherAdmin);

        assertEq(administeredActor.adminCount(), 1);
    }

    /**********************************************************************************************/
    /*** actorCount Tests                                                                       ***/
    /**********************************************************************************************/

    function test_actorCount() external {
        assertEq(administeredActor.actorCount(), 0);

        administeredActor.__addActor(actor);

        assertEq(administeredActor.actorCount(), 1);

        administeredActor.__removeActor(actor);

        assertEq(administeredActor.actorCount(), 0);
    }

    /**********************************************************************************************/
    /*** grantorCount Tests                                                                     ***/
    /**********************************************************************************************/

    function test_grantorCount() external {
        assertEq(administeredActor.grantorCount(), 0);

        administeredActor.__addGrantor(grantor);

        assertEq(administeredActor.grantorCount(), 1);

        administeredActor.__removeGrantor(grantor);

        assertEq(administeredActor.grantorCount(), 0);
    }

    /**********************************************************************************************/
    /*** revokerCount Tests                                                                     ***/
    /**********************************************************************************************/

    function test_revokerCount() external {
        assertEq(administeredActor.revokerCount(), 0);

        administeredActor.__addRevoker(revoker);

        assertEq(administeredActor.revokerCount(), 1);

        administeredActor.__removeRevoker(revoker);

        assertEq(administeredActor.revokerCount(), 0);
    }

    /**********************************************************************************************/
    /*** getAdmin Tests                                                                         ***/
    /**********************************************************************************************/

    function test_getAdmin() external {
        administeredActor.__addAdmin(otherAdmin);

        assertEq(administeredActor.getAdmin(0), admin);
        assertEq(administeredActor.getAdmin(1), otherAdmin);
    }

    /**********************************************************************************************/
    /*** getActor Tests                                                                         ***/
    /**********************************************************************************************/

    function test_getActor() external {
        address otherActor = makeAddr("otherActor");

        administeredActor.__addActor(actor);
        administeredActor.__addActor(otherActor);

        assertEq(administeredActor.getActor(0), actor);
        assertEq(administeredActor.getActor(1), otherActor);
    }

    /**********************************************************************************************/
    /*** getGrantor Tests                                                                       ***/
    /**********************************************************************************************/

    function test_getGrantor() external {
        address otherGrantor = makeAddr("otherGrantor");

        administeredActor.__addGrantor(grantor);
        administeredActor.__addGrantor(otherGrantor);

        assertEq(administeredActor.getGrantor(0), grantor);
        assertEq(administeredActor.getGrantor(1), otherGrantor);
    }

    /**********************************************************************************************/
    /*** getRevoker Tests                                                                       ***/
    /**********************************************************************************************/

    function test_getRevoker() external {
        address otherRevoker = makeAddr("otherRevoker");

        administeredActor.__addRevoker(revoker);
        administeredActor.__addRevoker(otherRevoker);

        assertEq(administeredActor.getRevoker(0), revoker);
        assertEq(administeredActor.getRevoker(1), otherRevoker);
    }

    /**********************************************************************************************/
    /*** getIsAdmin Tests                                                                       ***/
    /**********************************************************************************************/

    function test_getIsAdmin() external view {
        assertEq(administeredActor.getIsAdmin(admin),        true);
        assertEq(administeredActor.getIsAdmin(unauthorized), false);
    }

    /**********************************************************************************************/
    /*** getIsActor Tests                                                                       ***/
    /**********************************************************************************************/

    function test_getIsActor() external {
        assertEq(administeredActor.getIsActor(actor), false);

        administeredActor.__addActor(actor);

        assertEq(administeredActor.getIsActor(actor), true);
    }

    /**********************************************************************************************/
    /*** getIsGrantor Tests                                                                     ***/
    /**********************************************************************************************/

    function test_getIsGrantor() external {
        assertEq(administeredActor.getIsGrantor(grantor), false);

        administeredActor.__addGrantor(grantor);

        assertEq(administeredActor.getIsGrantor(grantor), true);
    }

    /**********************************************************************************************/
    /*** getIsRevoker Tests                                                                     ***/
    /**********************************************************************************************/

    function test_getIsRevoker() external {
        assertEq(administeredActor.getIsRevoker(revoker), false);

        administeredActor.__addRevoker(revoker);

        assertEq(administeredActor.getIsRevoker(revoker), true);
    }

}
