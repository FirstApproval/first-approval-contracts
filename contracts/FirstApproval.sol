// SPDX-License-Identifier: NONE
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";


contract FirstApproval is Ownable, ERC20Capped, ERC20Burnable, ERC20Permit {
    event FeeCollected(address indexed from, address indexed to, uint256 amount);
    event SettingsSet(address indexed treasury, uint256 feeNumerator, uint256 burnNumerator);

    uint256 public constant MAX_SUPPLY = 100 * 1_000_000 * 10**18;
    uint256 public constant DENOMINATOR = 10_000;  // 100% = 10000, 1%=100
    uint256 public constant MAX_FEE_NUMERATOR = 100;  // 1%
    uint256 public constant MAX_BURN_NUMERATOR = 100;  // 1%

    // put all settings in one storage slot to save gas on reading
    //        address treasury;  // 160 bits
    //        uint48 feeNumerator;  // 48 bits
    //        uint48 burnNumerator;  // 48 bits
    // _settings = treasury << (48+48) + feeNumerator << 48 + burnNumerator
    // read more - https://medium.com/@novablitz/storing-structs-is-costing-you-gas-774da988895e
    uint256 public _settings;

    /// @notice set token settings (onlyOwner call)
    /// @param treasury treasury address to collect fee (not zero if feeNumerator not zero)
    /// @param feeNumerator fee numerator denominated by 10000 (max 1%)
    /// @param burnNumerator burn numerator denominated by 10000 (max 1%)
    function setSettings(
        address treasury,
        uint256 feeNumerator,
        uint256 burnNumerator
    ) external onlyOwner {
        if (feeNumerator > 0) {
            require(feeNumerator <= MAX_FEE_NUMERATOR, "too big fee");  // note: feeNumerator < type(uint48).max
            require(treasury != address(0), "empty treasury");
        }
        require(burnNumerator <= MAX_BURN_NUMERATOR, "too big burn");  // note: burnNumerator < type(uint48).max
        _settings =
            (uint256(uint160(treasury)) << (48+48)) +
            (feeNumerator << 48) +
            burnNumerator;
        emit SettingsSet(treasury, feeNumerator, burnNumerator);
    }

    /// @notice read token settings
    /// @return treasury treasury address to collect fee
    /// @return feeNumerator fee numerator denominated by 10000
    /// @return burnNumerator burn numerator denominated by 10000
    function settings() public view returns(address treasury, uint256 feeNumerator, uint256 burnNumerator) {
        uint256 currentSettings = _settings;  // read storage once
        treasury = address(uint160(currentSettings >> (48 + 48)));
        feeNumerator = (currentSettings >> 48) & type(uint48).max;
        burnNumerator = currentSettings & type(uint48).max;
    }

    constructor()
        ERC20("FirstApproval", "FA")
        ERC20Capped(MAX_SUPPLY)
        ERC20Permit("FirstApproval")
    {}  // all initialization is done in parent contracts

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) {
        (address treasury, uint256 feeNumerator, uint256 burnNumerator) = settings();
        if (feeNumerator > 0) {
            uint256 feeAmount = amount * feeNumerator / DENOMINATOR;
            super._transfer(from, treasury, feeAmount);
            emit FeeCollected(from, treasury, feeAmount);
        }
        if (burnNumerator > 0) {
            uint256 burnAmount = amount * burnNumerator / DENOMINATOR;
            super._burn(from, burnAmount);
        }
        super._transfer(from, to, amount);
    }

    /// @notice mint amount of tokens to the balance of account (onlyOwner, totalSupply <= MAX_SUPPLY)
    /// @param account account to receive tokens
    /// @param amount amount of tokens to mint
    function mint(address account, uint amount) onlyOwner external {
        _mint(account, amount);
    }

    function _mint(address _account, uint _amount) internal virtual override(ERC20Capped, ERC20) {
        super._mint(_account, _amount);
    }
}
