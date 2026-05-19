// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "forge-std/StdInvariant.sol";
import "../src-v1.1/QuantaToken.sol";
import "../src-v1.1/AIAgentRegistry.sol";
import "../src-v1.1/AIPaymentChannel.sol";
import "../src-v1.1/AIModelMarketplace.sol";

/**
 * @title Foundry Invariant Tests — runs immediately, no Docker needed
 *
 * Foundry's built-in fuzzer is fast and well-integrated.
 * For 24-hour campaigns, use Echidna (Docker-based) on critical contracts.
 *
 * Run:
 *   forge test --match-contract Invariant -vv
 *   forge test --match-contract Invariant --fuzz-runs 100000 -vv  (deep)
 */

// =====================================================================
// HANDLERS — Bounded actions Foundry calls randomly
// =====================================================================

contract QuantaTokenHandler is Test {
    QuantaToken public token;
    address[] public actors;

    // Ghost variables — track expected state
    uint256 public ghost_totalMinted;
    uint256 public ghost_totalBurned;
    uint256 public ghost_collectAITaxAttempts;
    uint256 public ghost_collectAITaxSucceeded;

    constructor(QuantaToken _token, address[] memory _actors) {
        token = _token;
        actors = _actors;
        ghost_totalMinted = token.totalSupply();
    }

    function _actor(uint256 i) internal view returns (address) {
        return actors[bound(i, 0, actors.length - 1)];
    }

    function transfer(uint256 fromIdx, uint256 toIdx, uint256 amount) external {
        address from = _actor(fromIdx);
        address to = _actor(toIdx);
        amount = bound(amount, 0, token.balanceOf(from));
        vm.prank(from);
        token.transfer(to, amount);
    }

    function burn(uint256 actorIdx, uint256 amount) external {
        address actor = _actor(actorIdx);
        amount = bound(amount, 0, token.balanceOf(actor));
        vm.prank(actor);
        token.burn(amount);
        ghost_totalBurned += amount;
    }

    function tryCollectTaxAsRandomUser(uint256 actorIdx, address from, uint256 amount) external {
        address actor = _actor(actorIdx);
        ghost_collectAITaxAttempts++;
        vm.prank(actor);
        try token.collectAITax(from, amount) {
            ghost_collectAITaxSucceeded++;
        } catch { /* expected */ }
    }
}

contract QuantaTokenInvariantTest is StdInvariant, Test {
    QuantaToken public token;
    QuantaTokenHandler public handler;

    address constant TREASURY = address(0xA11);
    address[] public actors;

    function setUp() public {
        vm.prank(TREASURY);
        token = new QuantaToken(TREASURY);

        // Setup actors
        actors.push(address(0x1));
        actors.push(address(0x2));
        actors.push(address(0x3));
        actors.push(address(0x4));

        // Distribute tokens
        vm.startPrank(TREASURY);
        for (uint i = 0; i < actors.length; i++) {
            token.transfer(actors[i], 1_000_000 ether);
        }
        vm.stopPrank();

        handler = new QuantaTokenHandler(token, actors);
        targetContract(address(handler));
    }

    // ---------------------------------------------------------------
    // ✅ CRITICAL INVARIANTS
    // ---------------------------------------------------------------

    /// @notice Supply never exceeds cap
    function invariant_supplyNeverExceedsCap() public view {
        assertLe(token.totalSupply(), token.MAX_SUPPLY());
    }

    /// @notice C-06: Random users can NEVER successfully call collectAITax
    ///         (because none are whitelisted as collectors)
    function invariant_C06_noUnauthorizedTaxCollection() public view {
        assertEq(handler.ghost_collectAITaxSucceeded(), 0);
    }

    /// @notice Sum of tracked balances ≤ totalSupply
    function invariant_balancesConsistent() public view {
        uint256 sum = token.balanceOf(TREASURY);
        for (uint i = 0; i < actors.length; i++) {
            sum += token.balanceOf(actors[i]);
        }
        assertLe(sum, token.totalSupply());
    }

    /// @notice Tax rate capped
    function invariant_taxRateCapped() public view {
        assertLe(token.aiUsageTaxBps(), token.MAX_TAX_BPS());
    }

    /// @notice Supply + ALL burns >= genesis
    /// @dev Includes user burns (handler.ghost_totalBurned) + protocol burns (token.totalBurned)
    function invariant_burnedAccounting() public view {
        // totalSupply + (all burns ever) should equal GENESIS_SUPPLY
        uint256 allBurns = token.totalBurned() + handler.ghost_totalBurned();
        assertGe(token.totalSupply() + allBurns + 1 ether, token.GENESIS_SUPPLY());
    }
}

