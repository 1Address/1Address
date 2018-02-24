pragma solidity ^0.4.0;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";


contract Upgradable is Ownable {

    struct UpgradableState {
        bool isUpgrading;
        address prevVersion;
        address nextVersion;
    }

    UpgradableState public upgradableState;

    event Initialized(address indexed prevVersion);
    event Upgrading(address indexed nextVersion);
    event Upgraded(address indexed nextVersion);

    modifier isLastestVersion {
        require(!upgradableState.isUpgrading);
        require(upgradableState.nextVersion == address(0));
        _;
    }

    modifier onlyOwnerOrigin {
        require(tx.origin == owner);
        _;
    }

    function Upgradable(address _prevVersion) public {
        if (_prevVersion != address(0)) {
            require(msg.sender == Upgradable(_prevVersion).owner());
            upgradableState.isUpgrading = true;
            upgradableState.prevVersion = _prevVersion;
            Upgradable(_prevVersion).startUpgrade();
        } else {
            Initialized(_prevVersion);
        }
    }

    function startUpgrade() public onlyOwnerOrigin {
        require(msg.sender != owner);
        upgradableState.isUpgrading = true;
        upgradableState.nextVersion = msg.sender;
        Upgrading(msg.sender);
    }

    //function upgrade(uint index, uint size) public onlyOwner {}

    function endUpgrade() public onlyOwnerOrigin {
        upgradableState.isUpgrading = false;
        if (msg.sender != owner) {
            Upgraded(upgradableState.nextVersion);
        } 
        else  {
            if (upgradableState.prevVersion != address(0)) {
                Upgradable(upgradableState.prevVersion).endUpgrade();
            }
            Initialized(upgradableState.prevVersion);
        }
    }

}