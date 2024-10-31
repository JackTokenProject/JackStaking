// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import {Staking20} from "@thirdweb-dev/contracts/extension/Staking20.sol";
import {IERC20} from "@thirdweb-dev/contracts/eip/interface/IERC20.sol";
import {IERC20Metadata} from "@thirdweb-dev/contracts/eip/interface/IERC20Metadata.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract JackStaking is Staking20, Ownable {
    address public rewardTokenHolder;

    event MinStakeTimeChanged(
        uint80 oldMinStakeLockTime,
        uint80 minStakeLockTime
    );

    event RewardTokenHolderChanged(
        address oldRewardTokenHolder,
        address newRewardTokenHolder
    );

    struct ExtendedStaker {
        address staker;
        uint128 timeOfLastUpdate;
        uint256 amountStaked;
    }

    
    uint80 constant public maxStakeLockTime = 2592000;
    uint80 public minStakeLockTime;
    mapping(address staker => uint80) private lastStakeTimes;

    constructor(
        uint80 _timeUnit,
        uint256 _rewardRatioNumerator,
        uint256 _rewardRatioDenominator,
        address _stakingToken,
        address _rewardTokenHolder,
        address _nativeTokenWrapper,
        uint80 _minStakeLockTime
    )
        Staking20(
            _nativeTokenWrapper,
            _stakingToken,
            IERC20Metadata(_stakingToken).decimals(),
            IERC20Metadata(_stakingToken).decimals()
        )
        Ownable()
    {

        require(_timeUnit != 0, "Invalid _timeUnit!");
        require(_rewardRatioNumerator != 0, "Invalid _rewardRatioNumerator!");
        require(_rewardRatioDenominator != 0, "Invalid _rewardRatioDenominator!");
        require(_minStakeLockTime != 0, "Invalid _minStakeLockTime!");
        require(_rewardTokenHolder != address(0), "Invalid _rewardTokenHolder!");
        _setStakingCondition(
            _timeUnit,
            _rewardRatioNumerator,
            _rewardRatioDenominator
        );

        minStakeLockTime = _minStakeLockTime;
        rewardTokenHolder = _rewardTokenHolder;
    }

    /**
     *  @dev    Mint/Transfer ERC20 rewards to the staker. Must override.
     *
     *  @param _staker    Address for sending rewards to.
     *  @param _rewards   Amount of tokens to be given out as reward.
     *
     */
    function _mintRewards(address _staker, uint256 _rewards) internal override {
        IERC20(stakingToken).transferFrom(rewardTokenHolder, _staker, _rewards);
    }

    function totalStakers() public view returns (uint) {
        return stakersArray.length;
    }

    function getRewardTokenBalance()
        external
        view
        override
        returns (uint256 _rewardsAvailableInContract)
    {
        _rewardsAvailableInContract = IERC20(stakingToken).balanceOf(
            rewardTokenHolder
        );
    }

    function _stake(uint256 _amount) internal virtual override {
        lastStakeTimes[_stakeMsgSender()] = uint80(block.timestamp);
        super._stake(_amount);
    }

    function _withdraw(uint256 _amount) internal virtual override {
        uint80 lastStakeTime = lastStakeTimes[_stakeMsgSender()];
        if (uint80(block.timestamp) > (lastStakeTime + minStakeLockTime)) {
            super._withdraw(_amount);
        }
    }

    function canWithdraw(address staker) public view returns (bool) {
        uint80 lastStakeTime = lastStakeTimes[staker];
        if (uint80(block.timestamp) > (lastStakeTime + minStakeLockTime)) {
            return true;
        }
        return false;
    }

    // Returns whether staking restrictions can be set in given execution context.
    function _canSetStakeConditions() internal view override returns (bool) {
        return msg.sender == owner();
    }

    function getStakerAtIndex(
        uint index
    ) public view returns (ExtendedStaker memory e) {
        address a = stakersArray[index];
        Staker memory s = stakers[a];
        e.staker = a;
        e.amountStaked = s.amountStaked;
        e.timeOfLastUpdate = s.timeOfLastUpdate;
    }

    function setMinStakeLockTime(uint80 _minStakeLockTime) external {
        require(_minStakeLockTime > maxStakeLockTime, "Min lockTime exceeded!");
        if (!_canSetStakeConditions()) {
            revert("Not authorized");
        }
        emit MinStakeTimeChanged(minStakeLockTime, minStakeLockTime);
        minStakeLockTime = _minStakeLockTime;
    }

    function setRewardTokenHolder(address _rewardTokenHolder) external {
        require(_rewardTokenHolder != address(0), "Invalid _rewardTokenHolder!");
        if (!_canSetStakeConditions()) {
            revert("Not authorized");
        }
        emit RewardTokenHolderChanged(rewardTokenHolder, _rewardTokenHolder);
        rewardTokenHolder = _rewardTokenHolder;
    }
}
