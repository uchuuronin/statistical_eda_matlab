function fitResults = distribution(filename)

data = readtable(filename);

numRows = height(data);
numCols = width(data);

fprintf('Rows: %d | Columns: %d\n', numRows, numCols);

numericCols = varfun(@isnumeric, data, 'OutputFormat', 'uniform');
numericData = data(:, numericCols);
colNames = numericData.Properties.VariableNames;

fprintf('Numeric columns found: %d\n', length(colNames));
disp(colNames');

fprintf('Running distributions to find bestfit!')
distributions = {'normal', 'exponential', 'loglogistic', 'gamma', 'lognormal'};
positiveOnlyDistributions = {'exponential', 'loglogistic', 'gamma', 'lognormal'};

% also separating binary/categorical columns for later use
isBinary = false(1, length(colNames));
for i = 1:length(colNames)
    uniqueVals = unique(numericData.(colNames{i}));
    if length(uniqueVals) <= 2
        isBinary(i) = true;
    end
end
categoricalCols = colNames(isBinary);
continuousCols = colNames(~isBinary);

fprintf('Continuous columns: %d | Categorical columns: %d\n', length(continuousCols), length(categoricalCols));

continuous_numericData = numericData(:, ~isBinary);
colNames = continuousCols;

fitResults = struct();

for i = 1:length(colNames)
    colData = continuous_numericData.(colNames{i});
    colData = colData(~isnan(colData));

    
    fprintf('\nProcessing column: %s\n', colNames{i});

    bestAIC = inf;
    bestDist = '';

    for j = 1:length(distributions)
        try
            if ismember(distributions{j}, positiveOnlyDistributions)
                fitData = colData(colData > 0);
            else
                fitData = colData;
            end

            pd = fitdist(fitData, distributions{j});
            logL = sum(log(pdf(pd, fitData)));
            k = numel(pd.ParameterValues);
            n = numel(colData);

            aic = 2*k - 2*logL;
            bic = k*log(n) - 2*logL;

            fprintf('%-15s AIC: %10.2f  BIC: %10.2f\n', distributions{j}, aic, bic);

            if aic < bestAIC && ~isinf(aic)
                bestAIC = aic;
                bestDist = distributions{j};
            end
        catch
            fprintf('  %-15s could not be fitted\n', distributions{j});
        end
    end

    fprintf('Best fit: %s (AIC: %.2f)\n', bestDist, bestAIC);
    fitResults(i).column = colNames{i};
    fitResults(i).bestDist = bestDist;
    fitResults(i).bestAIC = bestAIC;
end