// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;


/// @title TronMulticall - Aggregate results from multiple read-only function calls
/// @author Michael Elliot <mike@makerdao.com>
/// @author Joshua Levine <joshua@makerdao.com>
/// @author Nick Johnson <arachnid@notdot.net>
/// @author Pavlo Bolhar <contact@pironmind.com>


contract TronMulticall {
    struct Call {
        address target;
        bytes callData;
    }

    function aggregate(Call[] calldata calls) public view returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.staticcall(calls[i].callData);
            require(success, "Multicall: call failed");
            returnData[i] = ret;
        }
    }
    
    function aggregateAssambly(Call[] calldata calls) public view returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; ) {
            (, bytes memory result) = aggregateOneAssambly(calls[i].target, calls[i].callData);
            result =  returnData[i];
            unchecked {
                ++i;
            }
        }
    }

    function aggregateOneAssambly(address target, bytes calldata data) public view returns (bool success, bytes memory result) {
        assembly {
            success := staticcall(gas(), target, add(data.offset, 0x20), data.length, 0, 0)
            let size := returndatasize()
            result := mload(0x40)
            mstore(result, size)
            returndatacopy(add(result, 0x20), 0, size)
            switch success
            case 0 {
                revert(add(result, 0x20), size)
            }
        }

        require(success, "Multicall: call failed");  
    }


    // Helper functions
    /// @notice Returns the block hash for the given block number
    /// @param blockNumber The block number
    function getBlockHash(uint256 blockNumber) public view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }

    /// @notice Returns the block number
    function getBlockNumber() public view returns (uint256 blockNumber) {
        blockNumber = block.number;
    }

    /// @notice Returns the block coinbase
    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }

    /// @notice Returns the block difficulty
    function getCurrentBlockDifficulty() public view returns (uint256 difficulty) {
        difficulty = block.prevrandao;
    }

    /// @notice Returns the block timestamp
    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }

    /// @notice Returns the (ETH) balance of a given address
    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }

    /// @notice Returns the block hash of the last block
    function getLastBlockHash() public view returns (bytes32 blockHash) {
        unchecked {
            blockHash = blockhash(block.number - 1);
        }
    }

    /// @notice Gets the base fee of the given block
    /// @notice Can revert if the BASEFEE opcode is not implemented by the given chain
    function getBasefee() public view returns (uint256 basefee) {
        basefee = block.basefee;
    }

    /// @notice Returns the chain id
    function getChainId() public view returns (uint256 chainid) {
        chainid = block.chainid;
    }
    
    /// @notice Returns tron account check for is contract TRC-44
    function isContract(address addr) public view returns (bool result) {
        result = addr.isContract;
    }
    
    /// @notice Returns tron TRC10 token account balance
    function getTokenBalance(address accountAddress, trcToken id) public view returns (uint256 balance){
        balance = accountAddress.tokenBalance(id);
    }
}
