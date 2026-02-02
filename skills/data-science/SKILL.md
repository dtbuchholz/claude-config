---
name: data-science
description:
  Data science methodology for EDA, statistical analysis, modeling, and insights generation.
---

# Data Science Skill

Expert methodology for statistical analysis, machine learning, and business insights. Use this skill
when working with data analysis, modeling, or generating insights from datasets.

## Environment Setup

**Python stack (prefer these):**

```python
# Core
import pandas as pd
import numpy as np

# Visualization
import matplotlib.pyplot as plt
import seaborn as sns
import plotly.express as px

# Statistics
from scipy import stats
import statsmodels.api as sm

# ML
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score, f1_score,
    mean_squared_error, r2_score, confusion_matrix, classification_report
)
```

**For large datasets:**

```python
import polars as pl  # Faster than pandas for large data
import duckdb        # SQL on local files
```

## Exploratory Data Analysis (EDA)

### Quick Data Profile

```python
def quick_profile(df):
    """Generate quick data profile."""
    print(f"Shape: {df.shape}")
    print(f"\nData Types:\n{df.dtypes}")
    print(f"\nMissing Values:\n{df.isnull().sum()}")
    print(f"\nNumeric Summary:\n{df.describe()}")
    print(f"\nCategorical Columns:")
    for col in df.select_dtypes(include=['object', 'category']).columns:
        print(f"  {col}: {df[col].nunique()} unique values")
```

### Distribution Analysis

```python
def analyze_distributions(df, numeric_cols):
    """Check distributions and normality."""
    for col in numeric_cols:
        stat, p_value = stats.normaltest(df[col].dropna())
        skew = df[col].skew()
        kurt = df[col].kurtosis()
        print(f"{col}: skew={skew:.2f}, kurtosis={kurt:.2f}, normal_p={p_value:.4f}")
```

### Correlation Analysis

```python
def correlation_analysis(df, target=None):
    """Analyze correlations, optionally with target."""
    corr_matrix = df.select_dtypes(include=[np.number]).corr()

    if target:
        target_corr = corr_matrix[target].sort_values(ascending=False)
        print(f"Correlations with {target}:\n{target_corr}")

    # Find high correlations (potential multicollinearity)
    high_corr = []
    for i in range(len(corr_matrix.columns)):
        for j in range(i+1, len(corr_matrix.columns)):
            if abs(corr_matrix.iloc[i, j]) > 0.8:
                high_corr.append((corr_matrix.columns[i], corr_matrix.columns[j], corr_matrix.iloc[i, j]))

    if high_corr:
        print(f"\nHigh correlations (>0.8): {high_corr}")

    return corr_matrix
```

### Outlier Detection

```python
def detect_outliers(df, cols, method='iqr'):
    """Detect outliers using IQR or z-score."""
    outliers = {}
    for col in cols:
        if method == 'iqr':
            Q1, Q3 = df[col].quantile([0.25, 0.75])
            IQR = Q3 - Q1
            mask = (df[col] < Q1 - 1.5*IQR) | (df[col] > Q3 + 1.5*IQR)
        else:  # z-score
            z = np.abs(stats.zscore(df[col].dropna()))
            mask = z > 3
        outliers[col] = mask.sum()
    return outliers
```

## Statistical Testing

### Hypothesis Testing Checklist

1. State null and alternative hypotheses
2. Choose significance level (typically α=0.05)
3. Check assumptions (normality, variance homogeneity)
4. Select appropriate test
5. Calculate test statistic and p-value
6. Make decision and interpret

### Common Tests

```python
# t-test (compare two means)
stat, p = stats.ttest_ind(group1, group2)

# Paired t-test (before/after)
stat, p = stats.ttest_rel(before, after)

# ANOVA (compare multiple groups)
stat, p = stats.f_oneway(group1, group2, group3)

# Chi-square (categorical independence)
stat, p, dof, expected = stats.chi2_contingency(contingency_table)

# Mann-Whitney U (non-parametric two groups)
stat, p = stats.mannwhitneyu(group1, group2)

# Correlation significance
r, p = stats.pearsonr(x, y)  # linear
rho, p = stats.spearmanr(x, y)  # monotonic
```

### Effect Size

