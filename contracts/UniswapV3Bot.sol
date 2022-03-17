pragma solidity ^0.8.0;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
//import "./IKeeperRegistry.sol";
//import "./KeeperCompatibleInterface.sol";

contract UniswapV3Bot is Ownable {
    uint constant HISTORY_COUNT = 24;

//    IKeeperRegistry public keeperRegistry;
    IUniswapV3Pool public pool;
//    uint public upkeepId;

    int public centerTick;
    int public volaTick;
    uint128 public liquidityAmount;
    int128 public rebalancingAmount;

    constructor(
//        IKeeperRegistry keeperRegistry_,
        IUniswapV3Pool pool_
//        uint32 gasLimit
    ) Ownable()
    {
//        keeperRegistry = keeperRegistry_;
        pool = pool_;

//        bytes memory checkData;
//        upkeepId = keeperRegistry.registerUpkeep(
//            address(this), // target
//            gasLimit,
//            msg.sender, // admin (can withdrawFunds)
//            checkData
//        );

        (centerTick, volaTick) = calcStatistics();
    }

    function withdrawAll() onlyOwner external {
        _removeLiquidity();

        IERC20Minimal token0 = IERC20Minimal(pool.token0());
        IERC20Minimal token1 = IERC20Minimal(pool.token1());

        uint balance0 = token0.balanceOf(address(this));
        uint balance1 = token1.balanceOf(address(this));
        if (balance0 > 0) {
            token0.transfer(msg.sender, balance0);
        }
        if (balance1 > 0) {
            token1.transfer(msg.sender, balance1);
        }
    }

    function rebalance() onlyOwner external {
        (int newCenterTick, int newVolaTick) = calcStatistics();
        _rebalance(newCenterTick, newVolaTick);
    }

//    function checkUpkeep(bytes calldata checkData) external view override
//    returns (
//        bool upkeepNeeded,
//        bytes memory performData
//    ) {
//        (upkeepNeeded,,) = _rebalanceNeeded();
//    }
//
//    function performUpkeep(bytes calldata performData) external override {
//        (bool upkeepNeeded, int newCenterTick, int newVolaTick) = _rebalanceNeeded();
//        require(upkeepNeeded, "upkeep not needed");
//        _rebalance(newCenterTick, newVolaTick);
//    }

    function calcStatistics() public view returns (int, int) {
        // https://docs.uniswap.org/protocol/reference/core/UniswapV3Pool#observe
        uint32[] memory secondsAgos = new uint32[](HISTORY_COUNT + 1);
        for (uint32 i = 0; i < HISTORY_COUNT + 1;) {
            secondsAgos[secondsAgos.length - 1 - i] = 60 * 60 * i + 60;
            unchecked { ++i; }
        }

        // https://docs.uniswap.org/protocol/concepts/V3-overview/oracle
        int64[] memory ticks = new int64[](HISTORY_COUNT);
        (int56[] memory tickCumulatives, ) = pool.observe(secondsAgos);

        for (uint i = 0; i < HISTORY_COUNT;) {
            ticks[i] = (tickCumulatives[i + 1] - tickCumulatives[i]) / (int32(secondsAgos[i]) - int32(secondsAgos[i + 1]));
            unchecked { ++i; }
        }

        int vola = 0;
        for (uint i = 0; i < HISTORY_COUNT - 1;) {
            vola += _abs(ticks[i + 1] - ticks[i]);
            unchecked { ++i; }
        }
        vola = vola / int(HISTORY_COUNT);

        return (ticks[ticks.length - 1], 1 + vola);
    }

    function calcLiquidityRange(int centerTick, int volaTick) public view returns (int24, int24) {
        int volaScale = 24;
        return (int24(centerTick - volaScale * volaTick), int24(centerTick + volaScale * volaTick));
    }

    function calcRebalancingLiquidityRange(int centerTick, int volaTick) public view returns (int24, int24) {
        int volaScale = 24;
        return (int24(centerTick - volaScale * volaTick), int24(centerTick + volaScale * volaTick));
    }

    // private

//    function _rebalanceNeeded() private view returns (bool, int, int) {
//        (int newCenterTick, int newVolaTick) = calcStatistics();
//
//        if (_abs(centerTick - newCenterTick) < 10 &&
//            _abs(volaTick - newVolaTick) < 10) {
//            return (false, 0, 0);
//        }
//
//        return (true, newCenterTick, newVolaTick);
//    }

    function _removeLiquidity() private {
        (int24 tickLower, int24 tickUpper) = calcLiquidityRange(centerTick, volaTick);

        if (liquidityAmount > 0) {
            pool.burn(tickLower, tickUpper, liquidityAmount);
            pool.collect(
                address(this),
                tickLower, tickUpper,
                type(uint128).max, type(uint128).max
            );
            liquidityAmount = 0;
        }
    }

    function _rebalance(int newCenterTick, int newVolaTick) private {
        _removeLiquidity();

//        _addKeeperFundsIfNeeded();

        uint128 newLiquidityAmount = 0;

        (int24 tickLower, int24 tickUpper) = calcLiquidityRange(newCenterTick, newVolaTick);
        bytes memory data;
        pool.mint(
            address(this),
            tickLower, tickUpper,
            newLiquidityAmount, data
        );

        centerTick = newCenterTick;
        volaTick = newVolaTick;
        liquidityAmount = newLiquidityAmount;
    }

//    function _addKeeperFundsIfNeeded() private {
//        (
//        address target,
//        uint32 executeGas,
//        bytes memory checkData,
//        uint96 balance,
//        address lastKeeper,
//        address admin,
//        uint64 maxValidBlocknumber
//        ) = keeperRegistry.getUpkeep(upkeepId);
//    }

    function _abs(int x) private view returns (int) {
        return x > 0 ? x : -x;
    }
}
