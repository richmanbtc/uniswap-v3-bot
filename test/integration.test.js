const { expect } = require("chai");
const { ethers } = require("hardhat");
const config = require('../scripts/config')
const hre = require("hardhat");

const BigNumber = (x) => {
    return hre.ethers.BigNumber.from(x)
};

describe("integraion", function () {
    before(async function () {
        this.UniswapV3Bot = await ethers.getContractFactory('UniswapV3Bot');
    });

    beforeEach(async function () {
        const addresses = await ethers.getSigners()
        this.myAddress = addresses[0]
        this.otherAddress = addresses[1]

        const bot = await this.UniswapV3Bot.deploy(
            config.uniswapV3Pool,
        );
        await bot.deployed();
        this.bot = bot;
    });

    describe("deposit,rebalance,withdraw", function () {
        it("ok", async function () {

            // prepare tokens using uniswap

            const weth = await hre.ethers.getContractAt(
                "IWETH",
                config.weth
            );
            await (await weth.deposit(
                {
                    value: hre.ethers.utils.parseEther('10'),
                }
            )).wait()

            const uniswapV3Router = await hre.ethers.getContractAt(
                "ISwapRouter",
                config.uniswapV3Router
            );
            await (await weth.approve(
                config.uniswapV3Router,
                hre.ethers.utils.parseEther('100'),
            )).wait()
            await (await uniswapV3Router.exactInputSingle(
                {
                    tokenIn: config.weth,
                    tokenOut: config.tokens[0],
                    fee: 3000, // https://etherscan.io/address/0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8#readContract
                    recipient: this.myAddress.address,
                    deadline: 2000000000,
                    amountIn: hre.ethers.utils.parseEther('5'),
                    amountOutMinimum: 1,
                    sqrtPriceLimitX96: 0,
                }
            )).wait()

            console.log('exactInputSingle finished')

            const usdc = await hre.ethers.getContractAt(
                "IERC20Minimal",
                config.tokens[0]
            );

            weth.transfer(this.bot.address, hre.ethers.utils.parseEther('4'));
            usdc.transfer(this.bot.address, 100000 * 1000);

            console.log('usdc balance ' + (await usdc.balanceOf(this.myAddress.address)))
            console.log('weth balance ' + (await weth.balanceOf(this.myAddress.address)))
            console.log('usdc balance bot ' + (await usdc.balanceOf(this.bot.address)))
            console.log('weth balance bot ' + (await weth.balanceOf(this.bot.address)))
            // console.log('lp token balance ' + (await this.pool.balanceOf(this.myAddress.address)))

            await (await this.bot.rebalance()).wait()

            console.log('rebalance finished')
            console.log('usdc balance ' + (await usdc.balanceOf(this.myAddress.address)))
            console.log('weth balance ' + (await weth.balanceOf(this.myAddress.address)))
            console.log('usdc balance bot ' + (await usdc.balanceOf(this.bot.address)))
            console.log('weth balance bot ' + (await weth.balanceOf(this.bot.address)))
            // console.log('lp token balance ' + (await this.pool.balanceOf(this.myAddress.address)))

            await (await this.bot.withdrawAll()).wait()

            console.log('withdrawAll finished')
            console.log('usdc balance ' + (await usdc.balanceOf(this.myAddress.address)))
            console.log('weth balance ' + (await weth.balanceOf(this.myAddress.address)))
            console.log('usdc balance bot ' + (await usdc.balanceOf(this.bot.address)))
            console.log('weth balance bot ' + (await weth.balanceOf(this.bot.address)))
            // console.log('lp token balance ' + (await this.pool.balanceOf(this.myAddress.address)))

        });
    })
})
