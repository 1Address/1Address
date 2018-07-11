pragma solidity ^0.4.0;

import "../../contracts/Upgradable.sol";


contract UpgradableImpl is Upgradable {

    uint count;

    function foo() public isLastestVersion {
        count++;
    }

    constructor(address _prevVersion) public Upgradable(_prevVersion) {
    }

}
