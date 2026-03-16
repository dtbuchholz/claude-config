# Autoresearch Evaluation Patterns

Guide for designing metrics and benchmark scripts across different experiment domains.

## Metric Design Principles

The autoresearch loop makes a binary keep/discard decision based on a primary metric. For the loop to work well:

1. **Primary metric must be computable** — output of a script, not human judgment
2. **Higher/lower must mean better** — monotonic improvement direction
3. **Must be reproducible** — same code should produce same (or very similar) metric
4. **Must resist gaming** — the agent will optimize whatever you measure

## Domain-Specific Patterns

### ML Model Optimization (straightforward)

```bash
# autoresearch.sh
python train.py  # outputs METRIC r2=0.78 and METRIC rmse=2.20
```

- Primary: R², F1, AUC, accuracy (higher is better)
- Secondary: RMSE, training time, model size
- Key: use held-out test set or cross-validation to prevent overfitting

### Algorithm / Performance Optimization (straightforward)

```bash
# autoresearch.sh
hyperfine --warmup 3 --min-runs 10 './target/release/mybinary' --export-json /tmp/bench.json
MEDIAN=$(jq '.results[0].median' /tmp/bench.json)
echo "METRIC runtime_ms=$(echo "$MEDIAN * 1000" | bc)"
```

- Primary: runtime, throughput, memory
- Key: use `hyperfine` or similar for stable measurements; warm up caches

### Trading Strategy (gray zone — overfitting risk)

```bash
# autoresearch.sh — MUST use strict temporal split
python backtest.py --train-end 2023-12-31 --val-end 2024-06-30 --test-start 2024-07-01
# Agent only sees train+val during development
# Metric comes from TEST period only
```

- Primary: out-of-sample Sharpe ratio (test period)
- Secondary: max drawdown, turnover, win rate, number of parameters
- **Critical safeguards:**
  - Strict temporal split (no future data leakage)
  - Complexity penalty: track `num_parameters` as secondary, discourage growth
  - Cap at ~30-50 experiments to limit overfitting risk
  - Log strategy descriptions in worklog for human review
  - Consider walk-forward validation (rolling windows) instead of single split

### API / CLI Ergonomics (proxy metrics)

```bash
# autoresearch.sh — automate a user scenario
START=$(date +%s%N)
# Run a scripted user flow
echo '{"query": "test"}' | ./my-cli search > /dev/null 2>&1
./my-cli create --name "test-item" > /dev/null 2>&1
./my-cli list --format json | jq length > /dev/null 2>&1
END=$(date +%s%N)

STEPS=3  # number of commands needed
DURATION=$(echo "scale=3; ($END - $START) / 1000000000" | bc)

# Validate outputs
ERRORS=0
echo '{"query": "test"}' | ./my-cli search 2>&1 | grep -q "error" && ERRORS=$((ERRORS+1))

echo "METRIC steps=$STEPS"
echo "METRIC duration_s=$DURATION"
echo "METRIC errors=$ERRORS"
```

- Primary: number of steps to complete task (lower), or error count (lower)
- Secondary: execution time, output size
- Limitation: measures mechanical friction, not subjective usability

### Code Quality (proxy metrics)

```bash
# autoresearch.sh
npx eslint src/ --format json 2>/dev/null | jq '[.[].errorCount] | add' > /tmp/lint.txt
ERRORS=$(cat /tmp/lint.txt)
npx tsc --noEmit 2>&1 | grep -c "error TS" > /tmp/types.txt || true
TYPE_ERRORS=$(cat /tmp/types.txt)

echo "METRIC lint_errors=$ERRORS"
echo "METRIC type_errors=$TYPE_ERRORS"
echo "METRIC total_issues=$((ERRORS + TYPE_ERRORS))"
```

- Primary: total lint + type errors (lower is better)
- Secondary: cyclomatic complexity, test coverage %
- Limitation: won't catch "code feels wrong" — only structural issues

### Prompt Engineering / LLM Output Quality

```bash
# autoresearch.sh — requires eval set + judge
python evaluate_prompts.py  # runs prompt against eval set, scores with LLM judge
# Outputs: METRIC eval_score=0.82 METRIC cost_per_query=0.003
```

- Primary: eval score against labeled test cases
- Secondary: token cost, latency
- Eval approaches:
  - String matching / regex for structured outputs
  - Cosine similarity to reference answers
  - LLM-as-judge (expensive but handles subjective quality)
  - Human-labeled rubric scores (pre-computed, not per-run)

## Anti-Patterns

| Anti-pattern | Why it fails | Fix |
|---|---|---|
| Metric on training data | Agent overfits immediately | Use held-out test set |
| Subjective metric ("make it better") | No computable score | Define proxy metrics |
| Too many secondary metrics | Agent gets confused about what to optimize | 1 primary, 2-3 secondary max |
| No complexity tracking | Agent adds parameters until it memorizes data | Track param count, penalize growth |
| Unlimited experiments | Overfitting compounds with iterations | Cap runs or add human checkpoints |
| Metric that can be gamed | Agent finds shortcuts (e.g., caching test outputs) | Validate results independently |

## Template: Custom Benchmark Script

```bash
#!/usr/bin/env bash
set -euo pipefail

# --- Pre-check (fast, <1s) ---
# Catch obvious errors before running the full benchmark
python3 -c "import py_compile; py_compile.compile('main.py', doraise=True)" 2>&1 \
  || { echo "Syntax error"; exit 1; }

# --- Run benchmark ---
OUTPUT=$(python3 main.py 2>&1)

# --- Parse metrics ---
# Primary (required)
PRIMARY=$(echo "$OUTPUT" | grep "PRIMARY:" | awk '{print $2}')
echo "METRIC primary_metric=$PRIMARY"

# Secondary (optional)
SECONDARY=$(echo "$OUTPUT" | grep "SECONDARY:" | awk '{print $2}')
echo "METRIC secondary_metric=$SECONDARY"
```
