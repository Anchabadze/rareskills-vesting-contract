// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Vesting} from "../src/Vesting.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {console} from "forge-std/console.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract VestingTest is Test {
    using SafeERC20 for MockERC20;

    Vesting public vesting;
    MockERC20 public token;
    address public deployer = makeAddr("deployer");
    address public payer = makeAddr("payer");
    address public receiver = makeAddr("receiver");

    function setUp() public {
        vm.startPrank(deployer);
        token = new MockERC20();
        vesting = new Vesting(address(token), payer, receiver);
        token.safeTransfer(payer, 1000);
        vm.stopPrank();
    }

    function test_depositSuccess() public {
        _depositTokens();

        assertEq(token.balanceOf(address(vesting)), 1000, "Vesting contract should hold 1000 tokens");
        assertEq(vesting.duration(), 10 days, "Vesting duration should be 10 days");
    }

    function test_claimSuccess() public {
        _depositTokens();
        uint256 timePassed = 5 days;
        vm.warp(vesting.startTime() + timePassed);
        vm.startPrank(receiver);
        vesting.claim();
        vm.stopPrank();

        uint256 expectedClaimedAmount = (vesting.totalAmount() * timePassed) / vesting.duration();
        assertEq(token.balanceOf(receiver), expectedClaimedAmount, "Receiver should have received the claimed amount");
        uint256 remainingAmount = vesting.totalAmount() - expectedClaimedAmount;
        assertEq(
            token.balanceOf(address(vesting)), remainingAmount, "Vesting contract should hold the remaining amount"
        );
        assertEq(vesting.claimedAmount(), expectedClaimedAmount, "Vesting contract should have updated claimed amount");
    }

    function test_claimSuccess20Days() public {
        _depositTokens();
        uint256 timePassed = 20 days;
        vm.warp(vesting.startTime() + timePassed);
        vm.startPrank(receiver);
        vesting.claim();
        vm.stopPrank();

        uint256 expectedClaimedAmount = vesting.totalAmount();
        assertEq(token.balanceOf(receiver), expectedClaimedAmount, "Receiver should have received the claimed amount");
        uint256 remainingAmount = vesting.totalAmount() - expectedClaimedAmount;
        assertEq(
            token.balanceOf(address(vesting)), remainingAmount, "Vesting contract should hold the remaining amount"
        );
        assertEq(vesting.claimedAmount(), expectedClaimedAmount, "Vesting contract should have updated claimed amount");
    }

    function test_claimSuccessTwoClaims() public {
        _depositTokens();
        _twoClaims();
    }

    function test_claimSuccessThreeClaimsFinal() public {
        _depositTokens();
        _twoClaims();

        // another 5 days
        uint256 timePassed = 5 days;
        vm.warp(block.timestamp + timePassed);
        vm.startPrank(receiver);
        vesting.claim();
        vm.stopPrank();

        assertEq(token.balanceOf(address(vesting)), 0, "Vesting contract should hold 0 tokens");
        assertEq(token.balanceOf(receiver), vesting.totalAmount(), "Receiver should have received the claimed amount");
        assertEq(vesting.totalAmount(), vesting.claimedAmount(), "Vesting contract should have updated claimed amount");
    }

    function _depositTokens() internal {
        vm.startPrank(payer);
        token.approve(address(vesting), 1000);
        vesting.deposit(1000, 10 days);
        vm.stopPrank();
    }

    function _twoClaims() internal {
        uint256 timePassed = 3 days;
        vm.warp(vesting.startTime() + timePassed);
        vm.startPrank(receiver);
        vesting.claim();
        vm.stopPrank();

        uint256 expectedClaimedAmount = (vesting.totalAmount() * timePassed) / vesting.duration();
        assertEq(token.balanceOf(receiver), expectedClaimedAmount, "Receiver should have received the claimed amount");
        uint256 remainingAmount = vesting.totalAmount() - vesting.claimedAmount();
        assertEq(
            token.balanceOf(address(vesting)), remainingAmount, "Vesting contract should hold the remaining amount"
        );
        assertEq(vesting.claimedAmount(), expectedClaimedAmount, "Vesting contract should have updated claimed amount");

        // another 4 days
        timePassed = 4 days;
        vm.warp(block.timestamp + timePassed);
        vm.startPrank(receiver);
        vesting.claim();
        vm.stopPrank();

        assertEq(token.balanceOf(receiver), vesting.claimedAmount(), "Receiver should have received the claimed amount");
        remainingAmount = vesting.totalAmount() - vesting.claimedAmount();
        assertEq(
            token.balanceOf(address(vesting)), remainingAmount, "Vesting contract should hold the remaining amount"
        );
    }
}
