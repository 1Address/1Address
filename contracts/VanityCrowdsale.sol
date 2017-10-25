pragma solidity ^0.4.11;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./VanityToken.sol";


contract VanityCrowdsale is Ownable {

    // Constants

    uint256 public constant TOKEN_RATE = 1000; // 1 ETH = 1000 VPL
    uint256 public constant OWNER_TOKENS_PERCENT = 100; // 1:1

    // Variables

    uint256 public startTime;
    uint256 public endTime;
    address public ownerWallet;
    
    mapping(address => bool) public registered;
    address[] public participants;
    
    VanityToken public token;
    bool public finalized;
    bool public distributed;
    uint256 public distributedCount;
    uint256 public distributedTokens;
    
    // Events

    event Finalized();
    event Distributed();

    // Constructor and setters

    function VanityCrowdsale(uint256 _startTime, uint256 _endTime, address _ownerWallet) public {
        startTime = _startTime;
        endTime = _endTime;
        ownerWallet = _ownerWallet;

        token = new VanityToken();
        token.pause();
    }

    function participantsCount() public constant returns(uint) {
        return participants.length;
    }

    function setOwnerWallet(address _ownerWallet) public onlyOwner {
        require(_ownerWallet != address(0));
        ownerWallet = _ownerWallet;
    }

    // Participants methods

    function () public payable {
        registerParticipant();
    }

    function registerParticipant() public payable {
        require(!finalized);
        require(startTime <= now && now <= endTime);
        require(!registered[msg.sender]);

        registered[msg.sender] = true;
        participants.push(msg.sender);
        if (msg.value > 0) {
            // No money => No need to handle recirsive calls
            msg.sender.transfer(msg.value);
        }
    }

    // Owner methods

    function finalize() public onlyOwner {
        require(!finalized);
        require(now > endTime);

        finalized = true;
        Finalized();
    }

    function distribute(uint count) public onlyOwner {
        require(count > 0 && distributedCount + count <= participants.length);
        require(finalized && !distributed);

        for (uint i = 0; i < count; i++) {
            address participant = participants[distributedCount + i];
            require(registered[participant]);
            delete registered[participant];

            uint256 tokens = participant.balance * TOKEN_RATE;
            token.mint(participant, tokens);
            distributedTokens += tokens;
        }
        distributedCount += count;

        if (distributedCount == participants.length) {
            uint256 ownerTokens = distributedTokens * OWNER_TOKENS_PERCENT / 100;
            token.mint(ownerWallet, ownerTokens);
            token.finishMinting();
            token.unpause();
            distributed = true;
            Distributed();
        }
    }

}