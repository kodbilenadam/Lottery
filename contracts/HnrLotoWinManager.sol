// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IHonorLottery.sol";

contract HnrLotoWinManager is Ownable
{
    using SafeMath for uint256;
    IHonorLottery honorLottery;

    mapping(address=>mapping(address=>uint256)) public userWinBalances;
    mapping(uint=>address[]) public winnerUsers;

    uint256[] public prizeFactors;

    constructor(address _honorLottery) {
        honorLottery=IHonorLottery(_honorLottery);
        prizeFactors.push(600); //1.  -- 600
        prizeFactors.push(150); //2.  -- 750
        prizeFactors.push(50);  //3.  -- 780
        prizeFactors.push(25);  //4.  -- 805
        prizeFactors.push(14);  //5.  -- 819
        prizeFactors.push(13);  //6.  -- 832
        prizeFactors.push(11);  //7.  -- 843
        prizeFactors.push(10);  //8.  -- 853
        prizeFactors.push(9);  //9.   -- 862
        prizeFactors.push(8);  //10.  -- 870 

                         // 11-20     -- 900 
        for(uint i=0;i<10;i++)
        {
            prizeFactors.push(3);
        }
    }

    function setPrizeFactor(uint i,uint256 factor) public onlyOwner {
        prizeFactors[i]=factor;
    }
    function getRandomNumber(uint blockNumber,uint256 mod) private view returns(uint)
    {
        bytes32 hashNumber=blockhash(blockNumber);
        uint256 num=uint256(hashNumber);
        return num % mod;
    }

    function sendToBonusPrize(address token,uint256 total,uint256 factor) private {
        uint256 prize = total.mul(factor).div(1000);
        honorLottery.addBonusPrize(token,prize);
    }
   
    function checkWinsLottery(uint lotID,address token,uint256 totalRevenue,uint blockStart,uint changeFactor,uint ticketCount) public {
        require(msg.sender==address(honorLottery),"Not Lottery");

        uint start=blockStart + 10;

        //Win Number 1
        uint mod= ticketCount*changeFactor/10;
        uint256 bonusPrize=0;

        for(uint x=0;x<10;x++)
        {
            bonusPrize=bonusPrize + checkWinNumbers(lotID, token, start + x  , mod, totalRevenue, ticketCount, prizeFactors[x]);
        }
       
        for(uint y=10;y<20;y++)
        {
            uint win=getRandomNumber(start+y, ticketCount);
            address user=honorLottery.getLotteryUser(lotID, win);
            winnerUsers[lotID].push(user);
            uint256 prize=totalRevenue.mul(prizeFactors[y]).div(1000);
            userWinBalances[user][token]=userWinBalances[user][token].add(prize);
        }
        
        if(bonusPrize>0)
            sendToBonusPrize(token,totalRevenue,bonusPrize);
    }

    function checkWinNumbers(uint lotID,address token,uint blockNum,uint mod,uint256 totalRevenue,uint ticketCount,uint256 prizeFactor) private returns(uint256 bonus) {
        uint win=getRandomNumber(blockNum, mod);
        if(win>ticketCount)
        {
            bonus=prizeFactor;
            winnerUsers[lotID].push(address(0));
        }
        else
        {
            address user=honorLottery.getLotteryUser(lotID, win);
            winnerUsers[lotID].push(user);
            uint256 prize=totalRevenue.mul(prizeFactor).div(1000);
            userWinBalances[user][token]=userWinBalances[user][token].add(prize);
            bonus=0;
        }
    }

    function getUserBalance(address user,address token) public view returns(uint256) {
        return userWinBalances[user][token];
    }

    function widthdrawUserBalance(address user,address token) external {
        require(msg.sender == address(honorLottery),"Only Honor Lottery" );
        userWinBalances[user][token]=0;
    }
}