pragma solidity ^0.4.0;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import './VanityLib.sol';
import './VanityPool.sol';


contract VanityTask is Ownable, VanityLib {

    struct Answer {
        // Fetch from miner
        address miner;
        bytes32 answerPublicXPoint;
        bytes32 answerPublicYPoint;
        bytes32 answerPrivateKey;
        
        // Computed by contract
        bytes32 addressPart;
        uint complexity;
        bool isFinalSolution;
    }
    
    VanityPool pool;
    
    bytes prefix;
    bytes32 requestPublicXPoint;
    bytes32 requestPublicYPoint;
    uint minAllowedLengthOfCommonPrefixForReward;
    uint complexity;
    uint complexitySolved = 0;
    bool foundSolution = false;
    Answer[] answers;
    
    function VanityTask(
        VanityPool poolArg,
        bytes prefixArg,
        bytes32 requestPublicXPointArg,
        bytes32 requestPublicYPointArg)
    {
        requireValidBicoinAddressPrefix(prefixArg);
     
        //address poolArg = address(0x0);
        //bytes memory prefixArg = "1Anton";
        //bytes32 requestPublicXPointArg = hex"141511b7dc6c3b906d88d4f7acbbabdeeec6c7ab32be5eecc1b1e6c9a6e81f09";
        //bytes32 requestPublicYPointArg = hex"2a26d9743e51ac77d5e8739ae507172c68cc57af727b2f57ab6e343765e476cd";
        // hex"611b5ca5f79aefd448f728421e8b3329364fd86458418052e5e1023e74879ec7"
        
        pool = poolArg;
        prefix = prefixArg;
        requestPublicXPoint = requestPublicXPointArg;
        requestPublicYPoint = requestPublicYPointArg;
        minAllowedLengthOfCommonPrefixForReward = prefix.length - 2;
        complexity = complexityForBtcAddressPrefix(prefix);
    }
    
    function kill() onlyOwner() {
        selfdestruct(owner);
        if (pool != address(0x0)) {
            pool.deleteTask(this);
        }
    }
    
    function () payable {
        if (pool != address(0x0)) {
            pool.updateTask();
        }
    }
    
    function redeem(uint amount) onlyOwner() {
        owner.transfer(amount);
        if (pool != address(0x0)) {
            pool.updateTask();
        }
    }
    
    function postAnswerCheck(bytes32 answerPublicXPoint, bytes32 answerPublicYPoint) constant returns(uint) {
        //bytes32 answerPublicXPoint = hex"bef8aa5dc83f75aff0e42f10b923e01e76d2f1d830e1a89dfe8621975a6226fe";
        //bytes32 answerPublicYPoint = hex"6da72eaa3180aef4a0213e5430a6eb11a3b88f04914c7037e4bf1f499b11f8d5";
        //bytes32 answerPrivateKey = bytes32(hex"eaf58f3ebd5ad92c16528b43ac41dadf267e50126568dcdd8a9196d469516659");
        
        var (publicXPoint, publicYPoint) = addXY(
            uint(requestPublicXPoint), 
            uint(requestPublicYPoint), 
            uint(answerPublicXPoint), 
            uint(answerPublicYPoint)
        );
        bytes32 btcAddress = createBtcAddress(publicXPoint, publicYPoint);
        
        uint prefixLength = lengthOfCommonPrefix32(btcAddress, prefix);
        return prefixLength;
    }
    
    function postAnswer(bytes32 answerPublicXPoint, bytes32 answerPublicYPoint, bytes32 answerPrivateKey) returns(bool) {
        
        // Check private key generates exact same public key
        // https://github.com/sontol/secp256k1evm
        // require(TODO!)
        
        var (publicXPoint, publicYPoint) = addXY(
            uint(requestPublicXPoint),
            uint(requestPublicYPoint), 
            uint(answerPublicXPoint), 
            uint(answerPublicYPoint)
        );
        bytes32 btcAddress = createBtcAddress(publicXPoint, publicYPoint);
        uint prefixLength = lengthOfCommonPrefix32(btcAddress, prefix);
        require(prefixLength >= minAllowedLengthOfCommonPrefixForReward);
        
        Answer memory answer = Answer(
            msg.sender, 
            answerPublicXPoint, 
            answerPublicYPoint, 
            answerPrivateKey, 
            btcAddress,
            complexityForBtcAddressPrefixWithLength(prefix, prefixLength),
            false
        );

        if (prefixLength == prefix.length) {
            // Final answer
            answer.isFinalSolution = true;
            foundSolution = true;
        } else if (prefixLength >= minAllowedLengthOfCommonPrefixForReward) {
            // Good answer
            answer.isFinalSolution = false;
        } else {
            // Wrong answer
            revert();
        }
        
        answers.push(answer);
        uint amount = this.balance * answer.complexity / (complexity - complexitySolved);
        if (amount > this.balance) {
            amount = this.balance;
        }
        uint fee = 0;
        if (pool != address(0x0)) {
            fee = amount / 100;
            amount -= fee;
        }
        msg.sender.transfer(amount);    // TODO: Danger! Handle recursive call!
        complexitySolved += answer.complexity;
        if (pool != address(0x0)) {
            pool.updateTask();
            pool.transfer(fee);
        }
        
        return true;
    }
}


// contract BitValid {
	
// 	bytes32 constant mask4 = 0xffffffff00000000000000000000000000000000000000000000000000000000;
// 	bytes1 constant networkConst = 0x00;

// 	function getBitcoinAddress(
// 			bytes32 _xPoint,
// 			bytes32 _yPoint)
// 			constant
// 			returns(
// 				bytes20 hashedPubKey,
// 				bytes4 checkSum,
// 				bytes1 network)
// 	{
// 		hashedPubKey = getHashedPublicKey(_xPoint, _yPoint);
//  		checkSum = getCheckSum(hashedPubKey, networkConst);
//  		network = networkConst;
// 	}

// 	function getHashedPublicKey(
// 			bytes32 _xPoint,
// 			bytes32 _yPoint)
// 			constant
// 			returns(
// 			    bytes20 hashedPubKey)
// 	{
// 		uint8 startingByte = 0x04;
//  		return ripemd160(sha256(startingByte, _xPoint, _yPoint));
// 	}

// 	function getCheckSum(
// 			bytes20 _hashedPubKey,
// 			bytes1 network)
// 			constant
// 			returns(
// 			    bytes4 checkSum)
// 	{
// 		var full = sha256((sha256(network, _hashedPubKey)));
// 		return bytes4(full & mask4);
// 	}
// }