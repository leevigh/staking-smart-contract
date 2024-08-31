// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StakeToken {
    
    address owner;
    address tokenAddress;

    struct Stake {
        uint256 amount;
        uint256 rewards;
        uint256 stakeTime;
        uint256 endTime;
        bool isClaimed;
    }

    constructor(address _tokenAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;

    }

    mapping(address => Stake[]) public totalStakes;

    mapping(address => uint256) public balances;

    event StakedSuccessfully(address indexed staker, uint256 amount, uint256 endTime);
    event WithdrawalSuccessful(address indexed staker, uint256 amount);


    function stakeTokens(uint256 _amount) external {
        require(msg.sender != address(0), "Address zero not allowed");
        require(_amount > 0, "Amount must be more than zero");

        uint256 _userTokenBalance = IERC20(tokenAddress).balanceOf(msg.sender);
        require(_userTokenBalance >= _amount, "Insufficient balance");

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount);

        balances[msg.sender] += _amount;

        Stake memory _stake = Stake({
            amount: _amount,
            rewards: 0,
            // stakeTime: 30 * 1 days,
            stakeTime: block.timestamp,
            // endTime: block.timestamp + 30 * 1 days,
            endTime: block.timestamp + 30 * 1 days,
            isClaimed: false
        });

        totalStakes[msg.sender].push(_stake);

        emit StakedSuccessfully(msg.sender, _amount, _stake.endTime);
    }

    // function stakeTokens(uint256 _amount ) external {
    //     require(msg.sender != address(0), "Address zero not allowed");
    //     require(_amount > 0, "Amount must be more than zero");

    //     uint256 _userTokenBalance = IERC20(tokenAddress).balanceOf(msg.sender);
    //     require(_userTokenBalance >= _amount, "Insufficient balance");

    //     IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount);

    //     balances[msg.sender] += _amount;

    //     Stake memory _stake = Stake({
    //         amount: _amount,
    //         rewards: 0,
    //         stakeTime: 30 * 1 days,
    //         endTime: block.timestamp + 30 * 1 days,
    //         isClaimed: false
    //     });

    //     totalStakes[msg.sender].push(_stake);

    //     emit StakedSuccessfully(msg.sender, _amount, _stake.endTime);

    // }

    function getMyStakes() external view returns(Stake[] memory) {
        return totalStakes[msg.sender];
    }

    function withdrawRewardTokens(uint _index) external {
        require(totalStakes[msg.sender].length > 0, "You have no stakes");
        
        Stake storage selectedStake = totalStakes[msg.sender][_index];
        require(!selectedStake.isClaimed, "You have already claimed reward tokens");
        require(block.timestamp >= selectedStake.endTime, "Stake still ongoing");

        uint _principal = selectedStake.amount;
        // uint _stakeDuration = block.timestamp - selectedStake.stakeTime; // Calculate duration based on time staked
        uint _stakeDuration = selectedStake.endTime; // Calculate duration based on time staked

        // Calculate the interest for the actual staking duration
        uint _interest = calculateInterest(_principal, _stakeDuration / 60); // Divide by 60 to convert seconds to minutes
        selectedStake.rewards += _interest;

        balances[msg.sender] -= selectedStake.amount;

        // Transfer staked amount and rewards back to the user
        IERC20(tokenAddress).transfer(msg.sender, selectedStake.amount + selectedStake.rewards);
        
        // Mark stake as claimed
        selectedStake.isClaimed = true;

        emit WithdrawalSuccessful(msg.sender, selectedStake.amount + selectedStake.rewards);
    }


    // function withdrawRewardTokens(uint _index) external {
    //     require(totalStakes[msg.sender][_index].isClaimed == false, "You have already claimed reward tokens");
    //     require(totalStakes[msg.sender].length > 0, "You have no stakes");

    //     uint _principal = totalStakes[msg.sender][_index].amount;
    //     uint _stakeDuration = block.timestamp - (totalStakes[msg.sender][_index].endTime - 30 days); // Corrected calculation
    //     uint _interest = calculateInterestInMinutes(_principal, _stakeDuration);
    //     totalStakes[msg.sender][_index].rewards += _interest;

    //     Stake storage selectedStake = totalStakes[msg.sender][_index];
    //     require(block.timestamp > selectedStake.endTime, "Stake still going");
    //     require(!selectedStake.isClaimed, "Stake already claimed");
        
    //     balances[msg.sender] -= selectedStake.amount;

    //     IERC20(tokenAddress).transfer(msg.sender, selectedStake.amount + selectedStake.rewards);
    //     selectedStake.isClaimed = true;

    //     emit WithdrawalSuccessful(msg.sender, selectedStake.amount + selectedStake.rewards);
    // }

    // function withdrawRewardTokens(uint _index) external {
    //     require(totalStakes[msg.sender][_index].isClaimed == false, "You have already claimed reward tokens");
    //     require(totalStakes[msg.sender].length > 0, "You have no stakes");

    //     uint _principal = totalStakes[msg.sender][_index].amount;
    //     // uint _rate = rate;
    //     uint _stakeDuration = totalStakes[msg.sender][_index].stakeTime - block.timestamp;
    //     uint _interest = calculateInterest(_principal, _stakeDuration);
    //     totalStakes[msg.sender][_index].rewards += _interest;

    //     Stake storage selectedStake = totalStakes[msg.sender][_index];
    //     require(block.timestamp > selectedStake.endTime, "Stake still going");
    //     require(!selectedStake.isClaimed, "Stake already claimed");
        
        
    //     balances[msg.sender] -= selectedStake.amount;

    //     IERC20(tokenAddress).transfer(msg.sender, selectedStake.amount + selectedStake.rewards);
    //     selectedStake.isClaimed = true;

    //     emit WithdrawalSuccessful(msg.sender, selectedStake.amount + selectedStake.rewards);

    // }

    // calculate interest with precision to avoid floats
    function calculateInterest(uint256 _principal, uint _stakeDuration) private pure returns (uint256) {
        uint256 rate = 10; // 10% annual rate
        uint256 precision = 1e18; // Precision factor to handle fixed-point arithmetic
        uint256 timeInYears = (_stakeDuration * precision) / 365 days; // Scale time to maintain precision

        // Simple Interest Formula: (Principal * Rate * Time) / 100
        uint256 interest = (_principal * rate * timeInYears) / (100 * precision);

        return interest;
    }

    // calculate interest in minutes
    // function calculateInterestInMinutes(uint256 _principal, uint _stakeDurationInMinutes) private pure returns (uint256) {
    //     uint256 rate = 10; // 10% annual rate
    //     uint256 precision = 1e18; // Precision factor to handle fixed-point arithmetic
    //     uint256 timeInYears = (_stakeDurationInMinutes * 1 minutes * precision) / 365 days; // Scale time to maintain precision

    //     // Simple Interest Formula: (Principal * Rate * Time) / 100
    //     uint256 interest = (_principal * rate * timeInYears) / (100 * precision);

    //     return interest;
    // }

    // function calculateInterest(uint256 _principal, uint _stakeDuration) private pure returns (uint256) {
    //     uint256 rate = 10; // 10% annual rate
    //     uint256 timeInYears = _stakeDuration / 365 days; // Convert duration to years

    //     // Simple Interest Formula: (Principal * Rate * Time) / 100
    //     uint256 interest = (_principal * rate * timeInYears) / 100;

    //     return interest;
    // }


    // function calculateInterest(uint256 _principal, uint _stakeDuration) private pure returns(uint256) {
    //     // uint256 timeInYears = daysStaked * 1e18 / 365;
    //     uint interest = (_principal * 10 * _stakeDuration) / (100 * 365 * 1440);

    //     return interest;
    // }

    // function claimReward(address _address, uint _index) external {
    //     require(totalStakes[_address][_index].rewards > 0, "No valid stake");

    //     Stake storage selectedStake = totalStakes[_address][_index];
    //     require(block.timestamp > selectedStake.endTime, "Stake still going");

    //     require(!selectedStake.isCompleted, "Stake already completed");

    //     require(address(this).balance >= selectedStake.rewards, "Not enough funds in contract");

    //     selectedStake.isCompleted = true;
    //     (bool success,) = msg.sender.call{value: selectedStake.rewards}("");
    //     require(success, "Reward transfer failed");
    // }
}
