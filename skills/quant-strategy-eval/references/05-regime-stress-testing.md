# Module 5: Regime & Stress Testing

Test strategy robustness across historical crises and hypothetical scenarios. Assess survivability
and tail risk.

## Section A: Historical Stress Events

Run the strategy through these specific periods. Report performance in each. Note untested periods.

### Crypto Strategies

- COVID crash (March 2020)
- China mining ban (May–June 2021)
- Terra/Luna collapse (May 2022)
- FTX collapse (November 2022)
- SVB/banking crisis (March 2023)
- Bitcoin ETF approval volatility (January 2024)
- Any major exchange hacks or delistings in the universe

### Equity Strategies

- GFC (September 2008 – March 2009)
- Flash Crash (May 6, 2010)
- Volmageddon (February 2018)
- COVID crash (March 2020)
- Meme stock / GME squeeze (January 2021)
- 2022 rate shock

For each event report: drawdown, recovery time (days), max daily loss, whether risk management rules
would have triggered.

## Section B: Hypothetical Stress Scenarios

1. **Correlation shock:** Set all pairwise correlations to 0.9. Simulate a 3-sigma market selloff.
   What happens to the portfolio?

2. **Liquidity crisis:** Multiply transaction costs by 5×, reduce available volume by 80%. Can the
   strategy still rebalance?

3. **Volatility regime shift:** Simulate vol doubling overnight, remaining elevated for 3 months.
   Impact on Sharpe, drawdown, and risk management triggers?

4. **Signal reversal:** What if the signal flips sign for 1 month? 3 months? Compute the damage.

5. **Data feed failure:** Simulate a 24-hour gap in signal data. Does the strategy have sensible
   default behavior (hold positions? flatten?)?

## Section C: Regime Classification

1. Classify the backtest into regimes using:
   - **HMM** with 2–4 states (preferred), or
   - **K-means clustering** on features: return, volatility, correlation, trend strength

2. Report strategy metrics in each regime.

3. Estimate current regime and transition probabilities between regimes.

4. **Worst-regime Sharpe** — the realistic performance floor.

## Section D: Tail Risk Metrics

Compute:

- VaR (95% and 99%)
- CVaR / Expected Shortfall (95% and 99%)
- Maximum 1-day loss, maximum 5-day loss
- Tail ratio: mean of returns > 95th percentile / |mean of returns < 5th percentile|

**Fat tail test:** Fit a t-distribution to returns, report degrees of freedom. If df < 5, the
strategy has dangerously fat tails.

**Pain index:** Average drawdown over the full period.

## Section E: Survival Analysis

Answer these questions with quantitative estimates:

1. Probability of drawdown > 20% in the next year?
2. Expected max drawdown over a 3-year period?
3. Probability an investor is underwater after 1 year? After 2 years?
4. What position sizing keeps 99% VaR below a target threshold (ask user for threshold, default 5%)?
