// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NSTBLTokenMock is ERC20 {
    address public stakePool;
    address public admin;

    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
    event StakePoolChanged(address indexed oldStakePool, address indexed newStakePool);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier authorizedCaller() {
        require(msg.sender == stakePool, "Token: StakePool unAuth");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Token: Admin unAuth");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol, address _admin) ERC20(_name, _symbol) {
        require(_admin != address(0), "LP: invalid Address");
        admin = _admin;
        _mint(admin, 1e6 * 1e18);
        emit AdminChanged(address(0), admin);
    }

    /*//////////////////////////////////////////////////////////////
                        ACCOUNT MINT/BURN
    //////////////////////////////////////////////////////////////*/

    function mint(address _user, uint256 _amount) external authorizedCaller {
        _mint(_user, _amount);
    }

    function burn(address _user, uint256 _amount) external authorizedCaller {
        _burn(_user, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                               OWNERSHIP
    //////////////////////////////////////////////////////////////*/

    function setStakePool(address _stakePool) external onlyAdmin {
        require(_stakePool != address(0), "LP: invalid Address");
        address oldStakePool = stakePool;
        stakePool = _stakePool;
        emit StakePoolChanged(oldStakePool, stakePool);
    }

    function setAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0), "LP: invalid Address");
        address oldAdmin = admin;
        admin = _admin;
        emit AdminChanged(oldAdmin, admin);
    }
}
