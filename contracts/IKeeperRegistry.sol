pragma solidity ^0.8.0;

interface IKeeperRegistry {
    function registerUpkeep(
        address target,
        uint32 gasLimit,
        address admin,
        bytes calldata checkData
    ) external returns (uint256 id);

    function addFunds(uint256 id, uint96 amount) external;

    function getUpkeep(uint256 id) external view
    returns (
        address target,
        uint32 executeGas,
        bytes memory checkData,
        uint96 balance,
        address lastKeeper,
        address admin,
        uint64 maxValidBlocknumber
    );
}
