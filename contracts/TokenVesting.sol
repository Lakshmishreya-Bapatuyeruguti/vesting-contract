// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenVesting{
    uint public duration;
    uint public cliff;
    uint public slicePeriod;
    uint public startTime;
    mapping (address=>uint)beneficiaries;
    mapping(address => uint256) public totalTokens;
    mapping(address => uint256) public releasedTokens;
    IERC20 public token;

    constructor(IERC20 _token,uint _cliff,uint _duration,uint _slicePeriod){
        token=_token;
        duration=_duration;
        cliff=_cliff;
        slicePeriod=_slicePeriod;
        startTime=block.timestamp;

    }
    function lockTokens(address _beneficiary,uint tokensAmount)public {
        beneficiaries[_beneficiary]=tokensAmount;
        token.transfer(address(this),tokensAmount);
        totalTokens[_beneficiary]=beneficiaries[_beneficiary];
    }
    function releasableTokens(address _beneficiary) public view returns(uint){
    
        if(block.timestamp<cliff){
        return 0;
    }
    else {
        uint timeSinceStart = block.timestamp - startTime;
        uint noOfPeriodsSinceStart = timeSinceStart / slicePeriod;
        uint totalPeriods = duration / slicePeriod;
        if (noOfPeriodsSinceStart >= totalPeriods) {
            return beneficiaries[_beneficiary];
        } 
        else {
            uint tokensVestedInOnePeriod = beneficiaries[_beneficiary] / totalPeriods;
            uint tokensToBeVested = tokensVestedInOnePeriod * noOfPeriodsSinceStart;
            return tokensToBeVested;
        }
    }
    }
    function releaseTokens(address _beneficiary) public { 
       uint tokensClaimed=releasableTokens(_beneficiary);
       token.transfer(_beneficiary,tokensClaimed);
       releasedTokens[_beneficiary]=tokensClaimed;
    }

}