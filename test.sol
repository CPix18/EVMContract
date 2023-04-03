// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeLockedWallet {
    address payable depositor;
    address payable authorizedWithdrawAddress;
    address private address_;
    uint256 depositTime;
    uint256 lockTime;
    uint256 depositAmount;
    uint256 initialDepositAmount;
    bytes32 memo;

    constructor(uint256 _lockTime, address payable _authorizedWithdrawAddress, bytes32 _memo) payable {
        depositor = payable(msg.sender);
        depositAmount = msg.value;
        depositTime = block.timestamp;
        lockTime = _lockTime;
        authorizedWithdrawAddress = _authorizedWithdrawAddress;
        memo = _memo;
        // Input address for 10% fee collection below, remove quotation marks
        address_ = "0x...";
    }

    function setMemo(bytes32 _memo) public {
        if (msg.sender != depositor) {
            revert("Only depositor can add a memo.");
        }
        memo = _memo;
    }

    function addFunds() public payable {
        depositAmount += msg.value;
    }

    function setAuthorizedWithdrawAddress(address payable _address) public {
        if (msg.sender != depositor && msg.sender != authorizedWithdrawAddress) {
            revert("Only depositor or authorized withdrawal address can change authorized withdrawal address.");
        }
        authorizedWithdrawAddress = _address;
    }

    function addTime(uint256 time) public {
        if (msg.sender != depositor) {
            revert("Only depositor can add time.");
        }
        lockTime += time;
    }

    function subtractTime(uint256 time) public {
        if (msg.sender != depositor) {
            revert("Only depositor can subtract time.");
        }
        if (lockTime < time) {
            revert("Lock time cannot be negative.");
        }
        lockTime -= time;
    }

    function withdraw() public {
        if (msg.sender != authorizedWithdrawAddress) {
            revert("Only authorized withdrawal address can withdraw.");
        }
        if (!checkLockTimeCompleted()) {
            revert("Not enough time has passed.");
        }
        authorizedWithdrawAddress.transfer(depositAmount);
    }

    function withdrawHalf(address payable _destination) public {
        if (msg.sender != depositor && msg.sender != authorizedWithdrawAddress) {
            revert("Only depositor or authorized withdrawal address can withdraw half.");
        }
        if (depositAmount == 0) {
            revert("No deposit to withdraw.");
        }
        if (depositAmount < initialDepositAmount * 2) {
            revert("Initial deposit amount has not been doubled.");
        }
        uint256 amountToWithdraw = depositAmount / 2;
        uint256 fee = depositAmount / 10;
        depositAmount -= amountToWithdraw;
        payable(address_).transfer(fee);
        _destination.transfer(amountToWithdraw);
    }

    function checkLockTimeCompleted() public view returns (bool) {
        uint256 totalLockTime = depositTime + lockTime;
        uint256 currentTime = block.timestamp;
        return currentTime >= totalLockTime;
    }

    function getWithdrawableBlock() public view returns (uint256) {
        require(block.timestamp >= depositTime, "Current time is before deposit time.");
        uint256 elapsedTime = block.timestamp - depositTime;
        uint256 remainingTime = lockTime - elapsedTime;
        uint256 withdrawBlock = block.number + remainingTime / 15;
        return withdrawBlock;
    }

    function getCurrentBlock() public view returns (uint256) {
        return block.number;
    }

    function lockTimeLeft() public view returns (uint256) {
        if (checkLockTimeCompleted()) {
            return 0;
        } else {
            return depositTime + lockTime - block.timestamp;
        }
    }
}
