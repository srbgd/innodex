// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.1 <0.9.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {

    address private origin;
    uint256 private TOTAL_SUPPLY = 1000 * 1000 * (10 ** uint256(decimals()));

    struct TransferRecord {
        address from;
        address to;
        uint256 amount;
    }

    TransferRecord[] public recordedTransfers;

    constructor (string memory symbol_) ERC20(symbol_, symbol_) {
        origin = msg.sender;
        _mint(origin, TOTAL_SUPPLY);
    }

    function getOrigin() external view returns(address) {
        return origin;
    }

    function recordTransfer(address to, uint256 amount) external returns(bool) {
        recordedTransfers.push(TransferRecord(msg.sender, to, amount));
        return transfer(to, amount);
    }

    function flushRecords() external {
        delete recordedTransfers;
    }

    function getTransfersCount() external view returns(uint256) {
        return recordedTransfers.length;
    }

}