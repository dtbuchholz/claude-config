---
name: analyze-data
description:
  Analyze a dataset with parallel EDA agents and generate insights. Creates distribution analysis,
  missing data reports, correlation analysis, outlier detection, and visualizations.
---

# Analyze Data

Perform comprehensive data analysis using parallel specialist agents. Generates insights,
visualizations, and recommendations.

## When This Skill Applies

- User provides a dataset path (CSV, Parquet, JSON)
- User asks to analyze or explore data
- User wants to understand data quality or distributions

## Data Path

The user should provide a path to the data file. If not provided:

1. Look for data files: `find . -name "*.csv" -o -name "*.parquet" -o -name "*.json" | head -10`
2. Ask user: "Which dataset would you like to analyze?"

## Workflow

### Step 1: Initial Data Load and Profile

Load the data and generate a quick profile:

```python
import pandas as pd
import numpy as np

# Load data (detect format)
df = pd.read_csv('[data_path]')  # or read_parquet, read_json

# Quick profile
print(f"Shape: {df.shape}")
print(f"Columns: {df.columns.tolist()}")
print(f"Data types:\n{df.dtypes}")
print(f"Missing values:\n{df.isnull().sum()}")
print(f"Sample:\n{df.head()}")
```

### Step 2: Ask Analysis Questions

Use AskUserQuestion to clarify:

1. **Analysis goal**: "What question are you trying to answer with this data?"
   - Exploratory analysis (understand the data)
   - Predictive modeling (predict a target)
   - Statistical testing (compare groups)
   - Time series analysis (forecast trends)

2. **Target variable** (if applicable): "Which column is the target/outcome you want to predict or
   analyze?"

3. **Key dimensions**: "Which columns represent important groups or segments to analyze?"

### Step 3: Launch Parallel Analysis Agents

**CRITICAL: Launch ALL agents in a SINGLE message.**

```
Task (model: haiku, subagent_type: general-purpose): "DISTRIBUTION ANALYSIS

Analyze distributions for this dataset:
- Load: [data_path]
- For each numeric column: compute mean, median, std, skewness, kurtosis
- Check normality (Shapiro-Wilk for n<5000, else D'Agostino)
- Identify heavily skewed columns (|skew| > 1)
- For each categorical column: value counts, cardinality

Output:
- Table of distribution stats
- List of columns needing transformation
- Anomalies found"

Task (model: haiku, subagent_type: general-purpose): "MISSING DATA ANALYSIS

Analyze missing data patterns:
- Load: [data_path]
- Missing count and percentage per column
- Missing data patterns (MCAR, MAR, MNAR indicators)
- Correlations between missingness
- Columns with >50% missing (candidates for dropping)

Output:
- Missing data summary table
- Pattern analysis
- Imputation recommendations"

Task (model: haiku, subagent_type: general-purpose): "CORRELATION ANALYSIS

Analyze relationships:
- Load: [data_path]
- Pearson correlations for numeric columns
- High correlations (|r| > 0.7) - multicollinearity risks
- Target correlations if target specified: [target]
- Cramér's V for categorical associations

Output:
- Top 10 correlations
- Multicollinearity warnings
- Feature importance ranking (if target)"

Task (model: haiku, subagent_type: general-purpose): "OUTLIER ANALYSIS

Detect outliers:
- Load: [data_path]
- IQR method for each numeric column
- Z-score method (|z| > 3)
- Isolation Forest for multivariate outliers
- Business logic outliers (negative prices, future dates, etc.)

Output:
- Outlier counts per column
- Most extreme values
- Recommended handling"

Task (model: sonnet, subagent_type: general-purpose): "VISUALIZATION GENERATION

Create key visualizations:
- Load: [data_path]
- Distribution plots for top numeric columns
- Correlation heatmap
- Target distribution (if applicable)
- Time trends (if datetime columns exist)
- Category breakdowns

Save plots to: ./analysis_output/
Use: matplotlib, seaborn
Output: List of generated plot files"
```

### Step 4: If Predictive Modeling Requested

Launch additional modeling agents:

```
Task (model: sonnet, subagent_type: general-purpose): "BASELINE MODELING

Build baseline models:
- Load: [data_path]
- Target: [target]
- Train/test split (80/20, stratified if classification)
- Baseline: DummyClassifier/DummyRegressor
- Simple model: LogisticRegression or LinearRegression
- Tree model: RandomForestClassifier/Regressor

Report:
- Baseline performance
- Simple model performance
- Feature importances from tree model
- Recommended next steps"

Task (model: haiku, subagent_type: general-purpose): "FEATURE ENGINEERING SUGGESTIONS

Based on data profile, suggest features:
- Log transforms for skewed numerics
- Binning strategies
- Interaction terms
- Date feature extraction
- Encoding strategies for categoricals
- Aggregation features if hierarchical data

Output: Prioritized list of feature engineering ideas"
```

### Step 5: Synthesize Results

Collect all agent outputs and create unified report:

```markdown
# Data Analysis Report: [Dataset Name]

**Generated:** [Date] **Dataset:** [Path] **Shape:** [Rows] x [Columns]

## Executive Summary

[2-3 key findings with metrics]

## Data Quality

### Missing Data

[From missing data agent]

### Outliers

[From outlier agent]

### Data Types

[Column type summary]

## Key Distributions

[Distribution insights + plots]

## Relationships

### Correlations

[Top correlations, multicollinearity warnings]

### Target Analysis (if applicable)

[Target distribution, key predictors]

## Visualizations

[Links/embeds to generated plots]

## Recommendations

### Data Cleaning

1. [Specific action]
2. [Specific action]

### Feature Engineering

1. [Specific suggestion]
2. [Specific suggestion]

### Modeling (if applicable)

- Baseline performance: [metric]
- Recommended approach: [algorithm]
- Key features: [list]

## Next Steps

1. [Action item]
2. [Action item]
```

### Step 6: Save Outputs

```bash
mkdir -p analysis_output
```

Save:

- `analysis_output/report.md` - Full analysis report
- `analysis_output/data_profile.json` - Structured data profile
- `analysis_output/*.png` - Visualizations
- `analysis_output/notebook.ipynb` - Reproducible notebook (optional)

## Output

Provide the user with:

1. Executive summary (3-5 bullet points)
2. Path to full report
3. Key visualizations inline
4. Recommended next steps

## Tips

- For large files (>100MB), use `polars` or `duckdb` instead of pandas
- For notebooks, use NotebookEdit to create reproducible analysis
- Reference the `data-science` skill for methodology details
