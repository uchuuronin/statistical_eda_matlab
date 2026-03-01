function recommendations = recommend(fitResults, correlationResults, outlierResults, outlierThresholdHigh, outlierThresholdMed)

fprintf('\n');
recommendations = struct();
recCount = 0;

fprintf('\nRecommendations based on distribution\n');

for i = 1:length(fitResults)
    col = fitResults(i).column;
    dist = fitResults(i).bestDist;
    rec = '';

    if strcmp(dist, 'lognormal') || strcmp(dist, 'loglogistic')
        rec = 'apply log transform; distribution is right-skewed ';
    elseif strcmp(dist, 'gamma')
        rec = 'apply sqrt transform; distribution is moderate right skew';
    elseif strcmp(dist, 'exponential')
        rec = 'apply log transform; distribution is heavy right skew';
    elseif strcmp(dist, 'normal')
        rec = 'no transform needed; distribution is normally distributed';
    end

    if ~isempty(rec)
        recCount = recCount + 1;
        recommendations(recCount).column = col;
        recommendations(recCount).type = 'transform';
        recommendations(recCount).recommendation = rec;
        fprintf('%-22s == %s\n', col, rec);
    end

    if strcmp(dist, 'lognormal') || strcmp(dist, 'loglogistic')
        fprintf('%-22s \t[note] for KNN/SVM, heavy tails distort distances; scaling after log transform is critical\n', '');
        fprintf('%-22s \t[note] normality assumption violated; avoid Gaussian Naive Bayes or use kernel density variant\n', '');
    elseif strcmp(dist, 'normal')
        fprintf('%-22s \t[note] normally distributed; Gaussian Naive Bayes and linear models are safe to use\n', '');
    end
end

fprintf('\nRecommendations based on correlation\n');

if isempty(correlationResults) || ~isstruct(correlationResults) || isempty(fieldnames(correlationResults))
    fprintf('No high correlation pairs found above threshold\n');
else
    for i = 1:length(correlationResults)
        col1 = correlationResults(i).col1;
        col2 = correlationResults(i).col2;
        r = correlationResults(i).r;
        type = correlationResults(i).type;

        rec = sprintf('multicollinearity detected with %s (%s r=%.2f); would inflate coefficients, so consider dropping for linear models or apply PCA', col2, type, r);
        recCount = recCount + 1;
        recommendations(recCount).column = col1;
        recommendations(recCount).type = 'feature_drop';
        recommendations(recCount).recommendation = rec;
        fprintf('%-22s == %s\n', col1, rec);

        fprintf('%-22s \t[note] for KNN/distance-based models, correlated features double-weight that direction in feature space; apply PCA before KNN\n', '');
        fprintf('%-22s \t[note] tree-based models (RandomForest, XGBoost) handle multicollinearity natively; dropping not required\n', '');
    end
end

fprintf('\nRecommendations based on outlier analysis\n');

for i = 1:length(outlierResults)
    col = outlierResults(i).column;
    pct = outlierResults(i).pctOutliers;

    if strcmp(col, 'multivariate')
         fprintf('%-22s \t[note] multivariate outlier rate %.2f%%; for clustering (KMeans, GMM) centroids will be distorted; consider Isolation Forest preprocessing\n', ...
            'multivariate', outlierResults(i).pctOutliers);
        continue  % skip mahalanobis row here
    end

    if pct > outlierThresholdHigh
        rec = sprintf('use robust scaler; high outlier rate (%.2f%%)', pct);
    elseif pct > outlierThresholdMed
        rec = sprintf('consider winsorization; moderate outlier rate (%.2f%%)', pct);
    else
        rec = sprintf('standard scaler acceptable; low outlier rate (%.2f%%)', pct);
    end

    recCount = recCount + 1;
    recommendations(recCount).column = col;
    recommendations(recCount).type = 'scaling';
    recommendations(recCount).recommendation = rec;
    fprintf('%-22s == %s\n', col, rec);

    if pct > outlierThresholdHigh
        fprintf('%-22s \t[note] for SVM, outliers near margin significantly affect hyperplane. Capping/Winsorization before training recommended\n', '');
    end
end

fprintf('\nFurther recommendations based on all three\n');
for i = 1:length(fitResults)
    col = fitResults(i).column;
    dist = fitResults(i).bestDist;

    % find matching outlier result
    pct = 0;
    for j = 1:length(outlierResults)
        if strcmp(outlierResults(j).column, col)
            pct = outlierResults(j).pctOutliers;
            break;
        end
    end

    if (strcmp(dist, 'lognormal') || strcmp(dist, 'loglogistic')) && pct > outlierThresholdMed
        fprintf('%-22s \t[note] log transform will naturally compress outliers; apply transform first, then reassess outlier rate\n', col);
    end
end


fprintf('\nTotal recommendations generated: %d\n', recCount);

end