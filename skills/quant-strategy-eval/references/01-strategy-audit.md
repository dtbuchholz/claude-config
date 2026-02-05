# Module 1: Strategy Audit

Full diagnostic of a trading strategy's return profile, risk decomposition, attribution, and
statistical significance.

## Section A: Return Profile

Compute and display:

- Total return, CAGR, annualized volatility
- Sharpe ratio, Sortino ratio, Calmar ratio
- Max drawdown (magnitude AND duration in days), average drawdown
- Win rate (% positive periods), profit factor (gross profit / gross loss)
- Skewness and kurtosis of returns

Plot:

- Cumulative returns vs benchmark (log scale)
- Drawdown chart over time
- Rolling 12-month Sharpe
- Monthly returns heatmap (year × month)

Flag anything suspicious:

- Single-day returns > 3 standard deviations
- Returns on dates with known data issues (exchange outages, flash crashes)
- Periods where the strategy suspiciously avoids known market crashes

## Section B: Risk Decomposition

Run a factor regression of strategy returns against relevant risk factors:

- **Crypto:** BTC beta, ETH beta, market cap factor, momentum factor, volatility factor
- **Equities:** Fama-French 5 factors + momentum
- **Futures/Multi-asset:** appropriate macro factors (rates, commodities, FX, equity)

Report: alpha, betas, R-squared, t-statistics for each coefficient.

Compute percentage of variance explained by systematic factors vs residual alpha.

**Critical flag:** If R-squared to benchmark > 0.5, the strategy may be disguised beta, not alpha.
Flag prominently.

Compute rolling factor exposures over time — stable or drifting?

## Section C: Return Attribution

Decompose returns by:

- Time period (yearly, quarterly)
- Long vs short book (if applicable)
- Sector/asset/segment
- Holding period bucket

Identify concentration risk:

- What % of total P&L comes from the top 5 trades or top 5 days?
- **If > 30% of P&L comes from < 5% of trades, flag as fragile**

Check for "one-trick" strategies that only worked in a specific regime.

## Section D: Statistical Significance

1. **T-statistic on annualized alpha.** Apply the Harvey, Liu & Zhu (2016) threshold: is it above
   3.0?

2. **Bootstrap analysis:** Resample returns with replacement (10,000 iterations). Compute the
   distribution of Sharpe ratios. Report the 5th percentile Sharpe — this is the "unlucky but real"
   scenario.

3. **Deflated Sharpe ratio:** Adjust for the number of strategy variations tested. Ask the user for
   this number if not provided.

4. **Permutation test:** Shuffle the signal/return alignment 10,000 times. Compute the fraction of
   permuted Sharpes that exceed the actual Sharpe. This is a non-parametric p-value.

## Section E: Executive Summary

Write a 1-page summary:

- **Verdict:** Is this alpha real, marginal, or likely overfit?
- Top 3 strengths
- Top 3 risks or red flags
- Specific recommendations for improvement
- Honest capacity assessment (how much capital can this absorb?)
