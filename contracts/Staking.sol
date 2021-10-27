// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Staking is Ownable {
    using SafeMath for uint;
    
    uint BIGNUMBER = 10**18;
    uint DECIMAL = 10**3;

    struct stakingInfo {
        uint amount;
        bool requested;
        uint releaseDate;
    }
        
    //allowed token addresses
    mapping (address => bool) public allowedTokens;

    mapping (address => mapping(address => stakingInfo)) public StakeMap; //tokenAddr to user to stake amount - stake[address]
    mapping (address => mapping(address => uint)) public userCummRewardPerStake; //tokenAddr to user to cummulative per token at the time of depoit - S0[address]
    mapping (address => uint) public tokenCummRewardPerStake; //tokenAddr to cummulative per token reward since the beginning till now - S
    mapping (address => uint) public tokenTotalStaked; //tokenAddr to total token claimed - T
    
    
    modifier isValidToken(address _tokenAddr){
        require(allowedTokens[_tokenAddr]);
        _;
    }
    
    /**
    * @dev add approved token address to the mapping 
    * @param _tokenAddr the token addressacceptable
    */
    function addToken(address _tokenAddr) onlyOwner external {
        require(keccak256(abi.encodePacked(ERC20(_tokenAddr).symbol())) == keccak256(abi.encodePacked("KTN")));
        allowedTokens[_tokenAddr] = true;
    }
    
    /**
    * @dev remove approved token address from the mapping 
    */
    function removeToken(address _tokenAddr) onlyOwner external {
        allowedTokens[_tokenAddr] = false;
    }

    /**
    * @dev deposit a specific amount to a token to stake
    * @param _amount the amount to be staked
    * @param _tokenAddr the token the user wish to stake on
    * for now, users are unable to add to the current deposit.
    */
    function deposit(uint _amount, address _tokenAddr) isValidToken(_tokenAddr) external returns (bool) {
        require(_amount != 0);
        require(StakeMap[_tokenAddr][msg.sender].amount == 0);
        // require(ERC20(_tokenAddr).approve(address(this), _amount));
        require(ERC20(_tokenAddr).transferFrom(msg.sender, address(this), _amount));
        
        return _deposit(_amount, _tokenAddr);
    }
    
    function _deposit(uint _amount, address _tokenAddr) internal returns (bool) {
        StakeMap[_tokenAddr][msg.sender].amount = _amount;
        userCummRewardPerStake[_tokenAddr][msg.sender] = tokenCummRewardPerStake[_tokenAddr];
        tokenTotalStaked[_tokenAddr] = tokenTotalStaked[_tokenAddr].add(_amount);
        return true;
    }

    /**
    * @dev returns the user's remaining stake amount
    * @param _tokenAddr the address of the staked token contracts
    * @param _userAddr the address of the user
    */
    function getStakedAmountByToken(address _tokenAddr, address _userAddr) isValidToken(_tokenAddr) public view returns (uint) {
        return StakeMap[_tokenAddr][_userAddr].amount;
    }
    /**
    * @dev pay out dividends to stakers, update how much per token each staker can claim
    * @param _reward the aggregate amount to be send to all stakers
    * @param _tokenAddr the token that this dividend gets paied out in
    */
    function distribute(uint _reward, address _tokenAddr) isValidToken(_tokenAddr) external returns (bool) {
        require(tokenTotalStaked[_tokenAddr] != 0);
        // require(ERC20(_tokenAddr).approve(address(this), _reward));
        require(ERC20(_tokenAddr).transferFrom(msg.sender, address(this), _reward));
        uint reward = _reward.mul(BIGNUMBER); //simulate floating point operations
        uint rewardAddedPerToken = reward.div(tokenTotalStaked[_tokenAddr]);
        tokenCummRewardPerStake[_tokenAddr] = tokenCummRewardPerStake[_tokenAddr].add(rewardAddedPerToken);
        return true;
    }
    
    
    /**
    * @dev claim dividends for a particular token that user has stake in
    * @param _tokenAddr the token that the claim is made on
    * @param _receiver the address which the claim is paid to
    */
    function claim(address _tokenAddr, address _receiver) isValidToken(_tokenAddr)  public returns (uint) {
        uint depositedAmount = StakeMap[_tokenAddr][_receiver].amount;
        //the amount per token for this user for this claim
        uint amountOwedPerToken = tokenCummRewardPerStake[_tokenAddr].sub(userCummRewardPerStake[_tokenAddr][_receiver]);
        uint claimableAmount = depositedAmount.mul(amountOwedPerToken); //total amoun that can be claimed by this user
        // claimableAmount = claimableAmount.div(DECIMAL); //simulate floating point operations
        claimableAmount = claimableAmount.div(BIGNUMBER); //simulate floating point operations
        userCummRewardPerStake[_tokenAddr][_receiver] = tokenCummRewardPerStake[_tokenAddr];

        return claimableAmount;

    }
    
    /**
    * @dev finalize withdraw of stake
    */
    function withdraw(uint _amount, address _tokenAddr) isValidToken(_tokenAddr)  external returns(bool) {
        require(StakeMap[_tokenAddr][msg.sender].amount >= _amount);
        uint reward = claim(_tokenAddr, msg.sender);
        tokenTotalStaked[_tokenAddr] = tokenTotalStaked[_tokenAddr].sub(_amount);
        StakeMap[_tokenAddr][msg.sender].amount = StakeMap[_tokenAddr][msg.sender].amount.sub(_amount);
        reward = reward.add(_amount);
        require(ERC20(_tokenAddr).transfer(msg.sender, reward));

        return true;
    }
    
}