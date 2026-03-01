function correlationResults = correlation(filename, correlationThreshold)
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
categoricalCols = colNames(isBinary);
continuous_numericData = numericData(:, ~isBinary);
categorical_numericData = numericData(:, isBinary);

contMatrix = table2array(continuous_numericData);

%% Pearson + Spearman on continuous columns
pearsonMatrix = corr(contMatrix, 'Type', 'Pearson', 'Rows', 'complete');
spearmanMatrix = corr(contMatrix, 'Type', 'Spearman', 'Rows', 'complete');

figure;
h1 = heatmap(continuousCols, continuousCols, pearsonMatrix, ...
    'Title', 'Pearson Correlation', ...
    'ColorbarVisible', 'on', ...
    'Colormap', redbluecmap);
saveas(gcf, 'pearson_correlation.png');
fprintf("\nPearsons corr heatmap generated\n");
close(gcf)

figure;
h2 = heatmap(continuousCols, continuousCols, spearmanMatrix, ...
    'Title', 'Spearman Correlation', ...
    'ColorbarVisible', 'on', ...
    'Colormap', redbluecmap);
saveas(gcf, 'spearman_correlation.png');
fprintf("\nSpearman corr heatmap generated\n");
close(gcf)

% flag high correlation pairs using spearman 
correlationResults = struct();
pairCount = 0;

fprintf('\n\nSpearman Correlation for continous vs continous feature analysis\n');
for i = 1:length(continuousCols)
    for j = i+1:length(continuousCols)
        r = spearmanMatrix(i,j);
        if abs(r) >= correlationThreshold
            pairCount = pairCount + 1;
            correlationResults(pairCount).col1 = continuousCols{i};
            correlationResults(pairCount).col2 = continuousCols{j};
            correlationResults(pairCount).r = r;
            correlationResults(pairCount).type = 'spearman';
            fprintf('High correlation: %-20s <-> %-20s r = %.4f\n', ...
                continuousCols{i}, continuousCols{j}, r);
        end
    end
end

%% Point-biserial: categorical vs continuous
if ~isempty(categoricalCols)
    fprintf('\nPoint Biserial for categorical vs continuous feature analysis\n');
    for c = 1:length(categoricalCols)
        catData = categorical_numericData.(categoricalCols{c});
        for i = 1:length(continuousCols)
            contData = contMatrix(:, i);
            r = corr(catData, contData, 'Type', 'Pearson', 'Rows', 'complete');
            if abs(r) >= correlationThreshold
                pairCount = pairCount + 1;
                correlationResults(pairCount).col1 = categoricalCols{c};
                correlationResults(pairCount).col2 = continuousCols{i};
                correlationResults(pairCount).r = r;
                correlationResults(pairCount).type = 'point-biserial';
                fprintf('High correlation: %-20s <-> %-20s r = %.4f\n', ...
                    categoricalCols{c}, continuousCols{i}, r);
            end
        end
    end
end

%% Cramers V: categorical vs categorical
if length(categoricalCols) >= 2
    fprintf('\nCrammers V for categorical vs categorical feature analysis\n');
    for c1 = 1:length(categoricalCols)
        for c2 = c1+1:length(categoricalCols)
            x = categorical_numericData.(categoricalCols{c1});
            y = categorical_numericData.(categoricalCols{c2});
            % contingency table
            [tbl, ~, ~] = crosstab(x, y);
            n = sum(tbl(:));
            chi2 = sum((tbl - n*tbl/sum(tbl(:))).^2 ./ (n*tbl/sum(tbl(:))), 'all');
            k = min(size(tbl));
            v = sqrt(chi2 / (n * (k-1)));
            fprintf('Cramers V: %-20s <-> %-20s V = %.4f\n', ...
                categoricalCols{c1}, categoricalCols{c2}, v);
        end
    end
end

fprintf('\nTotal high correlation pairs found: %d\n', pairCount);

end