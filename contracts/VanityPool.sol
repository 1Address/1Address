pragma solidity ^0.4.0;

import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import './VanityLib.sol';
import './BitcoinTask.sol';


contract VanityPool is Ownable {

    ERC20 public token;
    address public nextVersion;
    mapping(address => bool) public registeredTasks;
    
    // Bitcoin-related
    BitcoinTask[] public bitcoinTasks;
    mapping(address => uint) indexOfBitcoinTask; // Starting from 1
    BitcoinTask[] public completedBitcoinTasks;
    event NextVersionAppeared();
    event BitcoinTaskCreated(BitcoinTask task);
    event BitcoinTaskCompleted(BitcoinTask task);

    modifier onlyRegisteredTask(address task) {
        require(registeredTasks[task]);
        _;
    }

    function setNextVersion(address _nextVersion) public onlyOwner {
        require(nextVersion == address(0));
        require(_nextVersion != address(0));
        nextVersion = _nextVersion;
        NextVersionAppeared();
    }

    function bitcoinTasksCount() public constant returns(uint) {
        return bitcoinTasks.length;
    }
    
    function createBitcoinTask(bytes prefix, uint256 requestPublicXPoint, uint256 requestPublicYPoint) public {
        BitcoinTask task = new BitcoinTask(token, this, prefix, requestPublicXPoint, requestPublicYPoint);
        bitcoinTasks.push(task);
        indexOfBitcoinTask[task] = bitcoinTasks.length;
        registeredTasks[task] = true;
        BitcoinTaskCreated(task);
    }
    
    function completeBitcoinTask(BitcoinTask task) public onlyRegisteredTask(msg.sender) {
        uint index = indexOfBitcoinTask[task];
        require(index > 0);
        delete indexOfBitcoinTask[task];

        completedBitcoinTasks.push(task);
        bitcoinTasks[index - 1] = bitcoinTasks[bitcoinTasks.length - 1];
        bitcoinTasks.length -= 1;
    }
}