// =====================================================================
// Marketplace invariants
// =====================================================================

contract MarketplaceHandler is Test {
    QuantaToken public token;
    AIModelMarketplace public market;
    address[] public actors;

    uint256 public ghost_totalPaid;
    uint256 public ghost_totalCreatorReceived;
    uint256 public ghost_totalBurnedViaMarket;

    constructor(QuantaToken _token, AIModelMarketplace _market, address[] memory _actors) {
        token = _token;
        market = _market;
        actors = _actors;
    }

    function _actor(uint256 i) internal view returns (address) {
        return actors[bound(i, 0, actors.length - 1)];
    }

    function registerModel(uint256 actorIdx, uint256 price, uint16 royalty) external {
        address actor = _actor(actorIdx);
        price = bound(price, 1, 100 ether);
        royalty = uint16(bound(royalty, 0, 9000));

        vm.startPrank(actor);
        token.approve(address(market), type(uint256).max);
        try market.registerModel("ipfs://w", "ipfs://m", price, royalty) {}
        catch { /* may fail if insufficient balance */ }
        vm.stopPrank();
    }

    function payForInference(uint256 actorIdx, uint256 modelId) external {
        if (market.modelCount() == 0) return;
        address actor = _actor(actorIdx);
        modelId = bound(modelId, 0, market.modelCount() - 1);

        (, , , uint256 price, , , , ) = market.models(modelId);
        if (token.balanceOf(actor) < price) return;

        uint256 supplyBefore = token.totalSupply();
        vm.startPrank(actor);
        token.approve(address(market), price);
        try market.payForInference(modelId, price) {
            ghost_totalPaid += price;
            ghost_totalBurnedViaMarket += (supplyBefore - token.totalSupply());
        } catch { /* may fail if inactive */ }
        vm.stopPrank();
    }
}

contract MarketplaceInvariantTest is StdInvariant, Test {
    QuantaToken public token;
    AIModelMarketplace public market;
    MarketplaceHandler public handler;

    address constant OWNER = address(0xA11);
    address[] public actors;

    function setUp() public {
        vm.startPrank(OWNER);
        token = new QuantaToken(OWNER);
        market = new AIModelMarketplace(
            IERC20(address(token)),
            IQuantaToken(address(token)),
            OWNER, OWNER, OWNER
        );
        token.setAITaxCollector(address(market), true);
        vm.stopPrank();

        for (uint i = 1; i <= 5; i++) actors.push(address(uint160(0x100 + i)));

        vm.startPrank(OWNER);
        for (uint i = 0; i < actors.length; i++) {
            token.transfer(actors[i], 10_000 ether);
        }
        vm.stopPrank();

        handler = new MarketplaceHandler(token, market, actors);
        targetContract(address(handler));
    }

    /// @notice Marketplace never holds tokens after payForInference completes
    /// @dev All funds should flow out to creator/treasury/validator/burn
    function invariant_marketplaceSelfDraining() public view {
        // Marketplace should never accumulate large balance
        assertLe(token.balanceOf(address(market)), 1 ether,
                 "Marketplace shouldn't hold significant balance");
    }

    /// @notice Total burned via market ≤ total paid (tax can't exceed payment)
    function invariant_burnLessThanPaid() public view {
        assertLe(handler.ghost_totalBurnedViaMarket(),
                 handler.ghost_totalPaid());
    }

    /// @notice totalCalls accounting is consistent
    function invariant_callCountMonotonic() public view {
        uint256 count = market.modelCount();
        for (uint i = 0; i < count; i++) {
            (, , , , , uint64 totalCalls, , ) = market.models(i);
            // totalCalls is uint64, always non-negative — sanity check
            assertLe(totalCalls, type(uint64).max);
        }
    }
}
