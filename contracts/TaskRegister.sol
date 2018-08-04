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
        uint256 taskId; // Upper 128 bits are TaskType
        address creator;
        address referrer;
        uint256 reward;
        bytes32 data;
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

    Task[] public allTasks;
    uint256[] public taskIds;
    uint256[] public completedTaskIds;
    mapping(uint256 => uint) public indexOfTaskId; // Starting from 1
    mapping(uint256 => uint) public indexOfActiveTaskId; // Starting from 1
    mapping(uint256 => uint) public indexOfCompletedTaskId; // Starting from 1

    event TaskCreated(uint256 indexed taskId);
    event TaskSolved(uint256 indexed taskId, uint256 reward);
    event TaskPayed(uint256 indexed taskId, uint256 value);

    constructor(address _ec, address _prevVersion) public Upgradable(_prevVersion) {
        ec = EC(_ec);
    }

    function allTasksCount() public view returns(uint) {
        return allTasks.length;
    }

    function tasksCount() public view returns(uint) {
        return taskIds.length;
    }

    function tasks(uint i) public view returns(uint256, address, address, uint256, bytes32, uint256, uint256, uint256) {
        Task storage t = allTasks[indexOfTaskId[taskIds[i]].sub(1)];
        return (t.taskId, t.creator, t.referrer, t.reward, t.data, t.requestPublicXPoint, t.requestPublicYPoint, t.answerPrivateKey);
    }

    function completedTasksCount() public view returns(uint) {
        return completedTaskIds.length;
    }

    function completedTasks(uint i) public view returns(uint256, address, address, uint256, bytes32, uint256, uint256, uint256) {
        Task storage t = allTasks[indexOfTaskId[completedTaskIds[i]].sub(1)];
        return (t.taskId, t.creator, t.referrer, t.reward, t.data, t.requestPublicXPoint, t.requestPublicYPoint, t.answerPrivateKey);
    }

    function getActiveTasks() external view
        returns (
            uint256[] t_taskIds,
            address[] t_creators,
            //address[] t_referrers,
            uint256[] t_rewards,
            bytes32[] t_datas,
            uint256[] t_requestPublicXPoints,
            uint256[] t_requestPublicYPoints,
            uint256[] t_answerPrivateKeys
        )
    {
        t_taskIds = new uint256[](allTasks.length);
        t_creators = new address[](allTasks.length);
        //t_referrers = new address[](allTasks.length);
        t_rewards = new uint256[](allTasks.length);
        t_datas = new bytes32[](allTasks.length);
        t_requestPublicXPoints = new uint256[](allTasks.length);
        t_requestPublicYPoints = new uint256[](allTasks.length);
        t_answerPrivateKeys = new uint256[](allTasks.length);

        for (uint i = 0; i < taskIds.length; i++) {
            uint index = indexOfActiveTaskId[taskIds[i]];
            (
                t_taskIds[i],
                t_creators[i],
                //t_referrers[i],
                t_rewards[i],
                t_datas[i],
                t_requestPublicXPoints[i],
                t_requestPublicYPoints[i],
                t_answerPrivateKeys[i]
            ) = (
                allTasks[index].taskId,
                allTasks[index].creator,
                //allTasks[index].referrer,
                allTasks[index].reward,
                allTasks[index].data,
                allTasks[index].requestPublicXPoint,
                allTasks[index].requestPublicYPoint,
                allTasks[index].answerPrivateKey
            );
        }
    }

    function getCompletedTasks() external view
        returns (
            uint256[] t_taskIds,
            address[] t_creators,
            //address[] t_referrers,
            uint256[] t_rewards,
            bytes32[] t_datas,
            uint256[] t_requestPublicXPoints,
            uint256[] t_requestPublicYPoints,
            uint256[] t_answerPrivateKeys
        )
    {
        t_taskIds = new uint256[](allTasks.length);
        t_creators = new address[](allTasks.length);
        //t_referrers = new address[](allTasks.length);
        t_rewards = new uint256[](allTasks.length);
        t_datas = new bytes32[](allTasks.length);
        t_requestPublicXPoints = new uint256[](allTasks.length);
        t_requestPublicYPoints = new uint256[](allTasks.length);
        t_answerPrivateKeys = new uint256[](allTasks.length);

        for (uint i = 0; i < completedTaskIds.length; i++) {
            uint index = indexOfCompletedTaskId[completedTaskIds[i]];
            (
                t_taskIds[i],
                t_creators[i],
                //t_referrers[i],
                t_rewards[i],
                t_datas[i],
                t_requestPublicXPoints[i],
                t_requestPublicYPoints[i],
                t_answerPrivateKeys[i]
            ) = (
                allTasks[index].taskId,
                allTasks[index].creator,
                //allTasks[index].referrer,
                allTasks[index].reward,
                allTasks[index].data,
                allTasks[index].requestPublicXPoint,
                allTasks[index].requestPublicYPoint,
                allTasks[index].answerPrivateKey
            );
        }
    }

    function setServiceFee(uint256 _serviceFee) public onlyOwner {
        require(_serviceFee <= 20000, "setServiceFee: value should be less than 20000, which means 2% of miner reward");
        serviceFee = _serviceFee;
    }

    function setReferrerFee(uint256 _referrerFee) public onlyOwner {
        require(_referrerFee <= 500000, "setReferrerFee: value should be less than 500000, which means 50% of service fee");
        referrerFee = _referrerFee;
    }

    function upgrade(uint _size) public onlyOwner {
        require(upgradableState.isUpgrading);
        require(upgradableState.prevVersion != 0);

        // Migrate some vars
        TaskRegister prev = TaskRegister(upgradableState.prevVersion);
        nextTaskId = prev.nextTaskId();
        totalReward = prev.totalReward();
        serviceFee = prev.serviceFee();
        referrerFee = prev.referrerFee();

        uint index = allTasks.length;
        uint tasksLength = prev.tasksCount();
        
        // Migrate tasks

        for (uint i = index; i < index + _size && i < tasksLength; i++) {
            allTasks.push(Task((uint(TaskType.BITCOIN_ADDRESS_PREFIX) << 128) | 0,0,0,0,bytes32(0),0,0,0));
            uint j = prev.indexOfActiveTaskId(prev.taskIds(i));
            (
                allTasks[i].taskId,
                allTasks[i].creator,
                allTasks[i].referrer,
                allTasks[i].reward,
                ,//allTasks[i].data,
                ,//allTasks[i].requestPublicXPoint,
                ,//allTasks[i].requestPublicYPoint,
                 //allTasks[i].answerPrivateKey
            ) = prev.allTasks(j);
            indexOfTaskId[allTasks[i].taskId] = i + 1;
        }

        for (i = index; i < index + _size && i < tasksLength; i++) {
            j = prev.indexOfActiveTaskId(prev.taskIds(i));
            (
                ,//allTasks[i].taskId,
                ,//allTasks[i].creator,
                ,//allTasks[i].referrer,
                ,//allTasks[i].reward,
                allTasks[i].data,
                allTasks[i].requestPublicXPoint,
                allTasks[i].requestPublicYPoint,
                allTasks[i].answerPrivateKey
            ) = prev.allTasks(j);
        }

        for (i = index; i < index + _size && i < tasksLength; i++) {
            uint taskId = prev.taskIds(i);
            indexOfActiveTaskId[taskId] = taskIds.push(taskId);
        }
    }

    function endUpgrade() public {
        super.endUpgrade();

        if (upgradableState.nextVersion != 0) {
            upgradableState.nextVersion.transfer(address(this).balance);
        }

        //_removeAllActiveTasksWithHoles(0, taskIds.length);
    }

    function payForTask(uint256 _taskId) public payable isLastestVersion {
        if (msg.value > 0) {
            Task storage task = allTasks[indexOfTaskId[_taskId].sub(1)];
            require(task.answerPrivateKey == 0, "payForTask: you can't pay for the solved task");
            task.reward = task.reward.add(msg.value);
            totalReward = totalReward.add(msg.value);
            emit TaskPayed(_taskId, msg.value);
        }
    }

    function createBitcoinAddressPrefixTask(
        bytes prefix,
        uint256 requestPublicXPoint,
        uint256 requestPublicYPoint,
        address referrer
    )
        public
        payable
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

        uint256 taskId = nextTaskId++;
        Task memory task = Task({
            taskId: (uint(TaskType.BITCOIN_ADDRESS_PREFIX) << 128) | taskId,
            creator: msg.sender,
            referrer: referrer,
            reward: 0,
            data: data,
            requestPublicXPoint: requestPublicXPoint,
            requestPublicYPoint: requestPublicYPoint,
            answerPrivateKey: 0
        });

        indexOfTaskId[taskId] = allTasks.push(task); // incremented to avoid 0 index
        indexOfActiveTaskId[taskId] = taskIds.push(taskId);
        emit TaskCreated(taskId);
        payForTask(taskId);
    }

    function solveTask(uint _taskId, uint256 _answerPrivateKey, uint256 publicXPoint, uint256 publicYPoint) public isLastestVersion {
        uint activeTaskIndex = indexOfTaskId[_taskId].sub(1);
        Task storage task = allTasks[activeTaskIndex];
        require(task.answerPrivateKey == 0, "solveTask: task is already solved");
        
        // Require private key to be part of address to prevent front-running attack
        require(_answerPrivateKey >> 128 == uint256(msg.sender) >> 32, "solveTask: this solution does not match miner address");

        if (TaskType(task.taskId >> 128) == TaskType.BITCOIN_ADDRESS_PREFIX) {
            ///(publicXPoint, publicYPoint) = ec.publicKey(_answerPrivateKey);
            require(ec.publicKeyVerify(_answerPrivateKey, publicXPoint, publicYPoint));
            (publicXPoint, publicYPoint) = ec.ecadd(
                task.requestPublicXPoint,
                task.requestPublicYPoint,
                publicXPoint,
                publicYPoint
            );

            bytes32 btcAddress = createBtcAddress(publicXPoint, publicYPoint);
            require(haveCommonPrefixUntilZero(task.data, btcAddress), "solveTask: found prefix is not enough");

            task.answerPrivateKey = _answerPrivateKey;
        } else {
            revert();
        }

        uint256 taskReard = task.reward;
        uint256 serviceReward = taskReard.mul(serviceFee).div(MAX_PERCENT); // 1%
        uint256 minerReward = taskReard - serviceReward; // 99%
        if (serviceReward != 0 && task.referrer != 0) {
            uint256 referrerReward = serviceReward.mul(referrerFee).div(MAX_PERCENT); // 50% of service reward
            task.referrer.transfer(referrerReward);
        }
        msg.sender.transfer(minerReward);
        totalReward -= taskReard;

        _completeTask(_taskId, activeTaskIndex);
        emit TaskSolved(_taskId, minerReward);
    }

    function _completeTask(uint _taskId, uint _activeTaskIndex) internal {
        indexOfCompletedTaskId[_taskId] = completedTaskIds.push(_taskId);
        delete indexOfActiveTaskId[_taskId];

        if (_activeTaskIndex + 1 < taskIds.length) { // if not latest
            uint256 lastTaskId = taskIds[taskIds.length - 1];
            taskIds[_activeTaskIndex] = lastTaskId;
            indexOfActiveTaskId[lastTaskId] = _activeTaskIndex + 1;
        }
        taskIds.length -= 1;
    }

    // function _removeAllActiveTasksWithHoles(uint _from, uint _to) internal {
    //     for (uint i = _from; i < _to && i < taskIds.length; i++) {
    //         uint taskId = taskIds[i];
    //         uint index = indexOfTaskId[taskId].sub(1);
    //         delete allTasks[index];
    //         delete indexOfTaskId[taskId];
    //         delete indexOfActiveTaskId[taskId];
    //     }
    //     if (_to >= taskIds.length) {
    //         taskIds.length = 0;
    //     }
    // }

    function claim(ERC20Basic _token, address _to) public onlyOwner {
        if (_token == address(0)) {
            _to.transfer(address(this).balance - totalReward);
        } else {
            _token.transfer(_to, _token.balanceOf(this));
        }
    }

}
