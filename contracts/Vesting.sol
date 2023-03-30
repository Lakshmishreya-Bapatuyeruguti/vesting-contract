// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract Vesting{
    // address[] public beneficiaries ;
    // uint public amountOfVestingTokens;
    uint public slicePeriod;
    uint public cliff;
    uint public duration;
    uint public tokensReleased;
    uint public startTime;
    address owner;
    mapping(address=>uint) beneficiaries;
    mapping(address=>uint) noOfvestedTokens;
    IERC20 public token;
    constructor(address[] memory _beneficiaries, uint _slicePeriod,uint _cliff, uint _duration,address _token ,uint _startTime){  
        slicePeriod=_slicePeriod;
        cliff=_startTime+_cliff;
        duration=_duration;
        token=IERC20(_token);
        owner=msg.sender;
        startTime=_startTime;
     
        require(_beneficiaries.length>0,"No Beneficiaries provided");
    }

    modifier isOwner(){
        _;
        require(owner==msg.sender,"Only owner allowed");
    }
    modifier isOneOfBeneficiary(){
        _;
        require(beneficiaries[msg.sender]>=0,"Only benificiary with tokens can lock Tokens");
    }
    modifier cliffPeriodDone(){
         _;
        require(block.timestamp>=cliff," Wait till cliff period");
    }
   function addBeneificiary(address _newBeneficiary,uint _tokensToLock) public isOwner{
    beneficiaries[_newBeneficiary]=_tokensToLock;
   }
   function showTokenOfBeneficiary(address _beneficiary) public view returns (uint){
       return beneficiaries[_beneficiary];
   }

function release(address _beneficiary) public payable {
    uint amount = vestingTokens(_beneficiary);
    require(amount >0 , "No tokens to release");

    // require(token.balanceOf(address(this)) >= amount, "Insufficient balance in vesting contract");

    noOfvestedTokens[_beneficiary] += amount;
    tokensReleased += amount;
    token.approve(msg.sender, amount);
    token.transferFrom(_beneficiary, _beneficiary, amount);
}

function vestingTokens(address beneficiary) public view returns (uint) {
    if(block.timestamp<cliff){
        return 0;
    }
    else {
        uint timeSinceStart = block.timestamp - startTime;
        uint noOfPeriodsSinceStart = timeSinceStart / slicePeriod;
        uint totalPeriods = duration / slicePeriod;
        if (noOfPeriodsSinceStart >= totalPeriods) {
            return beneficiaries[beneficiary];
        } 
        else {
            uint tokensVestedInOnePeriod = beneficiaries[beneficiary] / totalPeriods;
            uint tokensToBeVested = tokensVestedInOnePeriod * noOfPeriodsSinceStart;
            return tokensToBeVested;
        }
    }
}


function getContractBalance() public view returns (uint) {
    return address(this).balance;
}
}
