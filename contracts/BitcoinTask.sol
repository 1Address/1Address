pragma solidity ^0.4.0;

import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import './VanityLib.sol';
import './TaskRegister.sol';


contract BitcoinTask is Ownable, VanityLib {
    
    bytes constant version = "1.0";

    ERC20 public token;
    bytes public prefix;
    TaskRegister public pool;
    uint256 public requestPublicXPoint;
    uint256 public requestPublicYPoint;
    uint256 public answerPrivateKey;
    
    function BitcoinTask(
        ERC20 tokenArg,
        TaskRegister poolArg,
        bytes prefixArg,
        uint256 requestPublicXPointArg,
        uint256 requestPublicYPointArg) public
    {
        requireValidBicoinAddressPrefix(prefixArg);
     
        //address poolArg = address(0x0);
        //bytes memory prefixArg = "1Anton";
        //bytes32 requestPublicXPointArg = hex"141511b7dc6c3b906d88d4f7acbbabdeeec6c7ab32be5eecc1b1e6c9a6e81f09";
        //bytes32 requestPublicYPointArg = hex"2a26d9743e51ac77d5e8739ae507172c68cc57af727b2f57ab6e343765e476cd";
        // hex"611b5ca5f79aefd448f728421e8b3329364fd86458418052e5e1023e74879ec7"
        
        pool = poolArg;
        token = tokenArg;
        prefix = prefixArg;
        requestPublicXPoint = requestPublicXPointArg;
        requestPublicYPoint = requestPublicYPointArg;
    }
    
    // function postAnswerCheck(bytes32 answerPrivateKey) public constant returns(uint) {
    //     //bytes32 answerPublicXPoint = hex"bef8aa5dc83f75aff0e42f10b923e01e76d2f1d830e1a89dfe8621975a6226fe";
    //     //bytes32 answerPublicYPoint = hex"6da72eaa3180aef4a0213e5430a6eb11a3b88f04914c7037e4bf1f499b11f8d5";
    //     //bytes32 answerPrivateKey = bytes32(hex"eaf58f3ebd5ad92c16528b43ac41dadf267e50126568dcdd8a9196d469516659");
    //     (answerPublicXPoint,answerPublicYPoint) = bitcoinPublicKey(answerPrivateKey);

    //     var (publicXPoint, publicYPoint) = addXY(
    //         uint(requestPublicXPoint), 
    //         uint(requestPublicYPoint), 
    //         uint(answerPublicXPoint), 
    //         uint(answerPublicYPoint)
    //     );
    //     bytes32 btcAddress = createBtcAddress(publicXPoint, publicYPoint);
        
    //     uint prefixLength = lengthOfCommonPrefix32(btcAddress, prefix);
    //     return prefixLength;
    // }
    
    function postAnswer(uint256 _answerPrivateKey) public returns(bool) {
        var (answerPublicXPoint,answerPublicYPoint) = bitcoinPublicKey(_answerPrivateKey);
        
        var (publicXPoint, publicYPoint) = addXY(
            uint(requestPublicXPoint),
            uint(requestPublicYPoint), 
            uint(answerPublicXPoint), 
            uint(answerPublicYPoint)
        );
        bytes32 btcAddress = createBtcAddress(publicXPoint, publicYPoint);
        uint prefixLength = lengthOfCommonPrefix32(btcAddress, prefix);
        require(prefixLength == prefix.length);
        
        answerPrivateKey = _answerPrivateKey;
        token.transfer(msg.sender, token.balanceOf(this));
        //pool.completeBitcoinTask(this);
        
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