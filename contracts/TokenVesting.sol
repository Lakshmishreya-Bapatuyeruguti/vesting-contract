// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenVesting{

    mapping (address=>uint) public duration;
    mapping (address=>uint) public cliff;
    mapping (address=>uint) public slicePeriod;
    mapping (address=>uint) public startTime;
    mapping (address=>uint)public beneficiaries;
    mapping(address => uint256) public totalTokens;
    mapping(address => uint256) public releasedTokens;
    address owner;
    IERC20 public token;

    constructor(IERC20 _token){
        token=_token;
        owner=msg.sender;

    }
// Events
    event AddBeneficiaryEvent (address beneficiary, string  message);
    event LockTokensEvent(address beneficiary, string  message);
    event ReleaseTokensEvent(address beneficiary, string message);

// Modifiers
    modifier cliffPeriodOver(address _beneficiary){
        _;
        require(block.timestamp>=cliff[_beneficiary],"Wait Till Cliff period");
    }
    modifier isBeneficiaryOrContractOwner(address _beneficiary){
        _;
        require(beneficiaries[_beneficiary]>0 || msg.sender==owner,"Only Beneficiary Or Owner can Lock and Release Tokens");
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
    function lockTokens(address _beneficiary,uint tokensAmount,uint _cliff,uint _duration,uint _slicePeriod) isBeneficiaryOrContractOwner(_beneficiary) public {
        duration[_beneficiary]=_duration;
        cliff[_beneficiary]=_cliff;
        slicePeriod[_beneficiary]=_slicePeriod;
        startTime[_beneficiary]=block.timestamp;
        beneficiaries[_beneficiary]=tokensAmount;
        totalTokens[_beneficiary]=beneficiaries[_beneficiary];
        token.transferFrom(msg.sender,address(this),tokensAmount);
        emit LockTokensEvent(_beneficiary, "Tokens are Locked in smart contract ");
    }

// Calculate no. of eligible tokens to release
    function releasableTokens(address _beneficiary) public cliffPeriodOver(_beneficiary) view returns(uint) {
        uint timeSinceStart = block.timestamp - startTime[_beneficiary];
        uint noOfPeriodsSinceStart = timeSinceStart / slicePeriod[_beneficiary];
        uint totalPeriods = duration[_beneficiary] / slicePeriod[_beneficiary];
        if (noOfPeriodsSinceStart >= totalPeriods ) {
            
            return beneficiaries[_beneficiary] -releasedTokens[_beneficiary];
        } 
        else {
            uint tokensVestedInOnePeriod = beneficiaries[_beneficiary] / totalPeriods;
            uint tokensToBeVested = tokensVestedInOnePeriod * noOfPeriodsSinceStart;
            tokensToBeVested=tokensToBeVested-releasedTokens[_beneficiary];
            return tokensToBeVested;
        }
    }

// Release Tokens to beneficiary
    function releaseTokens(address _beneficiary) isBeneficiaryOrContractOwner(_beneficiary) public { 
       uint tokensClaimed=releasableTokens(_beneficiary);
       require(tokensClaimed<=beneficiaries[_beneficiary],"Tokens Claiming are greater than tokens locked");
       require(tokensClaimed>0,"Already Claimed");
       releasedTokens[_beneficiary]+=tokensClaimed;
       token.transfer(_beneficiary,tokensClaimed);
       emit ReleaseTokensEvent(_beneficiary, "Tokens are Released in account of beneficiary ");
    }
}