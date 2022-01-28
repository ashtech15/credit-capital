//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ITreasuryShares {
    function mint(address _to, uint256 _amount) external;
}

contract TreasuryStorage is AccessControl {
    using SafeERC20 for IERC20;

    // user Roles for RBAC
    bytes32 public constant REVENUE_CONTROLLER =
        keccak256("REVENUE_CONTROLLER");

    // treasury shares represent a users percentage amount in the treasury pot
    ITreasuryShares treasuryShares;

    struct UserPosition {
        uint256 totalAmount;
        uint256 loanedAmount; // amount that has been taken out of the treasury storage as a loan
        uint256 profit;
        uint256 lastAllocRequestBlock; // track the last block when the profit has distributed from the RevenueController
    }

    // Mapping from user to userpostion of the token
    mapping(address => mapping(address => UserPosition)) UserPositions;

    struct Pool {
        uint256 totalPooled; // total token pooled in the contract
    }

    // pool tracking
    mapping(address => Pool) Pools; // token => pool

    constructor(address _treasuryShares) {
        treasuryShares = ITreasuryShares(_treasuryShares);

        // setup the admin role for the storage owner
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
        Read functions
     */
    function checkIfPoolExists(address _token) public view returns (bool) {
        return Pools[_token].totalPooled > 0;
    }

    function checkIfUserPositionExists(address _user, address _token)
        public
        view
        returns (bool)
    {
        return UserPositions[_user][_token].totalAmount > 0;
    }

    function getUnlockedAmount(address _token, address _user)
        public
        view
        returns (uint256 unlockedAmount)
    {
        UserPosition storage userPosition = UserPositions[_user][_token];
        unlockedAmount = userPosition.totalAmount - userPosition.loanedAmount;
    }

    /**
        This function get the total amount of the access token that the storage has.
     */
    function getTokenSupply(address _token) external view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function getUserPosition(address _token, address _user)
        public
        view
        returns (UserPosition memory)
    {
        return UserPositions[_user][_token];
    }

    /**
        Write functions
     */
    function deposit(
        address _user,
        address _token,
        uint256 _amount
    ) external {
        require(
            TreasuryStorage.checkIfPoolExists(_token),
            "Pool does not exist"
        );

        // update pool info
        Pool storage pool = Pools[_token];
        pool.totalPooled += _amount;

        if (!this.checkIfUserPositionExists(_user, _token)) {
            addUserPosition(_token, _user, _amount);
        } else {
            // update userPosition
            UserPosition storage userPosition = UserPositions[_token][_user];
            userPosition.totalAmount += _amount;
        }

        IERC20(_token).approve(_user, _amount);
        IERC20(_token).safeTransferFrom(_user, address(this), _amount);
    }

    function addUserPosition(
        address _token,
        address _user,
        uint256 _totalAmount
    ) internal {
        UserPositions[_user][_token] = UserPosition({
            totalAmount: _totalAmount,
            loanedAmount: 0,
            profit: 0,
            lastAllocRequestBlock: block.number
        });
    }

    function withdraw(
        address _token,
        address _user,
        uint256 _amount
    ) external {
        require(
            getUnlockedAmount(_token, _user) > _amount,
            "Withdrawn amount exceed the allowance"
        );

        // update userPosition
        UserPosition storage userPosition = UserPositions[_token][_user];
        userPosition.totalAmount -= _amount;

        // update Pool info
        Pool storage pool = Pools[_token];
        pool.totalPooled -= _amount;

        // transfer access token amount to the user
        IERC20(_token).approve(address(this), _amount);
        IERC20(_token).safeTransferFrom(address(this), _user, _amount);
    }

    /**
        @dev - this function transfers _amount to the user and updates the user position to denote the loaned amount and change in contract balance.
     */
    function loan(
        address _token,
        address _user,
        uint256 _amount
    ) external {
        require(
            getUnlockedAmount(_token, _user) > _amount,
            "The amount exceed the treasury balance."
        );

        // update user state
        UserPosition storage userPosition = UserPositions[_user][_token];
        userPosition.loanedAmount += _amount;
        userPosition.totalAmount -= _amount;

        // update the total amount of the access token pooled
        Pools[_token].totalPooled -= _amount;

        IERC20(_token).approve(address(this), _amount);
        IERC20(_token).safeTransferFrom(address(this), _user, _amount);
    }

    function returnPrincipal(
        address _user,
        address _token,
        uint256 _principal
    ) external onlyRole(REVENUE_CONTROLLER) {
        // get the userposition
        UserPosition storage userPosition = UserPositions[_user][_token];
        userPosition.loanedAmount -= _principal;
        userPosition.totalAmount += _principal;

        // update pool's access token amount
        Pools[_token].totalPooled += _principal;
    }

    function setUserPosition(
        address _token,
        address _user,
        uint256 _profit,
        uint256 _lastAllockRequetBlock
    ) external onlyRole(REVENUE_CONTROLLER) {
        UserPosition storage userPosition = UserPositions[_user][_token];
        userPosition.profit += _profit;
        userPosition.totalAmount += _profit;
        userPosition.lastAllocRequestBlock = _lastAllockRequetBlock;
    }

    function updatePool(address _token, uint256 _allocAmount)
        external
        onlyRole(REVENUE_CONTROLLER)
        returns (Pool memory)
    {
        Pool storage pool = Pools[_token];
        pool.totalPooled += _allocAmount;

        return pool;
    }

    function mintTreasuryShares(address _destination, uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        treasuryShares.mint(_destination, _amount);
    }
}
