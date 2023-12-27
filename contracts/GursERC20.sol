// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC20Drop.sol";

contract GursERC20 is ERC20Drop {
    address public constant TEAM = 0x225FdaD7515F118935511C623a588CE4a654c989;
    address public constant MARKETING = 0x06eDAEE88e79FD435505a6A582Bd1CFf678425A8;
    address public constant OG_AIRDROP_LP = 0xf071441db1AE02fadB44B71c25b70538De86b92b;
    uint256 private constant MIN_CLAIM_AMOUNT = 100 ether;
    uint256 private constant TOTAL_SUPPLY = 69_000_000_000 ether;
    uint256 private constant FIRST_CLAIMANT_AMOUNT = 9_420_000 ether;
    uint256 private constant END_AMOUNT = 100 ether;
    uint256 private constant FIRST_PHASE_CLAIMERS = 5_000;
    uint256 private constant MAX_CLAIMANTS = 152_932;

    /// @dev The total number of tokens to be claimed.
    uint256 private immutable _totalTokensClaimable;

    /// @dev The index of the last claimed token.
    uint256 private _lastClaimedIndex = 1;

    /// @dev Map of addressess that have claimed.
    mapping(address => bool) private _hasClaimed;

    /// @dev Constructor
    /// @param _defaultAdmin The default admin of the contract.
    /// @param _name The name of the token.
    /// @param _symbol The symbol of the token.
    /// @param _primarySaleRecipient The address to receive the funds from the primary sale.
    constructor(address _defaultAdmin, string memory _name, string memory _symbol, address _primarySaleRecipient)
        ERC20Drop(_defaultAdmin, _name, _symbol, _primarySaleRecipient)
    {
        _mint(TEAM, (2 * TOTAL_SUPPLY) / 100);
        _mint(MARKETING, (3 * TOTAL_SUPPLY) / 100);
        _mint(OG_AIRDROP_LP, (65 * TOTAL_SUPPLY) / 100);
        _totalTokensClaimable = (30 * TOTAL_SUPPLY) / 100;
    }

    /// @dev Claims tokens for the next claimer.
    /// @param _receiver The address to receive the tokens.
    /// @param _quantity The number of tokens to claim.
    /// @param _currency The currency used to pay for the tokens.
    /// @param _pricePerToken The price per token.
    /// @param _allowlistProof The merkle proof for the claimer.
    /// @param _data The data to pass to the hooks.
    function claim(
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        AllowlistProof calldata _allowlistProof,
        bytes memory _data
    ) public payable override {
        require(!_hasClaimed[msg.sender], "Already claimed");
        require(_lastClaimedIndex < MAX_CLAIMANTS, "All tokens claimed");
        _quantity = _calculateClaimAmount(_lastClaimedIndex);

        super.claim(_receiver, _quantity, _currency, _pricePerToken, _allowlistProof, _data);

        _hasClaimed[msg.sender] = true;

        unchecked {
            ++_lastClaimedIndex;
        }
    }

    /// @dev Calculates the claim amount for the given index.
    /// @param _index The index of the claimant.
    /// @return The claim amount.
    function _calculateClaimAmount(uint256 _index) private pure returns (uint256) {
        require(_index > 0 && _index <= MAX_CLAIMANTS, "Invalid claimer index");

        if (_index > FIRST_PHASE_CLAIMERS) {
            return END_AMOUNT;
        } else {
            uint256 decrementPerClaimer = (FIRST_CLAIMANT_AMOUNT - END_AMOUNT) / (FIRST_PHASE_CLAIMERS - 1);
            uint256 claimAmount = FIRST_CLAIMANT_AMOUNT - decrementPerClaimer * (_index - 1);
            return claimAmount;
        }
    }

    /// @dev Mints tokens to the given account.
    /// @param account The account to mint tokens to.
    /// @param amount The amount of tokens to mint.
    function _mint(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: mint to the zero address");
        require(totalSupply() + amount <= TOTAL_SUPPLY, "ERC20: mint amount exceeds cap");

        super._mint(account, amount);
    }
}
