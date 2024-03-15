// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHonorLottery {
    function getLotteryUser(uint lotID,uint userID) external view returns(address);
    function addBonusPrize(address token,uint256 prize) external;

}