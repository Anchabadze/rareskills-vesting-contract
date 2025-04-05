// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Time unlocked ERC20 / vesting contract
 * @notice Rareskills beginner solidity projects list
 * @author Zurab Anchabadze (https://x.com/anchabadze)
 */
contract Vesting is Ownable(msg.sender) {
    using SafeERC20 for IERC20;

    IERC20 public token;
    address public payer;
    address public receiver;
    uint256 public totalAmount;
    uint256 public startTime;
    uint256 public duration;
    uint256 public claimedAmount;

    constructor(address _token, address _payer, address _receiver) {
        token = IERC20(_token);
        payer = _payer;
        receiver = _receiver;
    }

    modifier onlyPayer() {
        require(msg.sender == payer, "Only payer can call this function");
        _;
    }

    modifier onlyReceiver() {
        require(msg.sender == receiver, "Only receiver can call this function");
        _;
    }

    function deposit(uint256 _totalAmount, uint256 _duration) external onlyPayer {
        require(token.balanceOf(address(this)) == 0, "Already deposited");
        require(_totalAmount > 0, "Total amount must be greater than 0");
        require(_duration > 0, "Duration must be greater than 0");
        totalAmount = _totalAmount;
        duration = _duration;
        startTime = block.timestamp;
        token.safeTransferFrom(msg.sender, address(this), _totalAmount);
    }

    function claim() external onlyReceiver {
        require(block.timestamp >= startTime, "Vesting has not started yet");
        require(claimedAmount < totalAmount, "All tokens have been claimed");
        uint256 timePassed = block.timestamp - startTime;
        if (timePassed > duration) {
            uint256 amountToClaim = totalAmount - claimedAmount;
            claimedAmount += amountToClaim;
            token.safeTransfer(receiver, amountToClaim);
        } else {
            uint256 unlockedAmount = (totalAmount * timePassed) / duration;
            require(unlockedAmount > claimedAmount, "No claimable amount available");
            uint256 amountToClaim = unlockedAmount - claimedAmount;
            claimedAmount += amountToClaim;
            token.safeTransfer(receiver, amountToClaim);
        }
    }
}
