// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract TokenVesting{

    struct VestingInfo{
        uint vestingId;
        uint startTime;
        uint duration;
        uint cliff;
        uint slicePeriod;
        uint tokensAmount;
        uint releasedTokens;
    }
    struct BeneficiaryInfo{
        uint id;
        mapping(IERC20 => VestingInfo[]) vestingSchedules;
    }
    mapping (address => BeneficiaryInfo) public beneficiaries;

    // Events
    event LockTokensEvent(address beneficiary, string  message);
    event ReleaseTokensEvent(address beneficiary, uint amountReleased, string message);

    // Modifiers
    modifier cliffPeriodOver(address _beneficiary, IERC20 _token, uint _id){
        require(block.timestamp >= beneficiaries[_beneficiary].vestingSchedules[_token][_id].cliff, "Wait Till Cliff period");
         _;
    }
    modifier isBeneficiary(address _beneficiary){
        require( msg.sender==_beneficiary,"Only Beneficiary can Lock and Release Tokens");
         _;
    }

    // Locking Tokens of beneficiary
    function lockTokens(address _beneficiaryAddress,uint _tokensAmount,uint _cliff,uint _duration,uint _slicePeriod,IERC20 _token) isBeneficiary(_beneficiaryAddress) public {
        require(_slicePeriod<=_duration &&_cliff<=_duration,"Slice period & cliff should be < Duration");
        require(_tokensAmount>0,"Tokens to vest should be > 0");
        VestingInfo[] storage vestingsOfToken = beneficiaries[_beneficiaryAddress].vestingSchedules[_token];
        VestingInfo memory currentVesting= VestingInfo({
            vestingId: vestingsOfToken.length,
            startTime: block.timestamp,
            duration: _duration,
            cliff:block.timestamp+ _cliff,
            slicePeriod: _slicePeriod,
            tokensAmount: _tokensAmount,
            releasedTokens: 0
        });
        vestingsOfToken.push(currentVesting);
        _token.transferFrom(msg.sender, address(this), _tokensAmount);
        emit LockTokensEvent(_beneficiaryAddress, "Tokens are Locked in smart contract ");
    }
      // Get Details of particular vesting of beneficiary
      function getVestingDetails(address _beneficiaryAddress, IERC20 _token , uint _id )public view returns(VestingInfo memory){
          return beneficiaries[_beneficiaryAddress].vestingSchedules[_token][_id];
      }

    // Calculate no. of eligible tokens to release
    function releasableTokens(address _beneficiary,IERC20 _token,uint _id) internal view  returns(uint) {
        VestingInfo memory vestingInstance =  beneficiaries[_beneficiary].vestingSchedules[_token][_id];
        uint timeSinceStart = block.timestamp - vestingInstance.startTime;
        uint noOfPeriodsSinceStart = timeSinceStart/vestingInstance.slicePeriod;
        uint totalPeriods =vestingInstance.duration /vestingInstance.slicePeriod;
        uint releasedTokens=vestingInstance.releasedTokens;
        uint totalTokenAmount=vestingInstance.tokensAmount;
        if (noOfPeriodsSinceStart >= totalPeriods ) {
            return totalTokenAmount-releasedTokens;
        } 
        else {
            uint tokensReleasedInOnePeriod =totalTokenAmount/ totalPeriods;
            uint tokensToBeReleased = tokensReleasedInOnePeriod * noOfPeriodsSinceStart;
            tokensToBeReleased=tokensToBeReleased-releasedTokens;
            return tokensToBeReleased;
        }
    }
    
    // Release  tokens to beneficiary
    function releaseTokens(address _beneficiary, IERC20 _token,uint _id ,uint _claimAmount) isBeneficiary(_beneficiary) cliffPeriodOver(_beneficiary,_token,_id) public {
        uint tokensToBeReleased = releasableTokens(_beneficiary, _token, _id);
        require(tokensToBeReleased > 0, "No tokens for release");
        require(_claimAmount<=tokensToBeReleased,"Claim Amount > Releasable tokens");
        VestingInfo  storage vestingInstance =  beneficiaries[_beneficiary].vestingSchedules[_token][_id];
        vestingInstance.releasedTokens += _claimAmount;
        _token.transfer(_beneficiary, _claimAmount); 
        emit ReleaseTokensEvent(_beneficiary, _claimAmount,"Tokens released to beneficiary");
    }

    }