const { expect } = require("chai");
const { ethers } = require("hardhat");
const config = require('../scripts/config')
const hre = require("hardhat");

const daySeconds = 24 * 60 * 60

describe("getters", function () {
    before(async function () {
        this.UniswapV3Bot = await ethers.getContractFactory('UniswapV3Bot');
    });

    beforeEach(async function () {
        const pool = await this.UniswapV3Bot.deploy(
            config.uniswapV3Pool,
        );
        await pool.deployed();
        this.pool = pool;
    });

    describe("calcStatistics", function () {
        it("ok", async function () {
            const result = await this.pool.calcStatistics()
            console.log(result)
            expect(result[0]).to.equal(197842)
            expect(result[1]).to.equal(43)
        });
    })

    describe("calcLiquidityRange", function () {
        it("ok", async function () {
            const result = await this.pool.calcLiquidityRange(10000, 100)
            expect(result[0]).to.equal(7600)
            expect(result[1]).to.equal(12400)
        });
    })
})
