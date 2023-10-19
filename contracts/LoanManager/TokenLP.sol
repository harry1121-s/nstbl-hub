// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenLP is ERC20 {
    address public loanManager;
    address public admin;

    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
    event LoanManagerChanged(address indexed oldLoanManager, address indexed newLoanManager);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier authorizedCaller() {
        require(msg.sender == loanManager, "Token: LoanManager unAuth");
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
        loanManager = msg.sender;
        emit AdminChanged(address(0), admin);
        emit LoanManagerChanged(address(0), loanManager);
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

    function setLoanManager(address _loanManager) external onlyAdmin {
        require(_loanManager != address(0), "LP: invalid Address");
        address oldLoanManager = loanManager;
        loanManager = _loanManager;
        emit LoanManagerChanged(oldLoanManager, loanManager);
    }

    function setAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0), "LP: invalid Address");
        address oldAdmin = admin;
        admin = _admin;
        emit AdminChanged(oldAdmin, admin);
    }
}
