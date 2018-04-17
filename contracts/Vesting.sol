pragma solidity ^0.4.18;

import "./ERC20.sol";
import "./SafeMath.sol";

contract Vesting {
    using SafeMath for uint256;
    
    address public creator;
    address public owner;
    uint256 public firstUnlockDate;
    uint256 public secondUnlockDate;
    uint256 public thirdUnlockDate;
    uint256 public fourthUnlockDate;
    uint256 public fifthUnlockDate;
    uint256 public createdAt;
    uint256 private withdrawBalance;

    enum Phase {
        Created,
        FirstTime,
        SecondTime,
        ThirdTime,
        FourthTime
    }

    Phase public currentPhase = Phase.Created;
    event LogPhaseSwitch(Phase phase);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function Vesting(
        address _creator,
        address _owner,
        uint256 _firstUnlockDate,
        uint256 _secondUnlockDate,
        uint256 _thirdUnlockDate,
        uint256 _fourthUnlockDate
    ) public {
        creator = _creator;
        owner = _owner;
        firstUnlockDate = _firstUnlockDate;
        secondUnlockDate = _secondUnlockDate;
        thirdUnlockDate = _thirdUnlockDate;
        fourthUnlockDate = _fourthUnlockDate;
        createdAt = now;
    }

    // keep all the ether sent to this address
    function() payable public { 
        Received(msg.sender, msg.value);
    }

    // callable by owner only, after specified time
    function withdraw() onlyOwner public {
       //require(now >= firstUnlockDate);
       //now send all the balance
       msg.sender.transfer(this.balance);
       Withdrew(msg.sender, this.balance);
    }

    // callable by owner only, after specified time, only for Tokens implementing ERC20
    function withdrawTokens(address _tokenContract) onlyOwner public {
        ERC20 token = ERC20(_tokenContract);
        //now send all the token balance
        uint256 tokenBalance = token.balanceOf(this);

        if (now >= fifthUnlockDate && currentPhase == Phase.FourthTime) {
            withdrawBalance = tokenBalance;
        } else if (now >= fourthUnlockDate && currentPhase == Phase.ThirdTime) {
            withdrawBalance = tokenBalance.div(2);
            setSalePhase(Phase.FourthTime);
        } else if (now >= thirdUnlockDate && currentPhase == Phase.SecondTime) {
            withdrawBalance = tokenBalance.div(3);
            setSalePhase(Phase.ThirdTime);
        } else if (now >= secondUnlockDate && currentPhase == Phase.FirstTime) {
            withdrawBalance = tokenBalance.div(4);
            setSalePhase(Phase.SecondTime);
        } else if (now >= firstUnlockDate && currentPhase == Phase.Created) {
            withdrawBalance = tokenBalance.div(5);
            setSalePhase(Phase.FirstTime);
        }

        token.transfer(owner, withdrawBalance);
        WithdrewTokens(_tokenContract, msg.sender, withdrawBalance);
    }

    function info() public view returns(address, address, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (
            creator,
            owner,
            firstUnlockDate,
            secondUnlockDate,
            thirdUnlockDate,
            fourthUnlockDate,
            fifthUnlockDate,
            createdAt,
            this.balance
        );
    }

    function getBalance(address _tokenContract) view returns (uint) {
        ERC20 token = ERC20(_tokenContract);

        uint256 tokenBalance = token.balanceOf(this);
        return tokenBalance;
    }

    function setSalePhase(Phase _nextPhase) internal {
        bool canSwitchPhase
        =  (currentPhase == Phase.Created && _nextPhase == Phase.FirstTime)
        || (currentPhase == Phase.FirstTime && _nextPhase == Phase.SecondTime)
        || (currentPhase == Phase.SecondTime && _nextPhase == Phase.ThirdTime)
        || (currentPhase == Phase.ThirdTime && _nextPhase == Phase.FourthTime);

        require(canSwitchPhase);
        currentPhase = _nextPhase;
        LogPhaseSwitch(_nextPhase);
    }

    // Constant functions
    function getCurrentPhase() public view returns (string CurrentPhase) {
        if (currentPhase == Phase.Created) {
            return "Patience young padawan, wait until your payday!";
        } else if (currentPhase == Phase.FirstTime) {
            return "First Vesting Round Was Paid";
        } else if (currentPhase == Phase.SecondTime) {
            return "Second Vesting Round Was Paid";
        } else if (currentPhase == Phase.ThirdTime) {
            return "Third Vesting Round Was Paid";
        } else if (currentPhase == Phase.FourthTime) {
            return "Fourth Vesting Round Was Paid";
        }

    }

    event Received(address from, uint256 amount);
    event Withdrew(address to, uint256 amount);
    event WithdrewTokens(address tokenContract, address to, uint256 amount);
}
