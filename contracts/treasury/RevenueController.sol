// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// TreasurySotrage
import "../../interfaces/ITreasuryStorage.sol";

contract RevenueController is AccessControl {
    using SafeERC20 for IERC20;

    IERC20 capl;
    // treasury storage contract, similar to the vault contract.
    // all principal must go back to the treasury, profit stays here.
    address treasuryStorage;

    // tokens allowed to be deposited into the treasury, must be updatable
    address[] accessTokens;

    // block counts per day
    uint256 blocksPerDay = 1 days / 6; // this value comes from a block in polygon chain is generated every 6 seconds.

    // last alloc block per each access token
    mapping(address => uint256) LastRequestedBlocks;

    constructor(address _capl, address _treasuryStorage) {
        capl = IERC20(_capl);
        treasuryStorage = _treasuryStorage;
    }

    /**
        @dev - this function sends the principal back to the storage contract via a function called treasuryStorage.returnPrincipal (to be implemented).
             - the profit remains in the revenue controller contract to be distributed by getCAPLAlloc function below.
     */
    function treasuryIncome(
        address _token,
        uint256 _principal,
        uint256 _profit
    ) external {
        // call the treasuryStorage's returnPrincipal function
        ITreasuryStorage(treasuryStorage).returnPrincipal(
            msg.sender,
            _token,
            _principal
        );

        // the profit remains here
        IERC20(_token).safeTransfer(address(this), _profit);

        // set the last distribution block
        LastRequestedBlocks[_token] = block.number;
    }

    /**
        @dev - this function calculates the amount of CAPL to distribute to the treasury storage contract:
             -  current CAPL balance / 30 days = transfer amount.
     */
    function getTokenAlloc(address _token) external {
        // get the access token balance
        uint256 balance = IERC20(_token).balanceOf(address(this));
        // get the user position
        IUserPositions.UserPosition memory userPosition = ITreasuryStorage(
            treasuryStorage
        ).getUserPosition(_token, msg.sender);

        // get amount per block
        uint256 allocPerBlock = balance / (blocksPerDay * 30);
        // get passed block count for calcualtion of distribution
        uint256 allocBlocks = block.number - userPosition.lastAllocRequestBlock;
        // get total amount to distribute
        uint256 allocAmount = allocPerBlock * allocBlocks;

        // update user state(in this case - the profit) in the storage
        ITreasuryStorage(treasuryStorage).setUserPosition(
            _token,
            msg.sender,
            allocAmount,
            block.number
        );

        // get the distributable access token amount
        IERC20(_token).approve(address(this), allocAmount);
        IERC20(_token).safeTransferFrom(
            address(this),
            treasuryStorage,
            allocAmount
        );
    }

    /**
        ADMIN FUNCTIONS
        TODO: Add RBAC @dev
    */

    function setTreasuryStorage(address _destination)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        treasuryStorage = _destination;
    }
}
