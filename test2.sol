// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TimeLockedWallet {
    address payable depositor;
    address payable authorizedWithdrawAddress;
    uint256 depositTime;
    uint256 lockTime;
    uint256 depositAmount;
    uint256 initialDepositAmount;

    address payable[5] public feeAddresses;

    constructor(
        uint256 _lockTime, 
        address payable _authorizedWithdrawAddress, 
        address payable _feeAddress1,
        address payable _feeAddress2,
        address payable _feeAddress3,
        address payable _feeAddress4,
        address payable _feeAddress5
    ) payable {
        depositor = payable(msg.sender);
        depositAmount = msg.value;
        depositTime = block.timestamp;
        lockTime = _lockTime;
        authorizedWithdrawAddress = _authorizedWithdrawAddress;
        feeAddresses[0] = _feeAddress1;
        feeAddresses[1] = _feeAddress2;
        feeAddresses[2] = _feeAddress3;
        feeAddresses[3] = _feeAddress4;
        feeAddresses[4] = _feeAddress5;
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
        authorizedWithdrawAddress.transfer(address(this).balance);
    }

    function withdrawDistribution(address payable _destination) public {
        if (msg.sender != depositor && msg.sender != authorizedWithdrawAddress) {
            revert("Only depositor or authorized withdrawal address can withdraw half.");
        }
        if (depositAmount == 0) {
            revert("No deposit to withdraw.");
        }
        if (depositAmount < initialDepositAmount * 2) {
            revert("Initial deposit amount has not been doubled.");
        }
        uint256 fee = depositAmount / 10;
        uint256 feePerAddress = fee / 5;
        for (uint i = 0; i < feeAddresses.length; i++) {
            payable(feeAddresses[i]).transfer(feePerAddress);
        }
        uint256 amountToWithdraw = depositAmount - fee;
        depositAmount = 0;
        for (uint i = 0; i < feeAddresses.length; i++) {
            payable(feeAddresses[i]).transfer(feePerAddress);
        }
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
