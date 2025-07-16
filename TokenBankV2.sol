// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// 导入 OpenZeppelin 提供的 ERC20 标准合约

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IERC20Receiver {

​    function tokensReceived(

​        address from,

​        address fromContract,

​        uint256 amount

​    ) external;

}

contract CallBack is ERC20{

​     address tokenAddress;

​     constructor(uint256 initialSupply) ERC20("SuperToken", "SPT"){

​        // 通过 _mint 函数铸造初始供应量的代币到部署合约的地址

​        _mint(msg.sender, initialSupply);

​    }

​         

​    function transferWithCallback(address _to,uint256 amount) public returns(bool) {

​        //  调用父合约的转账

​        bool success =  super.transfer(_to, amount);

​        require(success, "Transfer failed");

​         // 如果接收方是合约地址，尝试调用tokensReceived

​        if (isContract(_to)) {

​            try IERC20Receiver(_to).tokensReceived(msg.sender, address(this), amount) {

​                // 回调成功

​            } catch {

​                //回调失败记录事件

​                emit CallbackFailed(_to);

​            }

​        }

​        return true;

​    }

​    // 回调失败事件

​    event CallbackFailed(address indexed target); 

​    //判断是否是合约地址

​    function isContract(address _to) public  view returns(bool){

​            return _to.code.length > 0;

​    }

}

// 扩展的ERC20接口，包含transferWithCallback

interface IERC20WithCallback is IERC20 {

​    function transferWithCallback(

​        address recipient,

​        uint256 amount,

​        bytes calldata data

​    ) external returns (bool);

}

// 新建一个ERC20标准的代币合约

contract SuperToken is ERC20 {

​    constructor(uint256 initialSupply) ERC20("SuperToken", "SPT"){

​        // 通过 _mint 函数铸造初始供应量的代币到部署合约的地址

​        _mint(msg.sender, initialSupply);

​    }

}

// 创建TokenBank合约，允许用户存入跟取出对应的token

contract TokenBank{ // 启用 SafeERC20 扩展

​    // 代币合约地址

​    IERC20 public immutable token;

​       // 记录每个地址的存款余额

​    mapping(address => uint256) public balances;

​    

​    // 存款事件

​    event Deposited(address indexed user, uint256 amount);

​    

​    // 取款事件

​    event Withdrawn(address indexed user, uint256 amount);

​    // 构造函数，传入要支持的ERC20代币地址

​    constructor(address _token) {

​        token = IERC20(_token);

​    }

​    //存款 

​    function deposit(uint256 amount) internal   {

​        require(amount > 0, "Amount must be greater than 0");

​        

​        // 从用户转账代币到合约

​        bool success = token.transferFrom(msg.sender, address(this), amount);

​        require(success, "Transfer failed");

​        

​        // 更新用户余额

​        balances[msg.sender] += amount;

​        emit Deposited(msg.sender, amount);

​    }

​     // 取款

​    function withdraw(uint256 amount) external {

​        require(amount > 0, "Amount must be greater than 0");

​        require(balances[msg.sender] >= amount, "Insufficient balance");

​        

​        // 更新用户余额

​        balances[msg.sender] -= amount;

​        

​        // 将代币从银行合约转移回用户

​        bool success = token.transfer(msg.sender, amount);

​        require(success, "Token transfer failed");

​    }

 

}

contract TokenBankV2 is TokenBank,IERC20Receiver{

​    CallBack public immutable newToken;

​    constructor(address _tokenAddress) TokenBank(_tokenAddress){

​        newToken = CallBack(_tokenAddress);

​    } 

​    function transferWithCallback(uint256 amount) public {

​        newToken.transferWithCallback(address(this),amount);

​    }

​    //用户可以直接调用 transferWithCallback 将 扩展的 ERC20 Token 存入到 TokenBankV2 中

​    function tokensReceived(address from,address fromContract,uint256 amount) external virtual{

​        super.deposit(amount);

​    }

}