# Module 3: Overfitting Tribunal

Adversarial review to find overfitting. The goal is to **break** the strategy. If it survives these
attacks, it's probably real.

Requires: number of strategy variations tested (including all parameter sweeps, signal variations,
universe changes) and number of free parameters. Ask the user if not provided — this is critical.

## Attack 1: Multiple Comparisons Adjustment

1. Compute the **deflated Sharpe ratio** (Bailey & López de Prado, 2014) given the number of trials.

   ```
   E[max Sharpe from N trials] ≈ individual_sharpe × (1 + sqrt(2 × ln(N)))
   ```

2. Apply Bonferroni correction to all reported p-values.

3. Report: what is the probability that the best of N backtests would show this Sharpe by chance?

## Attack 2: Parameter Sensitivity

1. Take every tunable parameter. Perturb by ±10%, ±25%, ±50%.
2. Re-run the backtest for each perturbation.
3. Plot Sharpe as a function of each parameter.

**Overfitting signature:** A sharp peak — performance collapses with small parameter changes.
**Robust signature:** Flat-ish performance across a range of reasonable values.

4. Compute **parameter stability score:** fraction of perturbations retaining Sharpe > 50% of
   original.

## Attack 3: Time-Series Fragility

1. **Leave-one-year-out:** Remove each calendar year and recompute Sharpe. If removing any single
   year drops Sharpe by > 50%, the strategy is fragile.

2. **Walk-forward split:** Train on first 60%, evaluate on last 40%. Report out-of-sample vs
   in-sample Sharpe. **Ratio below 0.5 is a red flag.**

3. **Time reversal:** Reverse the time series and run the strategy backward. A truly predictive
   signal should fail on reversed data. If it still "works," you're fitting to autocorrelation or
   data artifacts.

## Attack 4: Data Snooping

Check for common biases:

1. **Survivorship bias:** Does the universe include only currently active assets, or does it
   properly include delisted/dead assets?

2. **Look-ahead bias:** Is any data used in signal construction available AFTER the trading decision
   would need to be made? Common culprits:
   - Using close prices for signals when you'd need to trade at close
   - Using financial data before its actual release date
   - Using revised/restated data instead of point-in-time as-reported data

3. **Data quality:** Gaps, duplicates, stale prices? Proper handling of splits, dividends, exchange
   listings/delistings?

## Attack 5: Regime Dependency

1. Divide history into regimes using either:
   - HMM with 2–4 states
   - Simple heuristics (e.g., VIX > 25 = high vol, BTC drawdown > 20% = bear)

2. Report strategy performance metrics in each regime separately.

3. Estimate current regime and transition probabilities.

4. Compute **regime-adjusted Sharpe:** weight per-regime Sharpes by expected future regime
   probabilities.

## Attack 6: Synthetic Data Test

1. Generate synthetic return series matching the real data's statistical properties (mean, vol,
   autocorrelation, cross-correlations) but containing NO actual signal.
2. Run the strategy on 100 synthetic datasets.
3. Report how often the strategy achieves Sharpe ≥ the real backtest.

**If this happens > 5% of the time, the real result is not statistically distinguishable from
noise.**

Implementation approach:

```python
# Block bootstrap or parametric simulation
from numpy.random import default_rng
rng = default_rng(42)

synthetic_sharpes = []
for i in range(100):
    # Generate synthetic returns with matched properties
    synthetic_returns = generate_matched_synthetic(real_returns, rng)
    synthetic_sharpe = run_strategy(synthetic_returns)
    synthetic_sharpes.append(synthetic_sharpe)

p_value = np.mean(np.array(synthetic_sharpes) >= real_sharpe)
```

## Final Verdict

Score the strategy 1–10 on a **"realness" scale** based on these attacks.

Summarize:

- Which attacks it survived
- Which it failed
- Honest probability estimate that this alpha will persist out of sample