```python
def cohens_d(group1, group2):
    """Calculate Cohen's d effect size."""
    n1, n2 = len(group1), len(group2)
    var1, var2 = group1.var(), group2.var()
    pooled_std = np.sqrt(((n1-1)*var1 + (n2-1)*var2) / (n1+n2-2))
    return (group1.mean() - group2.mean()) / pooled_std

# Interpretation: 0.2=small, 0.5=medium, 0.8=large
```

## Feature Engineering

### Numeric Transformations

```python
# Log transform (right-skewed data)
df['log_col'] = np.log1p(df['col'])  # log(1+x) handles zeros

# Box-Cox (find optimal transform)
from scipy.stats import boxcox
df['boxcox_col'], lambda_ = boxcox(df['col'] + 1)

# Binning
df['binned'] = pd.cut(df['col'], bins=5, labels=['very_low', 'low', 'medium', 'high', 'very_high'])

# Quantile binning
df['quantile_binned'] = pd.qcut(df['col'], q=4, labels=['Q1', 'Q2', 'Q3', 'Q4'])
```

### Categorical Encoding

```python
# One-hot encoding
df_encoded = pd.get_dummies(df, columns=['cat_col'], drop_first=True)

# Label encoding (ordinal)
from sklearn.preprocessing import LabelEncoder
le = LabelEncoder()
df['encoded'] = le.fit_transform(df['cat_col'])

# Target encoding (for high cardinality)
target_means = df.groupby('cat_col')['target'].mean()
df['target_encoded'] = df['cat_col'].map(target_means)
```

### Time Features

```python
df['date'] = pd.to_datetime(df['date'])
df['year'] = df['date'].dt.year
df['month'] = df['date'].dt.month
df['day_of_week'] = df['date'].dt.dayofweek
df['is_weekend'] = df['day_of_week'].isin([5, 6]).astype(int)
df['quarter'] = df['date'].dt.quarter
df['days_since_start'] = (df['date'] - df['date'].min()).dt.days
```

### Interaction Features

```python
# Polynomial features
from sklearn.preprocessing import PolynomialFeatures
poly = PolynomialFeatures(degree=2, interaction_only=True)
interactions = poly.fit_transform(df[['feat1', 'feat2']])

# Manual interactions
df['feat1_x_feat2'] = df['feat1'] * df['feat2']
df['feat1_ratio_feat2'] = df['feat1'] / (df['feat2'] + 1e-8)
```

## Model Development

### Train/Test Split

```python
from sklearn.model_selection import train_test_split

X = df.drop('target', axis=1)
y = df['target']

# Stratify for classification
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)
```

### Cross-Validation

```python
from sklearn.model_selection import cross_val_score, StratifiedKFold

cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
scores = cross_val_score(model, X, y, cv=cv, scoring='accuracy')
print(f"CV Score: {scores.mean():.3f} (+/- {scores.std()*2:.3f})")
```

### Model Selection Guide

| Problem Type            | Start With              | Then Try              |
| ----------------------- | ----------------------- | --------------------- |
| Classification (binary) | LogisticRegression      | RandomForest, XGBoost |
| Classification (multi)  | RandomForest            | XGBoost, Neural Net   |
| Regression              | LinearRegression, Ridge | RandomForest, XGBoost |
| Time Series             | ARIMA, Prophet          | LSTM if enough data   |
| Clustering              | KMeans                  | DBSCAN, Hierarchical  |
| Anomaly Detection       | IsolationForest         | One-Class SVM         |

### Baseline Models

```python
# Classification baseline
from sklearn.dummy import DummyClassifier
baseline = DummyClassifier(strategy='most_frequent')
baseline.fit(X_train, y_train)
print(f"Baseline accuracy: {baseline.score(X_test, y_test):.3f}")

# Regression baseline
from sklearn.dummy import DummyRegressor
baseline = DummyRegressor(strategy='mean')
baseline.fit(X_train, y_train)
print(f"Baseline RMSE: {np.sqrt(mean_squared_error(y_test, baseline.predict(X_test))):.3f}")
```

### Hyperparameter Tuning

```python
from sklearn.model_selection import RandomizedSearchCV

param_dist = {
    'n_estimators': [100, 200, 500],
    'max_depth': [5, 10, 20, None],
    'min_samples_split': [2, 5, 10],
    'min_samples_leaf': [1, 2, 4]
}

search = RandomizedSearchCV(
    RandomForestClassifier(random_state=42),
    param_dist,
    n_iter=20,
    cv=5,
    scoring='f1',
    random_state=42,
    n_jobs=-1
)
search.fit(X_train, y_train)
print(f"Best params: {search.best_params_}")
print(f"Best score: {search.best_score_:.3f}")
```

