// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IStakeInterface {
    function mint(uint256 amount) external returns(uint);
    function redeem(uint256 amount) external returns(uint);
}

contract HonorStakeManager is Ownable {
    using SafeMath for uint256;

    struct Token {
        uint256 balance;
        address stakeContract;
    }

    address public wbnb;

    mapping(address=>Token) tokens;
    mapping(address=>bool) stakers;

    constructor(address _wbnb) {
        wbnb=_wbnb;
    }
    function setStakeToken(address token,address stake) public onlyOwner {
        tokens[token].stakeContract=stake;
    }



    function deposited(address token,uint256 amount) public {
        require(stakers[msg.sender],"Not Staker");
        tokens[token].balance=tokens[token].balance.add(amount);
        
        if(token==wbnb)
        {
            if(tokens[token].stakeContract!=address(0))
            {
                payable(tokens[token].stakeContract).transfer(amount);
            }
            
        }
        else
        {
            if(tokens[token].stakeContract!=address(0))
            {
                IStakeInterface(tokens[token].stakeContract).mint(amount);
            }
        }
        
    }

    function widthdraw(address to,address token,uint256 amount) public  
    {
        require(stakers[msg.sender],"Not Staker");
        tokens[token].balance=tokens[token].balance.sub(amount);

        if(tokens[token].stakeContract!=address(0))
        {
            IStakeInterface(tokens[token].stakeContract).redeem(amount);
        }

        if(token!=wbnb)
        {
            IERC20(token).transfer(to,amount);
           
        }
        else
        {
            payable(to).transfer(amount);
        }
    }

    function balance(address token) public view returns(uint256) {
        return tokens[token].balance;
    }

    function setStaker(address staker,bool isStaker) public onlyOwner {
        stakers[staker]=isStaker;
    }

    receive() external payable {
        tokens[wbnb].balance=tokens[wbnb].balance.add(msg.value);
        if(tokens[wbnb].stakeContract!=address(0))
        {
            payable(tokens[wbnb].stakeContract).transfer(msg.value);
        }
    }

}