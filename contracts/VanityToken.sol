pragma solidity ^0.4.0;

import "../node_modules/zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "../node_modules/zeppelin-solidity/contracts/token/ERC20/PausableToken.sol";
import "../node_modules/zeppelin-solidity/contracts/token/ERC827/ERC827Token.sol";


contract VanityToken is MintableToken, PausableToken, ERC827Token {

    // Metadata
    string public constant symbol = "VIP";
    string public constant name = "VanIty Pool";
    uint8 public constant decimals = 18;
    string public constant version = "1.0";

}