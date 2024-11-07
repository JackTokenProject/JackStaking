// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Staking20} from "@thirdweb-dev/contracts/extension/Staking20.sol";
import {IERC20} from "@thirdweb-dev/contracts/eip/interface/IERC20.sol";
import {IERC20Metadata} from "@thirdweb-dev/contracts/eip/interface/IERC20Metadata.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract JackStaking is Staking20, Ownable2Step {
    address public rewardTokenHolder;

    event MinStakeTimeChanged(
        uint80 oldMinStakeLockTime,
        uint80 newMinStakeLockTime
    );

    event MinStakeAmountChanged(
        uint256 oldMinStakeAmount,
        uint256 newMinStakeAmount
    );

    event RewardTokenHolderChanged(
        address oldRewardTokenHolder,
        address newRewardTokenHolder
    );

    error MinStakeAmountError();
    error TimeUnitError();
    error RewardRatioError();
    error MinStakeLockTimeError();
    error RewardTokenHolderError();
    error InsufficientBalanceError();
    error StakeAmountError();
    error NotAuthorized();
    error CantWithdraw();

    struct ExtendedStaker {
        address staker;
        uint128 timeOfLastUpdate;
        uint256 amountStaked;
    }

    uint80 public constant maxStakeLockTime = 30 days;
    uint80 public minStakeLockTime;
    mapping(address staker => uint80) private lastStakeTimes;

    uint256 public minStakeAmount;

    constructor(
        uint80 _timeUnit,
        uint256 _rewardRatioNumerator,
        uint256 _rewardRatioDenominator,
        address _stakingToken,
        address _rewardTokenHolder,
        address _nativeTokenWrapper,
        uint80 _minStakeLockTime,
        uint256 _minStakeAmount
    )
        Staking20(
            _nativeTokenWrapper,
            _stakingToken,
            IERC20Metadata(_stakingToken).decimals(),
            IERC20Metadata(_stakingToken).decimals()
        )
        Ownable()
    {
        if (_minStakeAmount == 0) {
            revert MinStakeAmountError();
        }

        if (_timeUnit == 0) {
            revert TimeUnitError();
        }

        if (_rewardRatioNumerator == 0) {
            revert RewardRatioError();
        }

        if (_rewardRatioDenominator == 0) {
            revert RewardRatioError();
        }

        if (_minStakeLockTime == 0 || _minStakeLockTime > maxStakeLockTime) {
            revert MinStakeLockTimeError();
        }

        if (_rewardTokenHolder == address(0)) {
            revert RewardTokenHolderError();
        }

        _setStakingCondition(
            _timeUnit,
            _rewardRatioNumerator,
            _rewardRatioDenominator
        );
        minStakeAmount = _minStakeAmount;
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
        public
        view
        override
        returns (uint256 _rewardsAvailableInContract)
    {
        _rewardsAvailableInContract = IERC20(stakingToken).balanceOf(
            rewardTokenHolder
        );
    }

    function _claimRewards() internal virtual override {
        uint256 rewardsToClaim = stakers[_stakeMsgSender()].unclaimedRewards +
            _calculateRewards(_stakeMsgSender());

        if (getRewardTokenBalance() < rewardsToClaim) {
            revert InsufficientBalanceError();
        }
        super._claimRewards();
    }

    function _stake(uint256 _amount) internal virtual override {
        if (_amount < minStakeAmount) {
            revert StakeAmountError();
        }
        lastStakeTimes[_stakeMsgSender()] = uint80(block.timestamp);
        super._stake(_amount);
    }

    function _withdraw(uint256 _amount) internal virtual override {
        if (!canWithdraw(_stakeMsgSender())) {
            revert CantWithdraw();
        }
        super._withdraw(_amount);
    }

    function canWithdraw(address staker) public view returns (bool) {
        return (uint80(block.timestamp) > (lastStakeTimes[staker] + minStakeLockTime));
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
        if (_minStakeLockTime == 0 || _minStakeLockTime > maxStakeLockTime) {
            revert MinStakeLockTimeError();
        }

        if (!_canSetStakeConditions()) {
            revert NotAuthorized();
        }
        emit MinStakeTimeChanged(minStakeLockTime, minStakeLockTime);
        minStakeLockTime = _minStakeLockTime;
    }

    function setMinStakeAmount(uint256 _minStakeAmount) external {
        if (_minStakeAmount == 0) {
            revert MinStakeAmountError();
        }
        if (!_canSetStakeConditions()) {
            revert NotAuthorized();
        }
        emit MinStakeAmountChanged(minStakeAmount, _minStakeAmount);
        minStakeAmount = _minStakeAmount;
    }

    function setRewardTokenHolder(address _rewardTokenHolder) external {
        if (_rewardTokenHolder == address(0)) {
            revert RewardTokenHolderError();
        }
        if (!_canSetStakeConditions()) {
            revert NotAuthorized();
        }
        emit RewardTokenHolderChanged(rewardTokenHolder, _rewardTokenHolder);
        rewardTokenHolder = _rewardTokenHolder;
    }
}
