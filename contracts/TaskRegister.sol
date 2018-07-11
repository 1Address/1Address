pragma solidity ^0.4.24;

import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./VanityLib.sol";
import "./Upgradable.sol";


contract IEC {

    function _inverse(uint256 a) public view 
        returns(uint256 invA);

    function _ecAdd(uint256 x1,uint256 y1,uint256 z1,
                    uint256 x2,uint256 y2,uint256 z2) public view
        returns(uint256 x3,uint256 y3,uint256 z3);

    function _ecDouble(uint256 x1,uint256 y1,uint256 z1) public view
        returns(uint256 x3,uint256 y3,uint256 z3);

    function _ecMul(uint256 d, uint256 x1,uint256 y1,uint256 z1) public view
        returns(uint256 x3,uint256 y3,uint256 z3);

    function publicKey(uint256 privKey) public view
        returns(uint256 qx, uint256 qy);

    function deriveKey(uint256 privKey, uint256 pubX, uint256 pubY) public view
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
    uint256 public nextTaskId = 1;
    uint256 public totalReward;
    
    Task[] public tasks;
    Task[] public completedTasks;
    mapping(uint256 => uint) public indexOfTaskId; // Starting from 1
    event TaskCreated(uint256 indexed taskId);
    event TaskSolved(uint256 indexed taskId);
    event TaskPayed(uint256 indexed taskId);

    constructor(address _ec, address _prevVersion) public Upgradable(_prevVersion) {
        ec = IEC(_ec);
    }

    function upgrade(uint _size) public onlyOwner {
        require(upgradableState.isUpgrading);
        require(upgradableState.prevVersion != 0);

        // Migrate some vars
        nextTaskId = TaskRegister(upgradableState.prevVersion).nextTaskId();
        totalReward = TaskRegister(upgradableState.prevVersion).totalReward();

        uint index = tasks.length;
        uint tasksCount = TaskRegister(upgradableState.prevVersion).tasksCount();

        // Migrate tasks

        for (uint i = index; i < index + _size && i < tasksCount; i++) {
            tasks.push(Task(TaskType.BITCOIN_ADDRESS_PREFIX,0,0,0,bytes32(0),0,0,0,0));
        }

        for (uint j = index; j < index + _size && j < tasksCount; j++) {
            (
                tasks[j].taskType,
                tasks[j].taskId,
                tasks[j].creator,
                tasks[j].reward,
                tasks[j].data,
                ,//tasks[j].dataLength, 
                ,//tasks[j].requestPublicXPoint, 
                ,//tasks[j].requestPublicYPoint,
                 //tasks[j].answerPrivateKey
            ) = TaskRegister(upgradableState.prevVersion).tasks(j);
            indexOfTaskId[tasks[j].taskId] = j + 1;
        }

        for (uint k = index; k < index + _size && k < tasksCount; k++) {
            (
                ,//tasks[k].taskType,
                ,//tasks[k].taskId,
                ,//tasks[k].creator,
                ,//tasks[k].reward,
                ,//tasks[k].data,
                tasks[k].dataLength, 
                tasks[k].requestPublicXPoint, 
                tasks[k].requestPublicYPoint,
                tasks[k].answerPrivateKey
            ) = TaskRegister(upgradableState.prevVersion).tasks(k);
        }
    }
    
    function endUpgrade() public {
        super.endUpgrade();
    }

    function tasksCount() public view returns(uint) {
        return tasks.length;
    }

    function completedTasksCount() public view returns(uint) {
        return completedTasks.length;
    }

    function payForTask(uint256 _taskId) payable public isLastestVersion {
        uint index = safeIndexOfTaskId(_taskId);
        _payForTask(tasks[index], _taskId);
    }

    function safeIndexOfTaskId(uint _taskId) public view returns(uint) {
        uint index = indexOfTaskId[_taskId];
        require(index > 0);
        return index - 1;
    }
    
    // Pass reward == 0 for automatically determine already transferred value
    function createBitcoinAddressPrefixTask(
        bytes prefix,
        uint256 requestPublicXPoint,
        uint256 requestPublicYPoint
    )
        payable
        public
        isLastestVersion
    {
        require(prefix.length > 5);
        require(prefix[0] == "1");
        require(prefix[1] != "1"); // Do not support multiple 1s yet
        require(isValidBicoinAddressPrefix(prefix));
        require(isValidPublicKey(requestPublicXPoint, requestPublicYPoint));

        bytes32 data;
        assembly {
            data := mload(add(prefix, 32))
        }
        
        Task memory task = Task({
            taskType: TaskType.BITCOIN_ADDRESS_PREFIX,
            taskId: nextTaskId,
            creator: msg.sender,
            reward: 0,
            data: data,
            dataLength: prefix.length,
            requestPublicXPoint: requestPublicXPoint,
            requestPublicYPoint: requestPublicYPoint,
            answerPrivateKey: 0
        });

        indexOfTaskId[nextTaskId] = tasks.push(task); // incremented to avoid 0 index
        emit TaskCreated(nextTaskId);
        _payForTask(tasks[tasks.length - 1], nextTaskId);
        nextTaskId++;
    }
    
    function solveTask(uint _taskId, uint256 _answerPrivateKey) public isLastestVersion {
        uint taskIndex = safeIndexOfTaskId(_taskId);
        Task storage task = tasks[taskIndex];
        require(task.answerPrivateKey == 0, "solveTask: task is already solved");

        // Require private key to be part of address to prevent front-running attack
        bytes32 answerPrivateKeyBytes = bytes32(_answerPrivateKey);
        bytes32 senderAddressBytes = bytes32(uint256(msg.sender) << 96);
        for (uint i = 0; i < 16; i++) {
            require(answerPrivateKeyBytes[i] == senderAddressBytes[i], "solveTask: this solution does not match miner address");
        }

        if (task.taskType == TaskType.BITCOIN_ADDRESS_PREFIX) {
            uint256 answerPublicXPoint;
            uint256 answerPublicYPoint;
            uint256 publicXPoint;
            uint256 publicYPoint;
            uint256 z;
            (answerPublicXPoint, answerPublicYPoint) = ec.publicKey(_answerPrivateKey);
            (publicXPoint, publicYPoint, z) = ec._ecAdd(
                task.requestPublicXPoint,
                task.requestPublicYPoint,
                1,
                answerPublicXPoint,
                answerPublicYPoint,
                1
            );

            uint256 m = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
            z = ec._inverse(z);
            publicXPoint = mulmod(publicXPoint, z, m);
            publicYPoint = mulmod(publicYPoint, z, m);
            require(isValidPublicKey(publicXPoint, publicYPoint));
            
            bytes32 btcAddress = createBtcAddress(publicXPoint, publicYPoint);
            uint prefixLength = lengthOfCommonPrefix(btcAddress, task.data);
            require(prefixLength == task.dataLength);
            
            task.answerPrivateKey = _answerPrivateKey;
        } else {
            revert();
        }

        msg.sender.transfer(task.reward * 99 / 100); // 1% fee
        totalReward -= task.reward * 99 / 100;

        _completeTask(_taskId, taskIndex);
        emit TaskSolved(_taskId);
    }

    function _payForTask(Task storage _task, uint _taskId) internal {
        require(msg.value > 0, "payForTask: provide non zero payment");
        _task.reward += msg.value;
        totalReward += msg.value;
        emit TaskPayed(_taskId);
    }

    function _completeTask(uint _taskId, uint _index) internal {
        completedTasks.push(tasks[_index]);
        if (_index < tasks.length - 1) { // if not latest
            tasks[_index] = tasks[tasks.length - 1];
            indexOfTaskId[tasks[_index].taskId] = _index + 1;
        }
        tasks.length -= 1;
        delete indexOfTaskId[_taskId];
    }

    function claim(ERC20Basic _token, address _to) public onlyOwner {
        if (_token == address(0)) {
            _to.transfer(address(this).balance - totalReward);
        } else {
            _token.transfer(_to, _token.balanceOf(this));
        }
    }

}
