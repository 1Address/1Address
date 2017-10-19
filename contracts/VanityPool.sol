pragma solidity ^0.4.0;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import './VanityLib.sol';
import './VanityTask.sol';


contract VanityPool is Ownable {

    VanityTask[] public tasks;
    mapping(address => bool) public registeredTasks;
    
    event TaskCreated(VanityTask task);
    event TaskUpdated(VanityTask task);
    event TaskDeleted(VanityTask task);
    
    modifier onlyRegisteredTask(address task) {
        require(registeredTasks[task]);
        _;
    }
    
    function () payable {
    }
    
    function redeem(uint amount) onlyOwner {
        owner.transfer(amount);
    }

    function tasksCount() constant returns(uint) {
        return tasks.length;
    }
    
    function createTask(bytes prefixArg, bytes32 requestPublicXPointArg, bytes32 requestPublicYPointArg) {
        VanityTask task = new VanityTask(this, prefixArg, requestPublicXPointArg, requestPublicYPointArg);
        task.transferOwnership(msg.sender);
        tasks.push(task);
        registeredTasks[task] = true;
        TaskCreated(task);
    }
    
    function updateTask() onlyRegisteredTask(msg.sender) {
        VanityTask task = VanityTask(msg.sender);
        TaskUpdated(task);
    }
    
    function deleteTask(VanityTask task) onlyRegisteredTask(task) {
        require(msg.sender == task.owner());
        delete registeredTasks[task];

        for (uint i = 0; i < tasks.length; i++) {
            if (tasks[i] == task) {
                delete tasks[i];
                tasks[i] = tasks[tasks.length - 1];
                tasks.length -= 1;
                TaskDeleted(task);
                return;
            }
        }
        
        revert();
    }
}
