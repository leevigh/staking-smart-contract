// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

contract StakeEther {
    
    address public owner;

    struct Stake {
        uint256 amount;
        uint256 rewards;
        uint256 stakeTime;
        uint256 endTime;
        bool isClaimed;
    }

    constructor() payable {
        require(msg.value > 0, "You need to add reward ether");
        owner = msg.sender;
    }

    mapping(address => Stake[]) public totalStakes;
    mapping(address => uint256) public balances;

    event StakedSuccessfully(address indexed staker, uint256 amount, uint256 endTime);
    event WithdrawalSuccessful(address indexed staker, uint256 amount);

    // Function to stake Ether
    function stakeEther() external payable {
        require(msg.sender != address(0), "Address zero not allowed");
        require(msg.value > 0, "Amount must be more than zero");

        balances[msg.sender] += msg.value;

        Stake memory _stake = Stake({
            amount: msg.value,
            rewards: 0,
            stakeTime: block.timestamp,
            endTime: block.timestamp + 30 * 1 days,
            // endTime: block.timestamp + 60,
            isClaimed: false
        });

        totalStakes[msg.sender].push(_stake);

        emit StakedSuccessfully(msg.sender, msg.value, _stake.endTime);
    }

    function getMyStakes() external view returns (Stake[] memory) {
        return totalStakes[msg.sender];
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Function to withdraw staked Ether and earned rewards
    function withdrawReward(uint256 _index) external {
        require(totalStakes[msg.sender].length > 0, "You have no stakes");
        Stake storage selectedStake = totalStakes[msg.sender][_index];
        require(!selectedStake.isClaimed, "You have already claimed your rewards");
        require(block.timestamp >= selectedStake.endTime, "Stake period is still ongoing");

        uint256 _principal = selectedStake.amount;
        // uint256 _stakeDuration = selectedStake.endTime - selectedStake.stakeTime; // Calculate duration based on time staked

        // Test app calculation for 1 minute
        uint256 _stakeDurationInMinutes = (selectedStake.endTime - selectedStake.stakeTime) / 60; // Duration in minutes
        uint256 _interest = calculateInterestInMinutes(_principal, _stakeDurationInMinutes);
        selectedStake.rewards += _interest;

        // Calculate the interest for the actual staking duration
        // uint256 _interest = calculateInterest(_principal, _stakeDuration);
        // selectedStake.rewards += _interest;

        balances[msg.sender] -= selectedStake.amount;

        // Transfer staked amount and rewards back to the user
        uint256 totalAmount = selectedStake.amount + selectedStake.rewards;
        selectedStake.isClaimed = true;

        // Transfer Ether
        (bool success, ) = msg.sender.call{value: totalAmount}("");
        require(success, "Ether transfer failed");

        emit WithdrawalSuccessful(msg.sender, totalAmount);
    }

    // Function to calculate interest with precision to avoid floats
    function calculateInterest(uint256 _principal, uint256 _stakeDuration) private pure returns (uint256) {
        uint256 rate = 10; // 10% annual rate
        uint256 precision = 1e18; // Precision factor to handle fixed-point arithmetic
        uint256 timeInYears = (_stakeDuration * precision) / 365 days; // Scale time to maintain precision

        // Simple Interest Formula: (Principal * Rate * Time) / 100
        uint256 interest = (_principal * rate * timeInYears) / (100 * precision);

        return interest;
    }

    function calculateInterestInMinutes(uint256 _principal, uint256 _stakeDurationInMinutes) private pure returns (uint256) {
        uint256 rate = 10; // 10% annual rate
        uint256 precision = 1e18; // Precision factor to handle fixed-point arithmetic

        // Convert minutes to a fraction of a year for interest calculation
        uint256 timeInYears = (_stakeDurationInMinutes * precision) / (365 days / 1 minutes); // 1 year in minutes

        // Simple Interest Formula: (Principal * Rate * Time) / 100
        uint256 interest = (_principal * rate * timeInYears) / (100 * precision);

        return interest;
    }

    // Fallback function to accept Ether sent directly to the contract
    receive() external payable {}
}
