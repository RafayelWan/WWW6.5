interface IDepositBox {
    function getOwner() external view returns (address);
    function transferOwnership(address newOwner) external;
    function storeSecret(string memory secret) external;
    function getSecret() external view returns (string memory);
    function getBoxType() external pure returns (string memory);
    function getDepositTime() external view returns (uint256);
}

abstract contract BaseDepositBox is IDepositBox {
    address public owner;
    string public metadata;
    string private secret;
    uint256 public depositTime;
    
    constructor(string memory _metadata) {
        owner = msg.sender;
        metadata = _metadata;
        depositTime = block.timestamp;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    // 实现的函数
    function getOwner() external view override returns (address) {
        return owner;
    }
    
    function storeSecret(string memory _secret) external override onlyOwner {
        secret = _secret;
    }
    
    // 抽象函数 - 子类必须实现
    function getBoxType() external pure virtual override returns (string memory);
}

contract BasicDepositBox is BaseDepositBox {
    constructor(string memory _metadata) BaseDepositBox(_metadata) {}
    
    function getBoxType() external pure override returns (string memory) {
        return "Basic";
    }
}

contract TimeLockedDepositBox is BaseDepositBox {
    uint256 public unlockTime;
    
    constructor(string memory _metadata, uint256 _lockDuration) 
        BaseDepositBox(_metadata) 
    {
        unlockTime = block.timestamp + _lockDuration;
    }
    
    modifier timeUnlocked() {
        require(block.timestamp >= unlockTime, "Still locked");
        _;
    }
    
    // 重写父合约函数,添加时间锁
    function getSecret() external view override onlyOwner timeUnlocked 
        returns (string memory) 
    {
        return super.getSecret();
    }
    
    function getBoxType() external pure override returns (string memory) {
        return "Time-Locked";
    }
}

contract VaultManager {
    struct BoxInfo {
        address boxAddress;
        string boxType;
        string metadata;
    }
    
    mapping(address => BoxInfo[]) public userBoxes;
    
    function createTimeLockedBox(string memory _metadata, uint256 _lockDuration) 
        external returns (address) 
    {
        // 创建新合约
        TimeLockedDepositBox newBox = new TimeLockedDepositBox(_metadata, _lockDuration);
        
        // 转移所有权
        newBox.transferOwnership(msg.sender);
        
        // 记录信息
        userBoxes[msg.sender].push(BoxInfo({
            boxAddress: address(newBox),
            boxType: "Time-Locked",
            metadata: _metadata
        }));
        
        return address(newBox);
    }
    
    // 通过接口与保管箱交互
    function storeSecret(address boxAddress, string memory secret) external {
        IDepositBox(boxAddress).storeSecret(secret);
    }
}