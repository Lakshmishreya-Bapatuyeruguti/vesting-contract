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
    address owner;
    IERC20 public token;

    constructor(IERC20 _token,uint _cliff,uint _duration,uint _slicePeriod){
        token=_token;
        duration=_duration;
        cliff=_cliff;
        slicePeriod=_slicePeriod;
        startTime=block.timestamp;
        owner=msg.sender;

    }
// Events
    event AddBeneficiaryEvent (address beneficiary, string  message);
    event LockTokensEvent(address beneficiary, string  message);
    event ReleaseTokensEvent(address beneficiary, string message);

// Modifiers
    modifier cliffPeriodOver(){
        _;
        require(block.timestamp>=cliff,"Wait Till Cliff period");
    }
    modifier isBeneficiaryOrContractOwner(address _beneficiary){
        _;
        require(beneficiaries[_beneficiary]>0 || msg.sender==owner,"Only Beneficiary Or Owner can Release Tokens");
    }
    modifier onlyOwner(){
        _;
        require(msg.sender==owner," Only Owner can Add benefeiciaries");
    }

// Adding Beneficiaries
    function addBeneficiary(address _beneficiary,uint tokensToLock) onlyOwner public {
        beneficiaries[_beneficiary]=tokensToLock;
        emit AddBeneficiaryEvent(_beneficiary, "New Beneficiary Added");
    }

// Locking Tokens
    function lockTokens(address _beneficiary,uint tokensAmount)  public {
        beneficiaries[_beneficiary]=tokensAmount;
        totalTokens[_beneficiary]=beneficiaries[_beneficiary];
        token.transfer(address(this),tokensAmount);
        emit LockTokensEvent(_beneficiary, "Tokens are Locked in smart contract ");
    }

// Calculate no. of eligible tokens to release
    function releasableTokens(address _beneficiary) public view cliffPeriodOver returns(uint) {
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

// Release Tokens to beneficiary
    function releaseTokens(address _beneficiary) isBeneficiaryOrContractOwner(_beneficiary) public { 
       uint tokensClaimed=releasableTokens(_beneficiary);
       require(tokensClaimed<=beneficiaries[_beneficiary],"Tokens Claiming are greater than tokens locked");
       releasedTokens[_beneficiary]=tokensClaimed;
       token.transfer(_beneficiary,tokensClaimed);
       emit ReleaseTokensEvent(_beneficiary, "Tokens are Released in account of beneficiary ");
    }

}