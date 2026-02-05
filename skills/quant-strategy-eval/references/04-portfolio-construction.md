# Module 4: Portfolio Construction

Optimize how signals translate into positions. Maximize risk-adjusted returns subject to practical
constraints.

Requires: signal data, universe with liquidity characteristics, capital/AUM, and constraint
parameters. If not provided, use sensible defaults and document assumptions.

## Default Constraints (if not specified)

```
Max position size: 5% of portfolio per name
Max sector/segment concentration: 25%
Target turnover: < 200% annualized
Max gross leverage: 2x
Max net exposure: ±20% (for market-neutral), unconstrained (for directional)
Transaction cost: 10 bps for liquid crypto, 5 bps for large-cap equities
```

## Section A: Signal Combination

If multiple signals are available:

1. Compute optimal combination weights using:
   - (a) Equal weighting
   - (b) IC-weighting (weight proportional to each signal's ICIR)
   - (c) Optimized weights via maximizing out-of-sample ICIR using rolling estimation windows

2. Compare combined signal's IC, ICIR, and quantile spread to individual signals.
3. Report signal correlation matrix. Flag redundant pairs (correlation > 0.7).

## Section B: Position Sizing

Implement and compare these approaches:

1. **Linear z-score:** Normalize signal to z-scores, map linearly to position sizes, clip at
   constraints
2. **Rank-based equal risk contribution:** Rank-order positions, size inversely proportional to
   asset volatility
3. **Black-Litterman:** Use signal as a view, combine with equilibrium prior, solve for optimal
   weights
4. **Risk parity across signal groups:** Equal risk budget to long and short books, or to
   signal-defined clusters

For each approach, report:

- Sharpe, Sortino, max drawdown
- Turnover (annualized)
- Average position concentration (Herfindahl index)

### Kelly Fraction Analysis

Compute full Kelly bet size. Report performance at:

- 0.25× Kelly (conservative)
- 0.50× Kelly (moderate)
- 1.00× Kelly (aggressive — include for reference but note it's impractical due to parameter
  uncertainty)

## Section C: Risk Management Overlay

Layer these on top of the chosen position sizing:

1. **Volatility targeting:** Scale positions so ex-ante portfolio vol targets X% annualized. Use
   exponentially weighted vol estimate (halflife = 20 days). Default target: 10% for market-neutral,
   15% for directional.

2. **Drawdown control:**
   - Rolling drawdown exceeds X% → reduce positions by 50%
   - Rolling drawdown exceeds Y% → go to 100% cash
   - Default thresholds: X = 10%, Y = 20%
   - Backtest the impact of these rules

3. **Correlation break detection:** If trailing 20-day cross-asset correlations spike > 2 std devs
   above mean, reduce gross exposure by 50%.

## Section D: Execution Simulation

Model realistic execution:

- Do NOT assume trading at close/open — use VWAP or TWAP assumptions
- Include slippage as a function of trade size relative to ADV:
  `slippage_bps = base_cost + impact_coeff × sqrt(trade_size / ADV)`
- For crypto perps: include funding rate costs/income

Report:

- Gross vs net Sharpe after execution costs
- **Breakeven cost:** at what cost per trade does Sharpe drop below 0.5?

## Section E: Optimal Portfolio Report

Recommend the best portfolio construction approach. Provide:

- Final Sharpe, Sortino, Calmar (net of costs)
- Position sizing methodology and parameters
- Risk management rules and thresholds
- Rebalance frequency recommendation
- Estimated capacity: at what AUM does Sharpe degrade by 25%?
