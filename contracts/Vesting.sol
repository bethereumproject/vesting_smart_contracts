pragma solidity ^0.4.18;

/**************************************************/
/*IN DEVELOPMENT PHASE, DO NOT USE ON MAIN NETWORK*/
/**************************************************/

//import "../node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol";
//import "../node_modules/zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "./SafeMath.sol";
import "./ERC20.sol";//FOR DEV PURPOSE

contract Vesting {
    using SafeMath for uint256;
    //using SafeERC20 for ERC20Basic;
    
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
        uint256 _fourthUnlockDate,
        uint256 _fifthUnlockDate
    ) public {
        creator = _creator;
        owner = _owner;
        firstUnlockDate = _firstUnlockDate;
        secondUnlockDate = _secondUnlockDate;
        thirdUnlockDate = _thirdUnlockDate;
        fourthUnlockDate = _fourthUnlockDate;
        fifthUnlockDate = _fifthUnlockDate;
        createdAt = now;
    }

    // keep all the ether sent to this address
    function() payable public { 
        Received(msg.sender, msg.value);
    }

    // callable by owner only
    function withdraw() onlyOwner public {
       msg.sender.transfer(this.balance);
       Withdrew(msg.sender, this.balance);
    }

    // callable by owner only, after specified time, only for Tokens implementing ERC20
    function withdrawTokens(ERC20 token) onlyOwner public {
        uint256 tokenBalance = token.balanceOf(this);

        if (now >= fifthUnlockDate) {
            withdrawBalance = tokenBalance;
        } else if (now >= fourthUnlockDate && currentPhase == Phase.ThirdTime) {
            withdrawBalance = tokenBalance.div(2);
            setVestingPhase(Phase.FourthTime);
        } else if (now >= thirdUnlockDate && currentPhase == Phase.SecondTime) {
            withdrawBalance = tokenBalance.div(3);
            setVestingPhase(Phase.ThirdTime);
        } else if (now >= secondUnlockDate && currentPhase == Phase.FirstTime) {
            withdrawBalance = tokenBalance.div(4);
            setVestingPhase(Phase.SecondTime);
        } else if (now >= firstUnlockDate && currentPhase == Phase.Created) {
            withdrawBalance = tokenBalance.div(5);
            setVestingPhase(Phase.FirstTime);
        }

        token.transfer(owner, withdrawBalance);
        WithdrewTokens(token, msg.sender, withdrawBalance);
    }

    function info() public view returns(address, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
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

    function getBalance(ERC20 token) view returns (uint256) {
        uint256 tokenBalance = token.balanceOf(this);
        return tokenBalance;
    }

    function setVestingPhase(Phase _nextPhase) internal {
        bool canSwitchPhase
        =  (currentPhase == Phase.Created && _nextPhase == Phase.FirstTime)
        || (currentPhase == Phase.FirstTime && _nextPhase == Phase.SecondTime)
        || (currentPhase == Phase.SecondTime && _nextPhase == Phase.ThirdTime)
        || (currentPhase == Phase.ThirdTime && _nextPhase == Phase.FourthTime);

        require(canSwitchPhase);
        currentPhase = _nextPhase;
        LogPhaseSwitch(_nextPhase);
    }

    /*
    function getCurrentVestingPhase() public constant returns (string CurrentPhase) {
        if (now >= fifthUnlockDate) {
            return "You are able to withdraw your tokens";
        } else if (now >= fourthUnlockDate) {
            if (currentPhase == Phase.FourthTime) {
                return "You already got paid for your fourth round, wait until your payday";
            }
            return "You are able to withdraw";
        } else if (now >= thirdUnlockDate) {
            if (currentPhase == Phase.ThirdTime) {
                return "You already got paid for your third round, wait until your payday";
            }
            return "You are able to withdraw";
        } else if (now >= secondUnlockDate) {
            if (currentPhase == Phase.SecondTime) {
                return "You already got paid for your second round, wait until your payday";
            }
            return "You are able to withdraw";
        } else if (now >= firstUnlockDate) {
            if (currentPhase == Phase.FirstTime) {
                return "You already get paid for your first round, wait until your payday";
            }
            return "You are able to withdraw your first round";
        } else if (now < firstUnlockDate) {
            return "Patience young padawan, wait until your payday!";
        }
    }
    */

    event Received(address from, uint256 amount);
    event Withdrew(address to, uint256 amount);
    event WithdrewTokens(ERC20 token, address to, uint256 amount);
}
