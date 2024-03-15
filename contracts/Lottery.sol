// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface ILotoWinManager {
        function checkWinsLottery(uint lotID,address token,uint256 totalRevenue,uint blockStart,uint changeFactor,uint ticketCount) external;
        function widthdrawUserBalance(address user,address token) external;
        function getUserBalance(address user,address token) external view returns(uint256);
}

interface ILotteryTicket {
    function mintTicket(address user,uint256 amount) external;
    function burnTicket(address user,uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}
interface IStakeManager {
    function deposited(address token,uint256 amount) external;
    function widthdraw(address to,address token,uint256 amount) external;
    function balance(address token) external view returns(uint256);
}

interface ILotteryDealer {
    function paidGame(address token,uint256 paid) external;
}

contract Lottery is Ownable
{
    using SafeMath for uint256;

    ILotteryTicket public ticket;
    IStakeManager public stakeManager;
    ILotoWinManager public winManager;

    struct Lottery  {
        address baseToken;
        address[] users;
        uint32[] userTickets;
        uint256 ticketPrice;
        uint256 finishPrize;
        uint256 totalPrice;
        uint finishBlock;
        uint256 bonusPrice;
        uint8 freeTicketPrice;
        uint8 changeFactor;
        bool prizeFinish;
        bool checkFinish;
    }

    uint public maxTicket=250;
    uint8 public revenueRatio;
    Lottery[] public lotteries;
    uint256 public bonusTicketRatio;

    struct UserLottery {
        uint32 userID;
        uint16 ticketCount;
    }

    mapping(address=>mapping(uint=>UserLottery)) public userLotteries;

    address[] _lotteryDealers;

    struct Treasury {
        uint256 bonusPrize;
        uint256 revenue;
    }

    mapping(address=>Treasury) public bonusPrizePools;

    constructor(address _ticket) {
        lotteryTicket=ILotteryTicket(_ticket);
        bonusTicketRatio=1e17;
        revenueRatio=4;
    }

    function getLotteryToken(uint lotteryID) public view returns(address) {
        return lotteries[lotteryID].baseToken;
    }
    function setBonusTicketRatio(uint256 ratio) public onlyOwner {
        bonusTicketRatio=ratio;
    }
    function sendBonusTicket(address user,uint ticketCount) private {
        if(bonusTicketRatio>0)
        {
            lotteryTicket.mintTicket(user, ticketCount*bonusTicketRatio);
        }
    }

    function getTicketCount(uint lotID) public view returns(uint) {
        return lotteries[lotID].userTickets.length;
    }
    function getUserCount(uint lotID) public view returns(uint) {
        return lotteries[lotID].users.length;
    }
    function addBonusPrize(address token,uint256 amount) public {
        require(msg.sender==address(winManager) || msg.sender==owner(),"ERROR ADDBONUS");
        bonusPrizePools[token].bonusPrize=bonusPrizePools[token].bonusPrize.add(amount);
    }

    function sendBonusPrizeToLottery(address token,uint lotID,uint256 amount) public onlyOwner {
        require(token==lotteries[lotID].baseToken,"Not Token");
        require(bonusPrizePools[token].bonusPrize>=amount,"Not Balance");

        bonusPrizePools[token].bonusPrize=bonusPrizePools[token].bonusPrize.sub(amount);
        lotteries[lotID].bonusPrice=lotteries[lotID].bonusPrice.add(amount);
    }
    function checkBonusPrizeFromLottery(address token,uint lotID,uint256 amount) public onlyOwner {
        require(token==lotteries[lotID].baseToken,"Not Token");
        require(lotteries[lotID].bonusPrice>=amount,"Not Balance");

        bonusPrizePools[token].bonusPrize=bonusPrizePools[token].bonusPrize.add(amount);
        lotteries[lotID].bonusPrice=lotteries[lotID].bonusPrice.sub(amount);
    }
    
    function setWinManager(address _winManager) public onlyOwner {
        winManager = IHnrLotoWinManager(_winManager);
    }

    function setStakeManager(address _stakeManager) public onlyOwner {
        stakeManager = IStakeManager(_stakeManager);
    }

    function createLottery(address baseToken,uint256 ticketPrice,uint256 finishPrize,
    uint finishBlock,uint8 freeTicketPrice,uint8 changeFactor,bool prizeFinish) public onlyOwner {

        require(finishBlock>block.number,"ERROR BLOCK");

            Lottery memory newLottery = Lottery({
            baseToken: baseToken,
            users: new address[](0), // Boş bir kullanıcı dizisi oluştur
            userTickets: new uint32[](0), // Boş bir bilet dizisi oluştur
            ticketPrice: ticketPrice,
            finishPrize: finishPrize,
            totalPrice: 0, // Başlangıçta toplam fiyatı 0 olarak ayarla
            finishBlock: finishBlock,
            bonusPrice: 0, // Başlangıçta bonus fiyatı 0 olarak ayarla
            freeTicketPrice: freeTicketPrice,
            changeFactor: changeFactor,
            prizeFinish: prizeFinish,
            checkFinish:false
        });

        lotteries.push(newLottery);

        lotteries[lotteries.length-1].users.push(address(0));
    }

    function getUserLotteryID(address user,uint lotteryID) public view returns(uint32)
    {
        return userLotteries[user][lotteryID].userID;
    }
    function getUserLotteryTicketCount(address user,uint lotteryID) public view returns(uint)
    {
        return uint(userLotteries[user][lotteryID].ticketCount);
    }

    function getTicketTotalPrice(uint256 ticketPrice,uint ticketCount) public pure returns(uint256)
    {
        uint256 total=ticketPrice.mul(ticketCount);
        if(ticketCount>=100)
        {
            return total.mul(8).div(10);
        }
        if(ticketCount>=50)
        {
            return total.mul(9).div(10);
        }
        if(ticketCount>=10)
        {
            return total.mul(95).div(100);
        }
        return total;
    }

    function isLotteryFinished(uint lotID) public view returns(bool) {
        Lottery memory lot = lotteries[lotID];
        if(lot.finishBlock<=block.number)
            return true;
        if(lot.prizeFinish && lot.finishPrize<=lot.totalPrice)
            return true;
        return false;
    }

    function widthdrawRevenue(address token,uint256 amount) public onlyOwner {
        require(bonusPrizePools[token].revenue>=amount,"Not Balance");
        if(address(stakeManager)==address(0))
        {
            IERC20(token).transfer(msg.sender,amount);
        }
        else
        {
            stakeManager.widthdraw(msg.sender, token, amount);
        }
    }

    function widthdrawPrize(address user,address token) public {
        require(address(winManager) != address(0) ,"Not Set Manager");

        uint256 amount = winManager.getUserBalance(user, token);
        require(amount>0,"Not Balance");
        
        if(address(stakeManager)==address(0))
        {
            IERC20(token).transfer(user,amount);
        }
        else
        {
            stakeManager.widthdraw(user, token, amount);
        }
    }
    
//modUserTicket(lotteryID)
    function playUserTickets(address user,uint lotteryID,uint ticketCount) private {
        
        userLotteries[user][lotteryID].ticketCount=userLotteries[user][lotteryID].ticketCount + uint16(ticketCount);        uint32 userID=getUserLotteryID(user, lotteryID);
        
        Lottery storage lottery = lotteries[lotteryID];

        if(userID==0)
        {
            lottery.users.push(user);
            userID=uint32(lottery.users.length-1);
            userLotteries[user][lotteryID].userID=userID;
        }
        uint len=lottery.userTickets.length;
        for(uint i=len;i<(len+ticketCount);i++)
        {
            lottery.userTickets.push(userID);
        }
        sendBonusTicket(user, ticketCount);
    }

    function deposit(address user,address token,uint256 amount) private {
        
        if(address(stakeManager) == address(0))
        {
            IERC20(token).transferFrom(user,address(this),amount);
        }
        else
        {
            IERC20(token).transferFrom(user,address(stakeManager),amount);
            stakeManager.deposited(token, amount);
        }
    }

    function playFreeGame(uint lotteryID,uint ticketCount) public {
        uint count=getUserLotteryTicketCount(msg.sender,lotteryID);
        require((count+ticketCount)<=maxTicket, "Max Ticket 250");

        Lottery storage lottery = lotteries[lotteryID];
        require(!isLotteryFinished(lotteryID),"Lottery Finished");

        uint ticket=uint256(lottery.freeTicketPrice)*uint256(ticketCount)*1e18;
        require(lotteryTicket.balanceOf(msg.sender)>=ticket,"Not Balance");

        lotteryTicket.burnTicket(msg.sender, ticket);
      
        playUserTickets(msg.sender, lotteryID, ticketCount);
        
    }

    function playGame(address user,uint lotteryID,uint ticketCount,uint dealerID) external {
        require(_lotteryDealers[dealerID]==msg.sender,"Not Dealer");
        uint count=getUserLotteryTicketCount(user,lotteryID);
        
        require((count+ticketCount)<=maxTicket, "Max Ticket 250");
        
        Lottery storage lottery = lotteries[lotteryID];
        require(lottery.finishPrize>=lottery.totalPrice || lottery.finishBlock>=block.number,"Lottery Finished");

        uint256 paid=getTicketTotalPrice(lottery.ticketPrice,ticketCount);
        deposit(user,lottery.baseToken,paid);
        paid=ILotteryDealer(_lotteryDealers[dealerID]).paidGame(paid);
        lottery.totalPrice=lottery.totalPrice.add(paid);
        
        playUserTickets(user, lotteryID, ticketCount);

        if(lottery.totalPrice>=lottery.finishPrize && lottery.prizeFinish)
        {
            lottery.finishBlock=block.number;
        }
    }

    function clearLottery(uint lotID) public {
        require(lotID<lotteries.length,"Not LOT ID");
        Lottery storage lot=lotteries[lotID];
        require(lot.checkFinish==true,"Lottery Checked");

        delete lot.users;
        delete lot.userTickets;
    }

    function finishLottery(uint lotID) public onlyOwner {
        
        require(lotID<lotteries.length,"Not LOT ID");

        Lottery storage lot=lotteries[lotID];

        require(lot.finishBlock< (block.number + 100),"Not Finish");
        require(lot.checkFinish==false,"Lottery Checked");
        
        uint256 finishPrice = lot.totalPrice + lot.bonusPrice;
        require(finishPrice>0,"Not Price");
        uint256 revenue=finishPrice * uint256(revenueRatio) / 100;
        uint256 bonusRatio=10 - uint256(revenueRatio);
        uint256 bonus=finishPrice * bonusRatio / 100;
        
        bonusPrizePools[lot.baseToken].bonusPrize=bonusPrizePools[lot.baseToken].bonusPrize.add(bonus);
        bonusPrizePools[lot.baseToken].revenue=bonusPrizePools[lot.baseToken].revenue.add(revenue);

        winManager.checkWinsLottery(lotID, lot.baseToken, finishPrice, lot.finishBlock, lot.changeFactor, lot.userTickets.length);

    }

    function setRevenueRatio(uint8 ratio) public onlyOwner {
        require(ratio<1 && ratio>0,"Max 10");
        revenueRatio=ratio;
    }
}