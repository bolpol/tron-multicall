const TronMulticall = artifacts.require('TronMulticall');
const TronWeb = require('tronweb')
const {
    utils,
    Contract
} = require('ethers')

contract('TronMulticall', ([deployer]) => {
    it('#multicall(#aggregate)', async () => {
        let multicall;
        return TronMulticall.deployed()
            .then(async (instance) => {
                multicall = instance;
                return instance;
            })
            .then(async (multicall) => {
                let target = utils.getAddress(`0x${multicall.address.substring(2)}`)
                let signature = utils.id('getBlockNumber()').substring(0, 10)
                let signature2 = utils.id('getCurrentBlockTimestamp()').substring(0, 10)

                let abiCoder = new utils.AbiCoder()

                const multicallEthers = new Contract(target, TronMulticall.abi)
                let call0 = multicallEthers.interface.encodeFunctionData(
                    "aggregate",
                    [
                        [{ target: target, callData: `${signature}`}],
                    ]
                )
                let call1 = multicallEthers.interface.encodeFunctionData(
                    "aggregate",
                    [
                        [{ target: target, callData: `${signature2}`}],
                    ]
                )

                let results = await multicall.multicall([call0, call1])

                const blockNumberResult = (await multicall.getBlockNumber()).toString()
                const getCurrentBlockTimestampResult = (await multicall.getCurrentBlockTimestamp()).toString()

                let result;
                result = multicallEthers.interface.decodeFunctionResult("aggregate", results[0][0]);
                assert.equal(result.blockNumber.toString(), blockNumberResult, "block number 0")
                assert.equal(abiCoder.decode(["uint"], result.returnData[0]), blockNumberResult, "block number 0")

                result = multicallEthers.interface.decodeFunctionResult("aggregate", results[0][1]);
                assert.equal(result.blockNumber.toString(), blockNumberResult, "block number 1")
                assert.equal(abiCoder.decode(["uint"], result.returnData[0]), getCurrentBlockTimestampResult, "block timestamp 1")
            })
    });
});
