// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface Lottery {
    function playGame(uint lotteryID,uint ticketCount) external;
    function getLotteryToken(uint lotteryID) external view returns(address)
}
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address) external returns(uint256);
}
contract LotteryDealer is Ownable
{
    using SafeMath for uint256;

    Lottery public _adminLottery;
    address payable private constant  WETH ="";
    struct LotteryToken
    {
        bool access;
        bool isCreateLottery;
        uint8 revenue;
        uint totalTicket;
    }

    mapping(address=>LotteryToken) private _registeredTokens;

    mapping(address=>uint256) private _balance;

    constructor(address lottery,address weth) public {
        _adminLottery=Lottery(lottery);
        _weth=IWETH(weth);
    }

    function paidGame(address token,uint256 paid) external returns(uint256) {
        require(msg.sender==_adminLottery,"Not Admin");
        uint256 revenue=uint256(_registeredTokens[token].revenue);

        uint256 pay=paid.mul(revenue).div(100);
        _balance[token]=_balance[token].add(pay);
        return paid.sub(pay);
    }

    function playGame(address token,uint lotteryID,uint ticketCount) public {
      
        require(_registeredTokens[token].access,"Not Token Access");
        _adminLottery.playGame(lotteryID,ticketCount);
    }
    
    function playGameWithETH(uint lotteryID,uint ticketCount) payable public {
        require(_registeredTokens[WETH].access,"Not Token Access");
        uint256 ETHAmount = msg.value;
        //create WBNB from BNB
        if (msg.value != 0) {
        IWETH(WETH).deposit{ value: ETHAmount }();
        }
        require(
        IWETH(WETH).balanceOf(address(this)) >= ETHAmount,
        "BNB not deposited"
        );
    }

    function setTokenAccess(address token,bool access,bool isCreate,uint8 revenue) public {
        require(msg.sender==address(_adminLottery),"Not Admin");
        registeredTokens[token].access=access;
        _registeredTokens[isCreateLottery]=isCreate;
        _registeredTokens[revenue]=revenue;
    }

    function widthdrawBalance(address token) public onlyOwner {
        
    }

    function getBalance(address token) public view onlyOwner {
        return _balance[token];
    }


}