## Model Evaluation

### Classification Metrics

```python
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score

y_pred = model.predict(X_test)
y_prob = model.predict_proba(X_test)[:, 1]

print(classification_report(y_test, y_pred))
print(f"ROC-AUC: {roc_auc_score(y_test, y_prob):.3f}")

# Confusion matrix
cm = confusion_matrix(y_test, y_pred)
sns.heatmap(cm, annot=True, fmt='d', cmap='Blues')
```

### Regression Metrics

```python
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score

y_pred = model.predict(X_test)

print(f"RMSE: {np.sqrt(mean_squared_error(y_test, y_pred)):.3f}")
print(f"MAE: {mean_absolute_error(y_test, y_pred):.3f}")
print(f"R²: {r2_score(y_test, y_pred):.3f}")

# Residual analysis
residuals = y_test - y_pred
plt.scatter(y_pred, residuals)
plt.axhline(y=0, color='r', linestyle='--')
plt.xlabel('Predicted')
plt.ylabel('Residuals')
```

### Feature Importance

```python
# Tree-based models
importances = pd.DataFrame({
    'feature': X.columns,
    'importance': model.feature_importances_
}).sort_values('importance', ascending=False)

# Permutation importance (model-agnostic)
from sklearn.inspection import permutation_importance
perm_imp = permutation_importance(model, X_test, y_test, n_repeats=10, random_state=42)
```

## Visualization Best Practices

### Distribution Plots

```python
fig, axes = plt.subplots(2, 2, figsize=(12, 10))

# Histogram with KDE
sns.histplot(data=df, x='numeric_col', kde=True, ax=axes[0,0])

# Box plot by category
sns.boxplot(data=df, x='category', y='numeric_col', ax=axes[0,1])

# Violin plot
sns.violinplot(data=df, x='category', y='numeric_col', ax=axes[1,0])

# QQ plot for normality
stats.probplot(df['numeric_col'], dist="norm", plot=axes[1,1])

plt.tight_layout()
```

### Relationship Plots

```python
# Scatter with regression line
sns.regplot(data=df, x='x_col', y='y_col')

# Pair plot for multiple variables
sns.pairplot(df[['col1', 'col2', 'col3', 'target']], hue='target')

# Heatmap for correlations
plt.figure(figsize=(10, 8))
sns.heatmap(df.corr(), annot=True, cmap='coolwarm', center=0)
```

### Model Performance Plots

```python
# ROC curve
from sklearn.metrics import roc_curve, auc
fpr, tpr, _ = roc_curve(y_test, y_prob)
plt.plot(fpr, tpr, label=f'AUC = {auc(fpr, tpr):.3f}')
plt.plot([0, 1], [0, 1], 'k--')
plt.xlabel('False Positive Rate')
plt.ylabel('True Positive Rate')
plt.legend()

# Learning curve
from sklearn.model_selection import learning_curve
train_sizes, train_scores, val_scores = learning_curve(
    model, X, y, train_sizes=np.linspace(0.1, 1.0, 10), cv=5
)
```

## Reporting Template

### Analysis Summary Structure

```markdown
## Executive Summary

- Key finding 1 (with supporting metric)
- Key finding 2 (with supporting metric)
- Recommendation

## Methodology

- Data source and time period
- Sample size and any exclusions
- Statistical methods used

## Key Findings

### Finding 1: [Title]

- Metric: X increased by Y% (p < 0.05)
- Visualization
- Business implication

## Limitations

- Data quality issues
- Assumptions made
- Generalizability concerns

## Recommendations

1. Action item with expected impact
2. Action item with expected impact

## Appendix

- Detailed methodology
- Additional analyses
- Code repository link
```

## Quality Checklist

Before finalizing any analysis:

- [ ] **Data Quality**: Missing values handled, outliers addressed, data types correct
- [ ] **Statistical Rigor**: Assumptions checked, appropriate tests used, p-values reported
- [ ] **Model Validation**: Cross-validation performed, holdout test set used, no data leakage
- [ ] **Reproducibility**: Random seeds set, code documented, data versioned
- [ ] **Business Relevance**: Insights actionable, metrics meaningful, stakeholders considered
- [ ] **Communication**: Visualizations clear, findings summarized, limitations stated
