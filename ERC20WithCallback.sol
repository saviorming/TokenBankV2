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