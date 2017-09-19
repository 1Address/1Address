pragma solidity ^0.4.0;

import './VanityTask.sol';


library VanityLib {

    function lengthOfCommonPrefix(bytes a, bytes b) constant returns(uint) {
        uint len = (a.length <= b.length) ? a.length : b.length;
        for (uint i = 0; i < len; i++) {
            if (a[i] != b[i]) {
                return i;
            }
        }
        return len;
    }
    
    function lengthOfCommonPrefix32(bytes32 a, bytes b) constant returns(uint) {
        for (uint i = 0; i < b.length; i++) {
            if (a[i] != b[i]) {
                return i;
            }
        }
        return b.length;
    }
    
    function equalBytesToBytes(bytes a, bytes b) constant returns (bool) {
        if (a.length != b.length) {
            return false;
        }
        for (uint i = 0; i < a.length; i++) {
            if (a[i] != b[i]) {
                return false;
            }
        }
        return true;
    }
    
    function equalBytes32ToBytes(bytes32 a, bytes b) constant returns (bool) {
        for (uint i = 0; i < b.length; i++) {
            if (a[i] != b[i]) {
                return false;
            }
        }
        return true;
    }
    
    function bytesToBytes32(bytes source) constant returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    /* Converts given number to base58, limited by 32 symbols */
    function toBase58Checked(uint256 _value, byte appCode) constant returns (bytes32) {
        string memory letters = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
        bytes memory alphabet = bytes(letters);
        uint8 base = 58;
        uint8 len = 0;
        uint256 remainder = 0;
        bool needBreak = false;
        bytes memory bytesReversed = bytes(new string(32));
        
        for (uint8 i = 0; true; i++) {
            if (_value < base) {
                needBreak = true;
            }
            remainder = _value % base;
            _value = uint256(_value / base);
            if (len == 32) {
                for (uint j = 0; j < len - 1; j++) {
                    bytesReversed[j] = bytesReversed[j + 1];
                }
                len--;
            }
            bytesReversed[len] = alphabet[remainder];
            len++;
            if (needBreak) {
                break;
            }
        }
        
        // Reverse
        bytes memory result = bytes(new string(32));
        result[0] = appCode;
        for (i = 0; i < 31; i++) {
            result[i + 1] = bytesReversed[len - 1 - i];
        }
        
        return bytesToBytes32(result);
    }

    // Create BTC Address: https://en.bitcoin.it/wiki/Technical_background_of_version_1_Bitcoin_addresses#How_to_create_Bitcoin_Address
    function createBtcAddressHex(bytes32 publicXPoint, bytes32 publicYPoint) constant returns(bytes32) {
        bytes20 publicKeyPart = ripemd160(sha256(0x04, publicXPoint, publicYPoint));
        bytes32 publicKeyCheckCode = sha256(sha256(0x00, publicKeyPart));
        
        bytes memory publicKey = new bytes(32);
        for (uint i = 0; i < 7; i++) {
            publicKey[i] = 0x00;
        }
        publicKey[7] = 0x00; // Main Network
        for (uint j = 0; j < 20; j++) {
            publicKey[j + 8] = publicKeyPart[j];
        }
        publicKey[28] = publicKeyCheckCode[0];
        publicKey[29] = publicKeyCheckCode[1];
        publicKey[30] = publicKeyCheckCode[2];
        publicKey[31] = publicKeyCheckCode[3];
        
        return bytesToBytes32(publicKey);
    }
    
    function createBtcAddress(bytes32 publicXPoint, bytes32 publicYPoint) constant returns(bytes32) {
        return toBase58Checked(uint256(createBtcAddressHex(publicXPoint, publicYPoint)), "1");
    }

    // https://github.com/stonecoldpat/anonymousvoting/blob/master/LocalCrypto.sol
    function invmod(uint a, uint p) internal constant returns (uint) {
        if (a == 0 || a == p || p == 0)
            return 0;
        if (a > p)
            a = a % p;
        int t1;
        int t2 = 1;
        uint r1 = p;
        uint r2 = a;
        uint q;
        while (r2 != 0) {
            q = r1 / r2;
            (t1, t2, r1, r2) = (t2, t1 - int(q) * t2, r2, r1 - q * r2);
        }
        if (t1 < 0)
            return (p - uint(-t1));
        return uint(t1);
    }
    
    // https://github.com/stonecoldpat/anonymousvoting/blob/master/LocalCrypto.sol
    function submod(uint a, uint b, uint m) returns (uint){
        uint a_nn;

        if (a > b) {
            a_nn = a;
        } else {
            a_nn = a + m;
        }

        return addmod(a_nn - b, 0, m);
    }
    
    // https://en.wikipedia.org/wiki/Elliptic_curve_point_multiplication#Point_addition
    // https://github.com/bellaj/Blockchain/blob/6bffb47afae6a2a70903a26d215484cf8ff03859/ecdsa_bitcoin.pdf
    // https://math.stackexchange.com/questions/2198139/elliptic-curve-formulas-for-point-addition
    function addXY(uint x1, uint y1, uint x2, uint y2) returns(bytes32 x3, bytes32 y3) {
        uint m = uint(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f);
        uint anti = invmod(submod(x2, x1, m), m);
        uint alpha = mulmod(submod(y2, y1, m), anti, m);
        x3 = bytes32(submod(submod(mulmod(alpha, alpha, m), x2, m), x1, m));
        y3 = bytes32(submod(mulmod(alpha, submod(x1, uint(x3), m), m), y1, m));
        // x3 = bytes32(mul_mod(uint(x3), uint(y3), m)); == 1!!!!
        
        // https://github.com/jbaylina/ecsol/blob/master/ec.sol
        //(x3, y3) = (  bytes32(addmod( mulmod(y2, x1 , m) ,
        //                      mulmod(x2, y1 , m),
        //                      m)),
        //              bytes32(mulmod(y1, y2 , m))
        //            );
    }

    function complexityForBtcAddressPrefix(bytes prefix, uint length) constant returns(uint) {
        require(prefix.length >= length);
        
        //TODO: Implement more complex algo
        // https://bitcoin.stackexchange.com/questions/48586/best-way-to-calculate-difficulty-of-generating-specific-vanity-address
        
        return 58 ** length; 
    }

    function requireValidBicoinAddressPrefix(bytes prefixArg) constant {
        require(prefixArg.length >= 4);
        require(prefixArg[0] == "1" || prefixArg[0] == "3");
        
        for (uint i = 0; i < prefixArg.length; i++) {
            byte ch = prefixArg[i];
            require(ch != "0" && ch != "O" && ch != "I" && ch != "l");
            require((ch >= "1" && ch <= "9") || (ch >= "a" && ch <= "z") || (ch >= "A" && ch <= "Z"));
        }
    }

}
