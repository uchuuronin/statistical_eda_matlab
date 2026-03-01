function outlierResults = detect_outliers(filename, fitResults, zscoreThreshold, iqrMultiplier, mahalSignificance)

data = readtable(filename);

numericCols = varfun(@isnumeric, data, 'OutputFormat', 'uniform');
numericData = data(:, numericCols);
colNames = numericData.Properties.VariableNames;

% separate continuous vs categorical
isBinary = false(1, length(colNames));
for i = 1:length(colNames)
    if length(unique(numericData.(colNames{i}))) <= 2
        isBinary(i) = true;
    end
end
continuousCols = colNames(~isBinary);
continuous_numericData = numericData(:, ~isBinary);
contMatrix = table2array(continuous_numericData);

outlierResults = struct();

fprintf('\nOutliers Detected:\n')
for i = 1:length(continuousCols)
    colData = contMatrix(:, i);
    colData_clean = colData(~isnan(colData));

    % find this column's best distribution from fitResults
    bestDist = '';
    for k = 1:length(fitResults)
        if strcmp(fitResults(k).column, continuousCols{i})
            bestDist = fitResults(k).bestDist;
            break;
        end
    end

    % choose method based on distribution
    if strcmp(bestDist, 'normal')
        % z-score for normal distributions
        method = 'zscore';
        zscores = (colData_clean - mean(colData_clean)) / std(colData_clean);
        outlierMask = abs(zscores) > zscoreThreshold;
    else
        % IQR for skewed distributions
        method = 'IQR';
        Q1 = quantile(colData_clean, 0.25);
        Q3 = quantile(colData_clean, 0.75);
        IQR_val = Q3 - Q1;
        outlierMask = colData_clean < (Q1 - iqrMultiplier*IQR_val) | ...
                      colData_clean > (Q3 + iqrMultiplier*IQR_val);
    end

    nOutliers = sum(outlierMask);
    pctOutliers = 100 * nOutliers / length(colData_clean);

    fprintf('%-22s method: %-8s outliers: %4d (%.2f%%)\n', ...
        continuousCols{i}, method, nOutliers, pctOutliers);

    outlierResults(i).column = continuousCols{i};
    outlierResults(i).method = method;
    outlierResults(i).nOutliers = nOutliers;
    outlierResults(i).pctOutliers = pctOutliers;
    outlierResults(i).bestDist = bestDist;
end

%% Mahalanobis distance to understand multivariate outliers
fprintf('\nMahalanobis Distance (multivariate):\n');
cleanMatrix = contMatrix(~any(isnan(contMatrix), 2), :);
[sigma_robust, mu_robust] = robustcov(cleanMatrix); % Minimum Covariance Determinant
diff = cleanMatrix - mu_robust;
mahal_dist = diag(diff * (sigma_robust \ diff'));

chiThreshold = chi2inv(mahalSignificance, size(cleanMatrix, 2));  % chi2 threshold
mahalOutliers = sum(mahal_dist > chiThreshold);
fprintf('Multivariate outliers (Mahalanobis): %d (%.2f%%)\n', ...
    mahalOutliers, 100*mahalOutliers/size(cleanMatrix,1));

outlierResults(end+1).column = 'multivariate';
outlierResults(end).method = 'mahalanobis';
outlierResults(end).nOutliers = mahalOutliers;
outlierResults(end).pctOutliers = 100*mahalOutliers/size(cleanMatrix,1);
outlierResults(end).bestDist = 'N/A';
end