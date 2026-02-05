---
name: quant-strategy-eval
description: >
  Rigorous quantitative evaluation, diagnosis, and improvement of trading strategies. Use when asked
  to: evaluate or audit a trading strategy, analyze alpha signals or factors, test for overfitting,
  optimize portfolio construction, stress-test a strategy, or improve a quant strategy's
  risk-adjusted returns. Triggers include mentions of: Sharpe ratio, backtest, alpha, signal IC,
  drawdown, overfitting, strategy evaluation, factor analysis, quant strategy, trading strategy
  review, or any request to analyze returns/performance of a systematic strategy. Supports crypto,
  equities, futures, and multi-asset strategies.
---

# Quant Strategy Evaluation

Evaluate, diagnose, and improve systematic trading strategies with institutional-grade rigor.

## When This Skill Applies

- User asks to evaluate, audit, or review a trading strategy
- User mentions Sharpe ratio, backtest, alpha, drawdown, or overfitting
- User provides returns data or trade logs for analysis
- User asks about signal quality, factor analysis, or portfolio construction
- User wants to stress-test a strategy or check for overfitting

## Workflow

Run modules sequentially for a full evaluation, or individually for targeted analysis. Always start
by collecting strategy context.

### Strategy Context (collect first)

Before running any module, gather this context from the user or infer from provided data:

```
Strategy name:
Asset class: [crypto / equities / futures / options / multi-asset]
Strategy type: [momentum / mean-reversion / stat arb / market-making / factor-based / other]
Holding period: [intraday / daily / weekly / monthly]
Universe: [tradeable instruments]
Data files: [paths to data, returns series, trade logs]
Backtest period: [start - end]
Benchmark: [BTC / SPY / equal-weight universe / risk-free / none]
Number of strategy variations tested: [integer — critical for overfitting analysis]
Number of free parameters: [integer]
```

If the user provides data files (CSVs, DataFrames, trade logs), inspect them first to understand the
schema before running any analysis.

### Module Sequence

| #   | Module                      | When to Use                                   | Reference                                 |
| --- | --------------------------- | --------------------------------------------- | ----------------------------------------- |
| 1   | **Strategy Audit**          | First pass on any strategy — full diagnostic  | `references/01-strategy-audit.md`         |
| 2   | **Signal Diagnostics**      | Deep-dive on individual alpha signals/factors | `references/02-signal-diagnostics.md`     |
| 3   | **Overfitting Tribunal**    | Adversarial testing — is alpha real or noise? | `references/03-overfitting-tribunal.md`   |
| 4   | **Portfolio Construction**  | Optimize signal → position translation        | `references/04-portfolio-construction.md` |
| 5   | **Regime & Stress Testing** | Test robustness across market environments    | `references/05-regime-stress-testing.md`  |
| 6   | **Improvement Roadmap**     | Synthesize findings into actionable plan      | `references/06-improvement-roadmap.md`    |

**Default flow:** If user says "evaluate my strategy" or similar, run modules 1 → 3 → 5 → 6. Add
module 2 if individual signals are provided. Add module 4 if the user wants position sizing /
construction optimization.

**Quick mode:** If user wants a fast read, run only module 1 (Strategy Audit).

### Execution Guidelines

1. **Read the relevant reference file** before starting each module
2. **Write and execute all code** — produce actual computed results, not pseudocode
3. **Save all outputs** (charts, tables, summary stats) to an `output/` directory
4. **Use Python** with pandas, numpy, scipy, matplotlib, seaborn, statsmodels. Install additional
   packages only if needed (e.g., `arch` for GARCH, `hmmlearn` for regime detection)
5. **Interpret every result** — raw numbers without interpretation are useless. After each
   computation, explain what it means for the strategy
6. **Be skeptical by default** — the goal is to find problems, not confirm the strategy works

### Key Benchmarks (quick reference)

| Metric             | Mediocre  | Good      | Elite |
| ------------------ | --------- | --------- | ----- |
| Sharpe (net)       | 0.5–1.0   | 1.0–2.0   | 2.0+  |
| Sortino            | 1.0–1.5   | 1.5–3.0   | 3.0+  |
| Calmar             | 0.5–1.0   | 1.0–2.0   | 2.0+  |
| IC (single factor) | 0.02–0.03 | 0.04–0.07 | 0.08+ |
| Info Ratio         | 0.3–0.5   | 0.5–1.0   | 1.0+  |
| Max Drawdown       | 20–30%    | 10–20%    | <10%  |
| Alpha t-stat       | 2.0–2.5   | 2.5–3.0   | 3.0+  |

Benchmarks shift by strategy type. HFT: higher Sharpes, near-zero capacity. Macro: lower Sharpes,
absorbs billions. Crypto: generally higher vol, wider ranges.

### Crypto-Specific Considerations

When evaluating crypto strategies, account for:

- **Funding rates** on perpetual futures (significant cost or income)
- **24/7 markets** — no "close"; use consistent UTC snapshots
- **Exchange-specific data** — liquidation cascades, outages, listing/delisting events
- **Survivorship bias** — tokens die frequently; ensure dead tokens are in the universe
- **Liquidity** — varies dramatically; model realistic fills using ADV
- **Basis / funding carry** — decompose returns to check if "alpha" is actually basis carry
