pragma solidity ^0.4.24;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../libs/EC.sol";
import "./VanityLib.sol";
import "./Upgradable.sol";


contract TaskRegister is Upgradable, VanityLib {
    using SafeMath for uint256;

    enum TaskType {
        BITCOIN_ADDRESS_PREFIX
    }

    struct Task {
        TaskType taskType;
        uint256 taskId;
        address creator;
        address referrer;
        uint256 reward;
        bytes32 data;
        uint256 dataLength;
        uint256 requestPublicXPoint;
        uint256 requestPublicYPoint;
        uint256 answerPrivateKey;
    }

    EC public ec;
    uint256 public nextTaskId = 1;
    uint256 public totalReward;
    uint256 constant public MAX_PERCENT = 1000000;
    uint256 public serviceFee; // 1% == 10000, 100% == 1000000
    uint256 public referrerFee; // Calculated from service fee, 50% == 500000
    
    Task[] public tasks;
    Task[] public completedTasks;
    mapping(uint256 => uint) public indexOfTaskId; // Starting from 1

    event TaskCreated(uint256 indexed taskId);
    event TaskSolved(uint256 indexed taskId, uint256 reward);
    event TaskPayed(uint256 indexed taskId, uint256 value);

    constructor(address _ec, address _prevVersion) public Upgradable(_prevVersion) {
        ec = EC(_ec);
    }

    function setServiceFee(uint256 _serviceFee) public onlyOwner {
        require(_serviceFee <= 20000); // 2% of reward
        serviceFee = _serviceFee;
    }

    function setReferrerFee(uint256 _referrerFee) public onlyOwner {
        require(_referrerFee <= 500000); // 50% of serviceFee
        referrerFee = _referrerFee;
    }

    function upgrade(uint _size) public onlyOwner {
        require(upgradableState.isUpgrading);
        require(upgradableState.prevVersion != 0);

        // Migrate some vars
        nextTaskId = TaskRegister(upgradableState.prevVersion).nextTaskId();
        totalReward = TaskRegister(upgradableState.prevVersion).totalReward();
        serviceFee = TaskRegister(upgradableState.prevVersion).serviceFee();
        referrerFee = TaskRegister(upgradableState.prevVersion).referrerFee();
        
        uint index = tasks.length;
        uint tasksCount = TaskRegister(upgradableState.prevVersion).tasksCount();

        // Migrate tasks

        for (uint i = index; i < index + _size && i < tasksCount; i++) {
            tasks.push(Task(TaskType.BITCOIN_ADDRESS_PREFIX,0,0,0,0,bytes32(0),0,0,0,0));
        }

        for (uint j = index; j < index + _size && j < tasksCount; j++) {
            (
                tasks[j].taskType,
                tasks[j].taskId,
                tasks[j].creator,
                tasks[j].referrer,
                ,//tasks[j].reward,
                ,//tasks[j].data,
                ,//tasks[j].dataLength, 
                ,//tasks[j].requestPublicXPoint, 
                ,//tasks[j].requestPublicYPoint,
                 //tasks[j].answerPrivateKey
            ) = TaskRegister(upgradableState.prevVersion).tasks(j);
            indexOfTaskId[tasks[j].taskId] = j + 1;
        }

        for (j = index; j < index + _size && j < tasksCount; j++) {
            (
                ,//tasks[j].taskType,
                ,//tasks[j].taskId,
                ,//tasks[j].creator,
                ,//tasks[j].referrer,
                tasks[j].reward,
                tasks[j].data,
                tasks[j].dataLength, 
                tasks[j].requestPublicXPoint, 
                ,//tasks[j].requestPublicYPoint,
                 //tasks[j].answerPrivateKey
            ) = TaskRegister(upgradableState.prevVersion).tasks(j);
        }

        for (j = index; j < index + _size && j < tasksCount; j++) {
            (
                ,//tasks[j].taskType,
                ,//tasks[j].taskId,
                ,//tasks[j].creator,
                ,//tasks[j].referrer,
                ,//tasks[j].reward,
                ,//tasks[j].data,
                ,//tasks[j].dataLength, 
                ,//tasks[j].requestPublicXPoint, 
                tasks[j].requestPublicYPoint,
                tasks[j].answerPrivateKey
            ) = TaskRegister(upgradableState.prevVersion).tasks(j);
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
        if (msg.value > 0) {
            Task storage task = tasks[safeIndexOfTaskId(_taskId)];
            task.reward = task.reward.add(msg.value);
            totalReward = totalReward.add(msg.value);
            emit TaskPayed(_taskId, msg.value);
        }
    }

    function safeIndexOfTaskId(uint _taskId) public view returns(uint) {
        return indexOfTaskId[_taskId].sub(1);
    }
    
    function createBitcoinAddressPrefixTask(
        bytes prefix,
        uint256 requestPublicXPoint,
        uint256 requestPublicYPoint,
        address referrer
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
            taskId: nextTaskId++,
            creator: msg.sender,
            referrer: referrer,
            reward: 0,
            data: data,
            dataLength: prefix.length,
            requestPublicXPoint: requestPublicXPoint,
            requestPublicYPoint: requestPublicYPoint,
            answerPrivateKey: 0
        });

        indexOfTaskId[task.taskId] = tasks.push(task); // incremented to avoid 0 index
        emit TaskCreated(task.taskId);
        payForTask(task.taskId);
    }
    
    function solveTask(uint _taskId, uint256 _answerPrivateKey, uint256 publicXPoint, uint256 publicYPoint) public isLastestVersion {
        uint taskIndex = safeIndexOfTaskId(_taskId);
        Task storage task = tasks[taskIndex];
        require(task.answerPrivateKey == 0, "solveTask: task is already solved");

        // Require private key to be part of address to prevent front-running attack
        require(_answerPrivateKey >> 128 == uint256(msg.sender) >> 32, "solveTask: this solution does not match miner address");

        if (task.taskType == TaskType.BITCOIN_ADDRESS_PREFIX) {
            ///(publicXPoint, publicYPoint) = ec.publicKey(_answerPrivateKey);
            require(ec.publicKeyVerify(_answerPrivateKey, publicXPoint, publicYPoint));
            (publicXPoint, publicYPoint) = ec.ecadd(
                task.requestPublicXPoint,
                task.requestPublicYPoint,
                publicXPoint,
                publicYPoint
            );

            require(isValidPublicKey(publicXPoint, publicYPoint));
            
            bytes32 btcAddress = createBtcAddress(publicXPoint, publicYPoint);
            uint prefixLength = lengthOfCommonPrefix(btcAddress, task.data);
            require(prefixLength == task.dataLength);
            
            task.answerPrivateKey = _answerPrivateKey;
        } else {
            revert();
        }

        uint256 minerReward = task.reward.mul(MAX_PERCENT - serviceFee).div(MAX_PERCENT); // 1% fee
        msg.sender.transfer(minerReward);
        totalReward = totalReward.sub(minerReward);

        if (task.referrer != 0) {
            uint256 referrerReward = task.reward.mul(serviceFee).mul(referrerFee).div(MAX_PERCENT).div(MAX_PERCENT); // 50% of service fee
            task.referrer.transfer(referrerReward);
            totalReward = totalReward.sub(referrerReward);
        }

        _completeTask(_taskId, taskIndex);
        emit TaskSolved(_taskId, minerReward);
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
