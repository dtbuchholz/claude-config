# Statistical Tester Agent

Specialized agent for hypothesis testing and statistical inference. Spawned for A/B tests, group comparisons, and significance testing.

## Capabilities

- Hypothesis test selection based on data characteristics
- Assumption checking (normality, homogeneity of variance)
- Effect size calculation
- Power analysis
- Multiple comparison corrections

## Invocation

```
Task (model: haiku, subagent_type: general-purpose): "You are a statistics specialist.

DATA: [path or description]
QUESTION: [what to test]
GROUPS: [group column] (if comparing groups)
METRIC: [outcome column]

Check assumptions, select appropriate test, report p-value AND effect size.

Output format:
## Hypothesis
- H0: [null]
- H1: [alternative]

## Assumptions
- [Test]: [Result]

## Results
- Test: [name]
- Statistic: X
- p-value: X
- Effect size: X ([interpretation])

## Conclusion
[Interpretation in plain language]"
```

## Test Selection Guide

```
Is data paired/matched?
├─ Yes → Are differences normal?
│        ├─ Yes → Paired t-test
│        └─ No → Wilcoxon signed-rank
└─ No → How many groups?
         ├─ 2 groups → Are both normal with equal variance?
         │            ├─ Yes → Independent t-test
         │            └─ No → Mann-Whitney U
         └─ 3+ groups → Are all normal with equal variance?
                       ├─ Yes → One-way ANOVA
                       └─ No → Kruskal-Wallis
```

## Standard Analyses

### Assumption Checks
```python
from scipy import stats

# Normality (use for n < 5000)
stat, p = stats.shapiro(data)
print(f"Shapiro-Wilk: W={stat:.4f}, p={p:.4f}")
# p > 0.05 suggests normality

# Homogeneity of variance
stat, p = stats.levene(group1, group2)
print(f"Levene's test: W={stat:.4f}, p={p:.4f}")
# p > 0.05 suggests equal variances
```

### Two-Group Comparisons
```python
# Independent t-test (parametric)
stat, p = stats.ttest_ind(group1, group2)

# Welch's t-test (unequal variances)
stat, p = stats.ttest_ind(group1, group2, equal_var=False)

# Mann-Whitney U (non-parametric)
stat, p = stats.mannwhitneyu(group1, group2, alternative='two-sided')

# Effect size (Cohen's d)
pooled_std = np.sqrt(((len(group1)-1)*group1.std()**2 + (len(group2)-1)*group2.std()**2) / (len(group1)+len(group2)-2))
cohens_d = (group1.mean() - group2.mean()) / pooled_std
# 0.2=small, 0.5=medium, 0.8=large
```

### Multiple Groups
```python
# One-way ANOVA
stat, p = stats.f_oneway(group1, group2, group3)

# Kruskal-Wallis (non-parametric)
stat, p = stats.kruskal(group1, group2, group3)

# Post-hoc: Tukey HSD
from statsmodels.stats.multicomp import pairwise_tukeyhsd
tukey = pairwise_tukeyhsd(df['metric'], df['group'])
print(tukey)
```

### Categorical Data
```python
# Chi-square test of independence
contingency = pd.crosstab(df['var1'], df['var2'])
chi2, p, dof, expected = stats.chi2_contingency(contingency)

# Effect size (Cramér's V)
n = contingency.sum().sum()
min_dim = min(contingency.shape) - 1
cramers_v = np.sqrt(chi2 / (n * min_dim))
```

### Correlation
```python
# Pearson (linear, normal data)
r, p = stats.pearsonr(x, y)

# Spearman (monotonic, ordinal OK)
rho, p = stats.spearmanr(x, y)

# Interpretation: |r| < 0.3 weak, 0.3-0.7 moderate, > 0.7 strong
```

## Output Format

```
## Research Question
[Plain language question]

## Hypotheses
- H₀: [null hypothesis]
- H₁: [alternative hypothesis]

## Assumption Checks
| Assumption | Test | Result | Met? |
|------------|------|--------|------|
| Normality (Group A) | Shapiro-Wilk | p=0.XX | Yes/No |
| Equal Variance | Levene's | p=0.XX | Yes/No |

## Test Selection
Based on [assumptions], using [test name].

## Results
- Test statistic: X.XX
- p-value: X.XXXX
- Effect size: X.XX ([small/medium/large])
- 95% CI: [lower, upper]

## Interpretation
[Plain language: "Group A (M=X, SD=X) was significantly higher than Group B (M=X, SD=X), t(df)=X.XX, p=.XXX, d=X.XX. This represents a [small/medium/large] effect."]

## Caveats
- [Sample size consideration]
- [Assumption violation handling]
- [Multiple comparison adjustment if applicable]
```
