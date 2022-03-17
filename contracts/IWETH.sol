pragma solidity >=0.8.0;

import '@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol';

interface IWETH is IERC20Minimal {
    function deposit() external payable;
}
