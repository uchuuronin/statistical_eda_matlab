filename = 'data.csv';
correlationThreshold = 0.6;
zscoreThreshold = 3;
iqrMultiplier = 1.5;
mahalSignificance = 0.999;
outlierThresholdHigh = 5.0;
outlierThresholdMed  = 1.0;


fitResults = distribution(filename);
correlationResults = correlation(filename, correlationThreshold);
outlierResults = detect_outliers(filename, fitResults, zscoreThreshold, iqrMultiplier, mahalSignificance);

recommendations = recommend(fitResults, correlationResults, outlierResults, outlierThresholdHigh, outlierThresholdMed);

summary_dashboard(fitResults, correlationResults, outlierResults, recommendations);