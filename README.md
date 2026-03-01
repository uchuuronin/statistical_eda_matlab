# Statistical EDA Tool (run using MATLAB)
A brief exploratory project built to practice statistical analysis and preprocessing concepts.

## What it does
Takes a dataset and automatically profiles it across three stages:

- **Distribution fitting**: fits 5 distributions per feature and ranks by AIC/BIC to find the best fit
- **Correlation analysis**: computes Spearman, point-biserial, and Cramér's V correlations depending on feature types
- **Outlier detection**: uses z-score, IQR, or Mahalanobis distance depending on each feature's distribution

Then generates preprocessing recommendations (transforms, scaling, feature dropping) based on all three stages combined, with notes on how recommendations change depending on the model type (linear, tree-based, distance-based, clustering).

Results are shown in an interactive MATLAB dashboard with 4 tabs: summary, outlier chart, correlation analysis, and full recommendations.

## Dataset
Wine Quality dataset from UCI (red and white merged, 6497 rows, 12 features.) 
Can be run on any dataset though, just upload in base folder and update `filename` variable in `run_eda.m`

## How to run
Open MATLAB, set the folder as your working directory, and run:
```matlab
run_eda
```

## Requirements
MATLAB with Statistics and Machine Learning Toolbox.