pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol";

contract FairSwap{
    using SafeMath for uint256;
    uint8 private contractStatus;
    uint8 private playerStatus;
    uint8 private AAllowance;
    uint8 private BAllowance;
    address private playerA;
    address private playerB;
    uint256 private AAmount;
    uint256 private BAmount;
    address private AContractAddr;
    address private BContractAddr;
    uint256 private commitStart;
    uint256 constant private commitGap = 60;
    uint256 private transferStart;
    uint256 constant private transferGap = 60;
    uint256 constant private BAnnounceGap = 60;
    uint256 constant private AAnnounceGap = 60;
    uint256 private claimStart;
    Moireum AContract;
    Moireum BContract;
    constructor () public{ }
    function commit(address counterpart, uint256 myamount, uint256 hisamount,
    address mycontractaddr, address hiscontractaddr) public payable{
        require(msg.value == 1 ether && contractStatus == 0 && msg.sender != counterpart);
        if(playerStatus == 0){
        commitStart = now;
        playerStatus = 1; // one commit
        playerA = msg.sender;
        playerB = counterpart;
        AAmount = myamount;
        BAmount = hisamount;
        AContractAddr = mycontractaddr;
        BContractAddr = hiscontractaddr;
    } else if(playerStatus == 1){
        require( now < commitStart.add(commitGap) && playerA == counterpart
        && playerB == msg.sender && AAmount == hisamount && BAmount == myamount
        && AContractAddr == hiscontractaddr && BContractAddr == mycontractaddr);
        contractStatus = 1;
        playerStatus = 0; // reset nothing for contract status 1
        transferStart = now;
        AContract = Moireum(AContractAddr);
        BContract = Moireum(BContractAddr);
        delete commitStart;
    } // first commit more gas. approxi commit 1 should be announce 1. and 2 be 2.
}
function announce() public{ // dont care about token stuck
    require(contractStatus == 1 && now > transferStart.add(transferGap));
    contractStatus = 2; // outcome can be determined, can withdraw
    claimStart = now;
    if(msg.sender == playerB){
        require(now < transferStart.add(transferGap.add(BAnnounceGap))
        && BContract.getBalance() >= BAmount);
        // B announce scenario:
        if(AContract.getBalance() >= AAmount){
            // FairSwap
            AAllowance = 1;
            BAllowance = 1;
            AContract.transfer(playerB, AAmount);
            BContract.transfer(playerA, BAmount);
        } else{ //(AContract.getBalance() < AAmount)
            // A dishonest, B can pull 2, B token back
            BAllowance = 2;
            BContract.transfer(playerB, BAmount);
        }
    } else if(msg.sender == playerA){
        require(now > transferStart.add(transferGap.add(BAnnounceGap))
        && now < transferStart.add(transferGap.add(BAnnounceGap.add(AAnnounceGap)))
        && AContract.getBalance() >= AAmount);
        // A announce scenario: (meaning that B didnt announce)
        if(BContract.getBalance() < BAmount){
            // B dishonest, A can pull 2, A token back
            AAllowance = 2;
            AContract.transfer(playerA, AAmount);
        } else{ //(BContract.getBalance() >= BAmount)
            // FairSwap, yet A can pull 2 (since that B cheat on gas fee)
            AAllowance = 2;
            AContract.transfer(playerB, AAmount);
            BContract.transfer(playerA, BAmount);
}
} else{
revert(); }
    delete transferStart;
}

function claim() public{
        // anyone can call claim
        // if(contractStatus == 0 && playerStatus == 0){ nothing }
        if(contractStatus == 0 && playerStatus == 1 && now > commitStart.add(commitGap)){
            // A commit, B not commit, past commit gap, A can withdraw, reset status
            contractStatus = 10;
            address(uint160(playerA)).transfer(1 ether);
            resetContract();
        }
        // if(contractStatus == 1 && playerStatus == 0){ both committed, shouldnt withdraw }
        if(contractStatus == 1 && now > claimStart){
            // no one announce scenario:
            contractStatus = 10; // change status instead of using local variables
            if((AContract.getBalance() >= AAmount && BContract.getBalance() >= BAmount)){
                AContract.transfer(playerA, AAmount);
                BContract.transfer(playerB, BAmount);
            } else if(AContract.getBalance() < AAmount && BContract.getBalance() < BAmount){
            } else if(AContract.getBalance() >= AAmount){
                AContract.transfer(playerA, AAmount);
            } else{
                BContract.transfer(playerB, BAmount);
            }
            address(uint160(playerA)).transfer(1 ether);
            address(uint160(playerB)).transfer(1 ether);
            resetContract();
        }
        if(contractStatus == 2 && now > claimStart){
            // after announcement claim
            contractStatus = 10;
            address(uint160(playerA)).transfer(AAllowance * 1 ether);
            address(uint160(playerB)).transfer(BAllowance * 1 ether);
            resetContract();
} }
    function resetContract() private{
        delete playerA;
        delete playerB;
        delete contractStatus;
        delete playerStatus;
        delete AAllowance;
        delete BAllowance;
        delete AAmount;
        delete BAmount;
        delete AContractAddr;
        delete BContractAddr;
        delete commitStart;
        delete transferStart;
        delete claimStart;
}
    function getTime() view public returns(uint256 timenow){
        timenow = now;
} }
