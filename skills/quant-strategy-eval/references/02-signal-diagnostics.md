# Module 2: Signal Diagnostics

Deep evaluation of a trading signal's predictive power. Determines whether a signal contains genuine
exploitable information or is noise.

Requires signal-level data: a time series of signal values (cross-sectional scores or single time
series) with aligned forward returns.

## Section A: Information Coefficient Analysis

Compute rank IC (Spearman correlation between signal rank and forward return rank) at each period.

Report:

- Mean IC, median IC, IC standard deviation
- ICIR (mean IC / std IC) — **investable threshold: ICIR > 0.5**
- Hit rate (% of periods with positive IC) — **good threshold: > 55%**
- Mean IC benchmark: **> 0.03 is meaningful, > 0.05 is strong**

Plot: IC time series, rolling 12-period IC, cumulative IC.

**IC decay curve:** Test IC across multiple forward return horizons (1d, 2d, 5d, 10d, 21d, 63d).
Plot the curve. Where does the signal peak? Where does it die? This shapes rebalance frequency and
reveals what type of alpha is being captured.

## Section B: Quantile Analysis

Sort universe into quintiles (or deciles if universe > 200 names) by signal score at each rebalance.

Compute and plot:

- Average forward return by quantile
- Cumulative return of each quantile over time
- Long-short spread (Q1 vs Q5)

**Monotonicity check:** Do returns increase smoothly across quantiles? If Q1 and Q5 perform well but
Q2-Q4 are random, the signal may only work in extremes.

Report the t-statistic on the long-short spread return.

## Section C: Stability Analysis

1. **Half-sample test:** Split sample in half. Report IC and quantile spreads for each half. If the
   signal works in one half but not the other, it's suspect.

2. **Annual IC:** Compute IC by calendar year. Is performance consistent or clustered?

3. **Regime-conditional IC:** Compute IC in: up vs down markets, high vs low vol, trending vs
   mean-reverting. A signal that only works in one regime isn't automatically disqualified but must
   be acknowledged and position-sized accordingly.

## Section D: Correlation and Redundancy

If other signals exist in the pipeline:

1. Compute pairwise correlations between this signal and existing signals
2. Compute **marginal IC:** after orthogonalizing against existing signals, what residual IC
   remains?

Key insight: A signal with IC = 0.05 but correlation = 0.9 to an existing signal adds almost
nothing. A signal with IC = 0.03 but correlation = 0.1 is far more valuable.

## Section E: Turnover and Implementability

1. Compute implied turnover from following the signal (% of portfolio that changes at each
   rebalance)
2. Estimate transaction cost drag at realistic assumptions:
   - Liquid crypto: ~10 bps per trade
   - Large-cap equities: ~5 bps per trade
   - Small/micro-cap or illiquid: ~25-50+ bps
3. Report net-of-cost IC and quantile spread returns
4. **If transaction costs consume > 40% of gross alpha, flag as potentially non-implementable at
   scale**

## Section F: Verdict

Score 1–5 on each dimension:

- Economic rationale
- Statistical significance
- Stability across time and regimes
- Uniqueness (low correlation to existing signals)
- Implementability (turnover and cost efficiency)

Recommendation: core signal, diversifying signal, or reject. Key risks and suggested hedges.
