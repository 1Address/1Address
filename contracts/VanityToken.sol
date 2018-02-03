pragma solidity ^0.4.0;

import "zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "zeppelin-solidity/contracts/token/ERC20/PausableToken.sol";


contract VanityToken is MintableToken, PausableToken {

    // Metadata
    string public constant symbol = "VIP";
    string public constant name = "VanIty Pool";
    uint8 public constant decimals = 18;
    string public constant version = "1.0";

}