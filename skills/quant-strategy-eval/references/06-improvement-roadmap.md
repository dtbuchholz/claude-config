# Module 6: Improvement Roadmap

Synthesize all diagnostic results into a prioritized, actionable improvement plan.

Read this module AFTER running modules 1, 3, and 5 (at minimum). Reference their outputs when
generating recommendations.

## 1. Quick Wins (< 1 week, high expected impact)

Identify low-hanging improvements:

- Position sizing adjustments (e.g., switching from equal-weight to vol-weighted)
- Risk management parameter tuning based on stress test results
- Obvious data quality fixes identified in the audit
- Cost reduction through smarter execution (rebalance frequency, order type)
- Removing known factor exposures that aren't compensated

For each quick win: describe the change, estimate impact on Sharpe, and note implementation effort.

## 2. Signal Enhancements (1–4 weeks)

Based on signal diagnostics and IC decay analysis, suggest:

- **Signal transformations:** momentum of signal (signal change over time), signal acceleration,
  improved cross-sectional normalization (e.g., sector-neutral z-scores)
- **Regime-conditional weighting:** if the signal works better in certain regimes, apply dynamic
  weighting using the regime classifier from Module 5
- **Ensemble approaches:** if single-signal, suggest 3–5 complementary signals to research based on
  economic intuition. Prioritize low-correlation signals.
- **Horizon optimization:** adjust holding period based on IC decay curves. If peak IC is at 5d but
  strategy rebalances monthly, there's alpha left on the table.
- **Non-linear combinations:** if multiple signals exist, test interaction effects (signal A ×
  signal B) or tree-based combination models

## 3. Structural Improvements (1–3 months)

- **Portfolio construction upgrade:** move from heuristic to optimized position sizing (e.g.,
  mean-variance with shrinkage, Black-Litterman)
- **Dynamic risk budgeting:** allocate risk budget across signals/strategies based on recent regime
  and signal confidence
- **Execution improvement:** reduce slippage via smarter order scheduling, participation rate
  limits, or venue selection optimization
- **Data infrastructure:** faster data pipelines, more granular data (tick-level vs daily),
  alternative data sources

## 4. Research Directions (exploratory)

Suggest 3–5 new research directions that could meaningfully improve the strategy. For each provide:

| Field              | Description                                                          |
| ------------------ | -------------------------------------------------------------------- |
| Hypothesis         | What you expect and why                                              |
| Economic rationale | Why this should predict returns (who's the loser on the other side?) |
| Data required      | What data is needed and where to source it                           |
| Difficulty         | Low / Medium / High                                                  |
| Timeline           | Estimated weeks of research                                          |
| Impact potential   | Marginal / Meaningful / Transformative                               |

Prioritize directions that address the weaknesses identified in Modules 1–5.

## 5. Kill Criteria

Define explicit shutdown conditions. These must be written down BEFORE the strategy goes live.

- **Sharpe trigger:** What trailing out-of-sample Sharpe (over what lookback) triggers a pause for
  review? Suggested: trailing 6-month Sharpe < 0.0.
- **Drawdown trigger:** What max drawdown triggers an immediate shutdown? Suggested: 1.5× the worst
  backtest drawdown.
- **Regime invalidation:** What market regime change would invalidate the strategy's core thesis? Be
  specific.
- **Flat period:** How many months of flat/negative performance before formal reassessment?
  Suggested: 6 months.
- **Capacity breach:** At what point does market impact erode alpha beyond recovery?

## Output Format

Structure the final output as a project plan:

```
Priority | Improvement | Expected Sharpe Impact | Effort | Timeline | Status
---------|-------------|----------------------|--------|----------|-------
P0       | [quick win] | +0.1–0.2             | Low    | 1 day    | Ready
P1       | [signal]    | +0.2–0.4             | Med    | 2 weeks  | Needs data
P2       | [structural]| +0.1–0.3             | High   | 6 weeks  | Design phase
...
```

Include kill criteria as a separate clearly labeled section at the end.
