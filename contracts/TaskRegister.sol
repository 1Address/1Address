pragma solidity ^0.4.0;
pragma experimental ABIEncoderV2;

import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import './VanityLib.sol';
import './EC.sol';
import './BitcoinTask.sol';
import './Upgradable.sol';


contract TaskRegister is Upgradable, VanityLib {

    enum TaskType {
        BITCOIN_ADDRESS_PREFIX
    }

    struct Task {
        TaskType taskType;
        uint256 taskId;
        address creator;
        bytes32 data;
        uint256 dataLength;
        uint256 requestPublicXPoint;
        uint256 requestPublicYPoint;
        uint256 answerPrivateKey;
    }

    EC public ec;
    ERC20 public token;
    uint256 public nextTaskId = 1;
    
    Task[] public tasks;
    Task[] public completedTasks;
    mapping(uint => uint) indexOfTask; // Starting from 1
    event TaskCreated(Task task);
    event TaskSolved(Task task);

    function TaskRegister(address _ec, address _token, address _prevVersion) public Upgradable(_prevVersion) {
        ec = EC(_ec);
        token = ERC20(_token);
        // Migration
        // for (uint i = 0; i < prevVersion.tasksCount(); i++) {
        //     Task memory task = Task(TaskType.BITCOIN_ADDRESS_PREFIX,0,0,bytes32(0),0,0,0,0);
        //     (
        //         task.taskType,
        //         task.taskId, 
        //         task.creator, 
        //         task.data,
        //         task.dataLength, 
        //         task.requestPublicXPoint, 
        //         task.requestPublicYPoint,
        //         task.answerPrivateKey
        //     ) = prevVersion.tasks(i);
        //     tasks.push(task);
        //     indexOfTask[task.taskId] = tasks.length;
        // }
    }

    function tasksCount() public constant returns(uint) {
        return tasks.length;
    }

    function safeIndexOfTask(uint taskId) public constant returns(uint) {
        uint index = indexOfTask[taskId];
        require(index > 0);
        return index - 1;
    }
    
    function createBitcoinAddressPrefixTask(bytes prefix, uint256 requestPublicXPoint, uint256 requestPublicYPoint) public isLastestVersion {
        require(prefix.length > 5);
        require(prefix[0] == '1');
        // (y^2 == x^3 + 7) mod m
        uint256 m = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
        require(mulmod(requestPublicYPoint, requestPublicYPoint,m) ==
                addmod(mulmod(requestPublicXPoint, mulmod(requestPublicXPoint, requestPublicXPoint, m), m), 7, m));

        bytes32 data;
        assembly {
            data := mload(add(prefix, 32))
        }
        
        Task memory task = Task({
            taskType: TaskType.BITCOIN_ADDRESS_PREFIX,
            taskId: nextTaskId,
            creator: msg.sender,
            data: data,
            dataLength: prefix.length,
            requestPublicXPoint: requestPublicXPoint,
            requestPublicYPoint: requestPublicYPoint,
            answerPrivateKey: 0
        });
        tasks.push(task);
        indexOfTask[nextTaskId] = tasks.length; // incremented to avoid 0 index
        TaskCreated(task);
        nextTaskId++;
    }
    
    function solveTask(uint taskId, uint256 answerPrivateKey) public isLastestVersion {
        uint taskIndex = safeIndexOfTask(taskId);
        Task storage task = tasks[taskIndex];

        // Require private key to be part of address to prevent front-running attack
        bytes32 answerPrivateKeyBytes = bytes32(answerPrivateKey);
        bytes32 senderAddressBytes = bytes32(uint256(msg.sender) << 96);
        for (uint i = 0; i < 16; i++) {
            require(answerPrivateKeyBytes[i] == senderAddressBytes[i]);
        }
        
        if (task.taskType == TaskType.BITCOIN_ADDRESS_PREFIX) {
            var (answerPublicXPoint, answerPublicYPoint) = ec.publicKey(answerPrivateKey);
            var (publicXPoint, publicYPoint) = ec._jAdd(
                uint(task.requestPublicXPoint),
                uint(task.requestPublicYPoint), 
                uint(answerPublicXPoint), 
                uint(answerPublicYPoint)
            );
            bytes32 btcAddress = createBtcAddress(publicXPoint, publicYPoint);
            uint prefixLength = lengthOfCommonPrefix3232(btcAddress, task.data);
            require(prefixLength == task.dataLength);
            task.answerPrivateKey = answerPrivateKey;
        }

        completeTask(taskId, taskIndex);
        TaskSolved(task);
    }

    function completeTask(uint taskId, uint index) internal isLastestVersion {
        completedTasks.push(tasks[index]);
        tasks[index] = tasks[tasks.length - 1];
        tasks.length -= 1;

        delete indexOfTask[taskId];
        indexOfTask[tasks[index].taskId] = index;
    }
}
