pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external view
    returns (bool, bytes memory);

    function performUpkeep(bytes calldata performData) external;
}
