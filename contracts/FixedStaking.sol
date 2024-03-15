// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


interface IStakeManager {
    function deposited(address token,uint256 amount) external;
    function widthdraw(address to,address token,uint256 amount) external;
    function balance(address token) external view returns(uint256);
}

contract FixedStaking is Ownable {
    using SafeMath for uint256;
    
    struct Farm {
        address stakeToken;
        address rewardToken;
        uint256 rewardPerBlock;
        uint256 stakedTotal;
        address stakeManager;
        uint minLock;
    }

    struct UserStat {
        uint256 amount;
        uint lockedBlock;
        uint lastReward;
        uint256 reward;
    }

    Farm[] public allFarms;

    mapping(address=>mapping(uint=>UserStat)) public userFarms;

    function pendingReward(address user,uint farmID) public view returns(uint256) {
        Farm memory farm = allFarms[farmID];
        UserStat memory stat = userFarms[user][farmID];
        return rewardAmount(stat.amount,stat.lastReward,farm.rewardPerBlock);
    }

    function rewardAmount(uint256 amount,uint lastReward,uint256 rewardPerBlock) public view returns(uint256) {
        uint blockCount=block.number - lastReward;

        uint256 reward = amount.mul(rewardPerBlock).mul(blockCount).div(1e18);
        return reward;
    }
    function stakedTotal(uint farmID) public view returns(uint256) {
        return allFarms[farmID].stakedTotal;
    }
    function createFarm(address stake,address reward,uint256 rewardPerBlock,address stakeManager,uint minLock) public onlyOwner {
         Farm memory farm = Farm({
            stakeToken: stake,
            rewardToken: reward,
            rewardPerBlock: rewardPerBlock,
            stakedTotal: 0, 
            stakeManager: stakeManager,
            minLock: minLock
            });
        allFarms.push(farm);
    }

    function setFarm(uint farmID,address stake,address reward,uint256 rewardPerBlock,address stakeManager,uint minLock) public onlyOwner {
        require(farmID<allFarms.length,"No Farm");
        Farm storage farm=allFarms[farmID];
        farm.stakeToken=stake;
        farm.rewardToken=reward;
        farm.minLock=minLock;
        farm.stakeManager=stakeManager;
        farm.rewardPerBlock=rewardPerBlock;
        if(stakeManager!=address(0))
        {
            IERC20(stake).approve(stakeManager,type(uint256).max);
        }
    }

    function setReward(uint farmID,uint256 rewardPerBlock) public onlyOwner {
        require(farmID<allFarms.length,"No Farm");
        Farm storage farm=allFarms[farmID];
        farm.rewardPerBlock=rewardPerBlock;
    }
    function setStakeManager(uint farmID,address manager) public onlyOwner {
        require(farmID<allFarms.length,"No Farm");
        Farm storage farm=allFarms[farmID];
        farm.stakeManager=manager;
        if(manager!=address(0))
        {
            IERC20(farm.stakeToken).approve(manager,type(uint256).max);
        }
    }
    function depositToken(uint farmID,uint256 amount) public {
        require(farmID<allFarms.length,"No Farm");
        Farm storage farm=allFarms[farmID];
        UserStat storage stat=userFarms[msg.sender][farmID];

        stat.lockedBlock=block.number + farm.minLock;

        
        if(stat.amount==0)
        {
            stat.amount=amount;
        }
        else
        {
            uint256 reward=rewardAmount(stat.amount, stat.lastReward, farm.rewardPerBlock);
            stat.reward=stat.reward.add(reward);
            stat.amount=stat.amount.add(amount);

        }
        stat.lastReward=block.number;
        farm.stakedTotal=farm.stakedTotal.add(amount);
    }

    function widthdrawFarm(address user,uint farmID,uint256 amount) private {
        Farm storage farm=allFarms[farmID];

       
        if(farm.stakeManager==address(0))
        {
            IERC20(farm.stakeToken).transfer(user,amount);
        }
        else
        {
            IStakeManager(farm.stakeManager).widthdraw(user,farm.stakeToken, amount);
        }

        farm.stakedTotal=farm.stakedTotal.sub(amount);
    }

    function depositFarm(address user,uint farmID,uint256 amount) private {
        Farm storage farm=allFarms[farmID];
        if(farm.stakeManager==address(0))
        {
            IERC20(farm.stakeToken).transferFrom(user,address(this),amount);
        }
        else
        {
            IERC20(farm.stakeToken).transferFrom(user,farm.stakeManager,amount);

            IStakeManager(farm.stakeManager).deposited(farm.stakeToken,amount);
        }

        farm.stakedTotal=farm.stakedTotal.sub(amount);
    }

    function widthdrawToken(uint farmID,uint256 amount) public {
        require(farmID<allFarms.length,"No Farm");
        Farm storage farm=allFarms[farmID];
        UserStat storage stat=userFarms[msg.sender][farmID];

        require(stat.amount>0 && amount<=stat.amount,"Not Balance");
        require(stat.lockedBlock<=block.number,"Locked Resource");

        uint256 reward=rewardAmount(stat.amount, stat.lastReward, farm.rewardPerBlock);
        stat.reward=stat.reward.add(reward);

        stat.amount=stat.amount.sub(amount);
        stat.lastReward=block.number;
        
        widthdrawFarm(msg.sender, farmID, amount);
    }

   function getFarm(uint farmID) public view returns(address,address,uint256,uint256,uint,address) {
        require(farmID<allFarms.length,"No Farm");
        Farm storage farm=allFarms[farmID];
        return (farm.stakeToken,farm.rewardToken,farm.rewardPerBlock,farm.stakedTotal,farm.minLock,farm.stakeManager);
    }
    function emergencyWidthdrawToken(uint farmID) public {
        require(farmID<allFarms.length,"No Farm");

        UserStat storage stat=userFarms[msg.sender][farmID];
        require(stat.amount>0 ,"Not Balance");

        stat.reward=0;
        uint256 amount=stat.amount;
        stat.lastReward=block.number;

        widthdrawFarm(msg.sender, farmID, amount);
    }
    
    function getAllFarmsLength() public view returns(uint256) {
        return allFarms.length;
    }

    function getUserStakedAmount(address user,uint256[] memory farmIDs) public view returns(uint256[] memory) {
        uint256[] memory amounts=new uint256[](farmIDs.length);
        for(uint i=0;i<farmIDs.length;i++)
        {
            amounts[i]=userFarms[user][farmIDs[i]].amount;
        }
        return amounts;
    }

    function harvestFarm(uint farmID) public {
        require(farmID<allFarms.length,"No Farm");
        Farm storage farm=allFarms[farmID];
        UserStat storage stat=userFarms[msg.sender][farmID];

        if(stat.amount==0)
        {
            require(stat.reward>0,"No Reward");
            IERC20(farm.rewardToken).transfer(msg.sender,stat.reward);
            
        }
        else
        {
            uint256 reward=rewardAmount(stat.amount, stat.lastReward, farm.rewardPerBlock);
            stat.reward=stat.reward.add(reward);
            IERC20(farm.rewardToken).transfer(msg.sender,stat.reward);
        }

        stat.reward=0;
        stat.lastReward=block.number;
    }
}
