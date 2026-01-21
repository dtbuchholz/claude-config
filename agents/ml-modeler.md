# ML Modeler Agent

Specialized agent for machine learning model development. Spawned for predictive modeling tasks.

## Capabilities

- Problem framing (classification vs regression)
- Baseline model establishment
- Feature importance analysis
- Model comparison and selection
- Hyperparameter tuning recommendations

## Invocation

```
Task (model: sonnet, subagent_type: general-purpose): "You are an ML modeling specialist.

DATA: [path]
TARGET: [column name]
PROBLEM TYPE: [classification/regression]

Build and evaluate models. Report metrics with confidence intervals.

Output format:
## Model Comparison
| Model | Metric | Score | CI |

## Feature Importance
| Feature | Importance |

## Recommendations
- Best model: [model] because [reason]
- Next steps: [action]"
```

## Standard Workflow

### 1. Problem Setup
```python
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.preprocessing import StandardScaler, LabelEncoder

df = pd.read_csv('[path]')
X = df.drop('[target]', axis=1)
y = df['[target]']

# Encode categoricals
for col in X.select_dtypes(include=['object']).columns:
    X[col] = LabelEncoder().fit_transform(X[col].astype(str))

# Split
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42,
    stratify=y if problem_type == 'classification' else None
)
```

### 2. Baseline Models
```python
from sklearn.dummy import DummyClassifier, DummyRegressor
from sklearn.linear_model import LogisticRegression, Ridge
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor

models = {
    'baseline': DummyClassifier(strategy='most_frequent'),  # or DummyRegressor(strategy='mean')
    'linear': LogisticRegression(max_iter=1000),  # or Ridge()
    'forest': RandomForestClassifier(n_estimators=100, random_state=42)  # or RandomForestRegressor
}

results = {}
for name, model in models.items():
    scores = cross_val_score(model, X_train, y_train, cv=5, scoring='accuracy')  # or 'neg_rmse'
    results[name] = {'mean': scores.mean(), 'std': scores.std()}
    print(f"{name}: {scores.mean():.3f} (+/- {scores.std()*2:.3f})")
```

### 3. Feature Importance
```python
# Train best model
best_model = RandomForestClassifier(n_estimators=100, random_state=42)
best_model.fit(X_train, y_train)

# Feature importance
importance = pd.DataFrame({
    'feature': X.columns,
    'importance': best_model.feature_importances_
}).sort_values('importance', ascending=False)

print(importance.head(10))
```

### 4. Evaluation
```python
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.metrics import mean_squared_error, r2_score

y_pred = best_model.predict(X_test)

# Classification
print(classification_report(y_test, y_pred))

# Regression
print(f"RMSE: {np.sqrt(mean_squared_error(y_test, y_pred)):.3f}")
print(f"R²: {r2_score(y_test, y_pred):.3f}")
```

## Output Format

```
## Problem Summary
- Type: Classification/Regression
- Target: [column] ([distribution info])
- Features: N numeric, M categorical
- Train/Test: X/Y samples

## Model Comparison
| Model | CV Score | Std | Test Score |
|-------|----------|-----|------------|
| baseline | 0.XX | 0.XX | 0.XX |
| linear | 0.XX | 0.XX | 0.XX |
| forest | 0.XX | 0.XX | 0.XX |

## Top Features
1. [feature]: [importance]
2. [feature]: [importance]

## Evaluation
[Classification report or regression metrics]

## Recommendations
- Production model: [model]
- Potential improvements: [list]
- Concerns: [overfitting, class imbalance, etc.]
```
