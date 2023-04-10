// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall {
	function multicall(bytes[] calldata data) public view returns (bytes[] memory results) {
		results = new bytes[](data.length);
		for (uint256 i = 0; i < data.length; i++) {
			(bool success, bytes memory result) = address(this).staticcall(data[i]);

			if (!success) {
				// Next 5 lines from https://ethereum.stackexchange.com/a/83577
				if (result.length < 68) revert();
				assembly {
					result := add(result, 0x04)
				}
				revert(abi.decode(result, (string)));
			}

			results[i] = result;
		}
	}
}

/// @title TronMulticall - Aggregate results from multiple read-only function calls
/// @author Michael Elliot <mike@makerdao.com>
/// @author Joshua Levine <joshua@makerdao.com>
/// @author Nick Johnson <arachnid@notdot.net>
/// @author Pavlo Bolhar <contact@pironmind.com>

contract TronMulticall is Multicall {
	struct Call {
		address target;
		bytes callData;
	}

	function aggregate(Call[] calldata calls) external view returns (uint256 blockNumber, bytes[] memory returnData) {
		blockNumber = block.number;
		returnData = new bytes[](calls.length);
		bool success;
		bytes memory ret;
		for (uint256 i; i < calls.length; ) {
			(success, ret) = calls[i].target.staticcall(calls[i].callData);
			require(success, "Multicall: call failed");
			returnData[i] = ret;
			unchecked { i++; }
		}
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
	/// @notice Doesnt work
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
