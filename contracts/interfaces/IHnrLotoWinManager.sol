// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHnrLotoWinManager {
        function checkWinsLottery(uint lotID,address token,uint256 totalRevenue,uint blockStart,uint changeFactor,uint ticketCount) external;
        
}