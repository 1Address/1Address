pragma solidity ^0.4.0;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import './VanityLib.sol';
import './Upgradable.sol';

contract IEC {

    function _inverse(uint256 a) public constant 
        returns(uint256 invA);

    function _ecAdd(uint256 x1,uint256 y1,uint256 z1,
                    uint256 x2,uint256 y2,uint256 z2) public constant
        returns(uint256 x3,uint256 y3,uint256 z3);

    function _ecDouble(uint256 x1,uint256 y1,uint256 z1) public constant
        returns(uint256 x3,uint256 y3,uint256 z3);

    function _ecMul(uint256 d, uint256 x1,uint256 y1,uint256 z1) public constant
        returns(uint256 x3,uint256 y3,uint256 z3);

    function publicKey(uint256 privKey) public constant
        returns(uint256 qx, uint256 qy);

    function deriveKey(uint256 privKey, uint256 pubX, uint256 pubY) public constant
        returns(uint256 qx, uint256 qy);

}

contract TaskRegister is Upgradable, VanityLib {

    enum TaskType {
        BITCOIN_ADDRESS_PREFIX
    }

    struct Task {
        TaskType taskType;
        uint256 taskId;
        address creator;
        uint256 reward;
        bytes32 data;
        uint256 dataLength;
        uint256 requestPublicXPoint;
        uint256 requestPublicYPoint;
        uint256 answerPrivateKey;
    }

    IEC public ec;
    ERC20 public token;
    uint256 public nextTaskId = 1;
    uint256 public totalReward;
    
    Task[] tasks;
    Task[] completedTasks;
    mapping(uint256 => uint) indexOfTaskId; // Starting from 1
    event TaskCreated(uint256 indexed taskId);
    event TaskSolved(uint256 indexed taskId);

    function TaskRegister(address _ec, address _token, address _prevVersion) public Upgradable(_prevVersion) {
        ec = IEC(_ec);
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
        //     indexOfTaskId[task.taskId] = tasks.length;
        // }
    }

    function tasksCount() public constant returns(uint) {
        return tasks.length;
    }

    function completedTasksCount() public constant returns(uint) {
        return completedTasks.length;
    }

    function payForTask(uint256 taskId, uint256 reward) public isLastestVersion {
        uint index = safeIndexOfTaskId(taskId);
        token.transferFrom(msg.sender, this, reward);
        tasks[index].reward += reward;
        totalReward += reward;
    }

    function safeIndexOfTaskId(uint taskId) public constant returns(uint) {
        uint index = indexOfTaskId[taskId];
        require(index > 0);
        return index - 1;
    }
    
    function createBitcoinAddressPrefixTask(bytes prefix, uint256 reward, uint256 requestPublicXPoint, uint256 requestPublicYPoint) public isLastestVersion {
        require(prefix.length > 5);
        require(prefix[0] == "1");
        //require(reward > 0);
        token.transferFrom(msg.sender, this, reward);

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
            reward: reward,
            data: data,
            dataLength: prefix.length,
            requestPublicXPoint: requestPublicXPoint,
            requestPublicYPoint: requestPublicYPoint,
            answerPrivateKey: 0
        });
        tasks.push(task);
        indexOfTaskId[nextTaskId] = tasks.length; // incremented to avoid 0 index
        TaskCreated(nextTaskId);
        nextTaskId++;
    }
    
    function solveTask(uint taskId, uint256 answerPrivateKey) public isLastestVersion {
        uint taskIndex = safeIndexOfTaskId(taskId);
        Task storage task = tasks[taskIndex];

        // Require private key to be part of address to prevent front-running attack
        bytes32 answerPrivateKeyBytes = bytes32(answerPrivateKey);
        bytes32 senderAddressBytes = bytes32(uint256(msg.sender) << 96);
        for (uint i = 0; i < 16; i++) {
            require(answerPrivateKeyBytes[i] == senderAddressBytes[i]);
        }

        if (task.taskType == TaskType.BITCOIN_ADDRESS_PREFIX) {
            var (answerPublicXPoint, answerPublicYPoint) = ec.publicKey(answerPrivateKey);
            var (publicXPoint, publicYPoint, z) = ec._ecAdd(
                task.requestPublicXPoint,
                task.requestPublicYPoint,
                1,
                answerPublicXPoint,
                answerPublicYPoint,
                1
            );
            
            // (y^2 == x^3 + 7) mod m
            uint256 m = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
            z = ec._inverse(z);
            publicXPoint = mulmod(publicXPoint, z, m);
            publicYPoint = mulmod(publicYPoint, z, m);
            require(mulmod(publicYPoint, publicYPoint,m) ==
                    addmod(mulmod(publicXPoint, mulmod(publicXPoint, publicXPoint, m), m), 7, m));

            bytes32 btcAddress = createBtcAddress(publicXPoint, publicYPoint);
            uint prefixLength = lengthOfCommonPrefix3232(btcAddress, task.data);
            require(prefixLength == task.dataLength);
            task.answerPrivateKey = answerPrivateKey;
        }

        token.transfer(msg.sender, task.reward);
        totalReward -= task.reward;

        completeTask(taskId, taskIndex);
        TaskSolved(taskId);
    }

    function completeTask(uint taskId, uint index) internal {
        completedTasks.push(tasks[index]);
        tasks[index] = tasks[tasks.length - 1];
        tasks.length -= 1;

        delete indexOfTaskId[taskId];
        if (tasks.length > 0) {
            indexOfTaskId[tasks[index].taskId] = index + 1;
        }
    }

    function recoverLost(ERC20Basic _token, address loser) public onlyOwner {
        uint256 amount = _token.balanceOf(this);
        if (_token == token) {
            amount -= totalReward;
        }
        _token.transfer(loser, _token.balanceOf(this));
    }

}
