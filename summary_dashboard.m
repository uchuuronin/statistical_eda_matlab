function summary_dashboard(fitResults, correlationResults, outlierResults, recommendations)

fig = uifigure('Name', 'EDA Overview', 'Position', [100 100 1100 700]);

tabGroup = uitabgroup(fig, 'Position', [10 10 1080 680]);

tab1 = uitab(tabGroup, 'Title', 'Summary');
tab2 = uitab(tabGroup, 'Title', 'Outliers');
tab3 = uitab(tabGroup, 'Title', 'Correlations');
tab4 = uitab(tabGroup, 'Title', 'Recommendations');

%% TAB 1: TLDR
nCols = length(fitResults);
nTransform = sum(cellfun(@(d) ismember(d, {'lognormal','loglogistic','gamma','exponential'}), {fitResults.bestDist}));
nHighOutlier = sum(cellfun(@(p) p > 5.0, {outlierResults(1:end-1).pctOutliers}));
nMedOutlier = sum(cellfun(@(p) p > 1.0 && p <= 5.0, {outlierResults(1:end-1).pctOutliers}));
nCorr = length(correlationResults);

mahalPct = 0;
for i = 1:length(outlierResults)
    if strcmp(outlierResults(i).column, 'multivariate')
        mahalPct = outlierResults(i).pctOutliers;
        break;
    end
end

colNames = {'Feature', 'Best Fit', 'Outliers %', 'Transform', 'Scaling'};
tableData = {};

for i = 1:length(fitResults)
    col = fitResults(i).column;
    dist = fitResults(i).bestDist;

    if strcmp(dist, 'lognormal') || strcmp(dist, 'loglogistic')
        transform = 'log transform';
    elseif strcmp(dist, 'gamma')
        transform = 'sqrt transform';
    elseif strcmp(dist, 'exponential')
        transform = 'log transform';
    elseif strcmp(dist, 'normal')
        transform = 'none';
    else
        transform = 'unknown';
    end

    pct = 0;
    scaling = '';
    for j = 1:length(outlierResults)
        if strcmp(outlierResults(j).column, col)
            pct = outlierResults(j).pctOutliers;
            if pct > 5.0
                scaling = 'robust scaler';
            elseif pct > 1.0
                scaling = 'winsorization';
            else
                scaling = 'standard scaler';
            end
            break;
        end
    end

    tableData{end+1, 1} = col;
    tableData{end, 2} = dist;
    tableData{end, 3} = sprintf('%.2f%%', pct);
    tableData{end, 4} = transform;
    tableData{end, 5} = scaling;
end

uitable(tab1, ...
    'Data', tableData, ...
    'ColumnName', colNames, ...
    'Position', [10 220 1055 420], ...
    'ColumnWidth', {220, 150, 100, 180, 180});

headerText = sprintf([ ...
    'TLDR: %d columns analyzed   |   ' ...
    '%d need transforms   |   ' ...
    '%d high outlier rate (>5%%)   |   ' ...
    '%d moderate outlier rate (1-5%%)   |   ' ...
    '%d high correlation pairs   |   ' ...
    'Multivariate outlier rate: %.2f%%'], ...
    nCols, nTransform, nHighOutlier, nMedOutlier, nCorr, mahalPct);

uilabel(tab1, ...
    'Text', headerText, ...
    'Position', [10 185 1060 35], ...
    'FontSize', 12, ...
    'FontWeight', 'bold', ...
    'WordWrap', 'on');

uilabel(tab1, 'Text', 'High Correlation Pairs', ...
    'Position', [10 148 300 22], 'FontSize', 12, 'FontWeight', 'bold');

corrStr = '';
if ~isempty(correlationResults) && isstruct(correlationResults) && ~isempty(fieldnames(correlationResults))
    for i = 1:length(correlationResults)
        corrStr = [corrStr sprintf('%s <-> %s (r=%.2f)     ', ...
            correlationResults(i).col1, correlationResults(i).col2, correlationResults(i).r)];
    end
end
uilabel(tab1, 'Text', corrStr, ...
    'Position', [10 123 1055 25], 'FontSize', 11, 'WordWrap', 'on');

uilabel(tab1, 'Text', 'Key Insight', ...
    'Position', [10 93 300 22], 'FontSize', 12, 'FontWeight', 'bold');

logCols = {};
for i = 1:length(fitResults)
    if ismember(fitResults(i).bestDist, {'lognormal','loglogistic','exponential'})
        for j = 1:length(outlierResults)
            if strcmp(outlierResults(j).column, fitResults(i).column) && outlierResults(j).pctOutliers > 1.0
                logCols{end+1} = fitResults(i).column;
                break;
            end
        end
    end
end
if ~isempty(logCols)
    crossStr = sprintf('%d columns (%s) benefit from log transform before scaling to compress outliers naturally', ...
        length(logCols), strjoin(logCols, ', '));
else
    crossStr = 'No cross-stage insights found.';
end
uilabel(tab1, 'Text', crossStr, ...
    'Position', [10 68 1055 25], 'FontSize', 11, 'WordWrap', 'on');

uilabel(tab1, 'Text', 'Multivariate Outliers', ...
    'Position', [10 43 300 22], 'FontSize', 12, 'FontWeight', 'bold');

if mahalPct > 20
    mahalNote = sprintf('%.2f%% outlier rate likely due to merged distributions. Consider Isolation Forest before clustering.', mahalPct);
elseif mahalPct > 10
    mahalNote = sprintf('%.2f%% outlier rate, review before clustering.', mahalPct);
else
    mahalNote = sprintf('%.2f%% outlier rate. This is an acceptable margin.', mahalPct);
end
uilabel(tab1, 'Text', mahalNote, ...
    'Position', [10 18 1055 25], 'FontSize', 11, 'WordWrap', 'on');

%% TAB 2: Outlier Overview
cols = {};
pcts = [];
for i = 1:length(outlierResults)
    if ~strcmp(outlierResults(i).column, 'multivariate')
        cols{end+1} = outlierResults(i).column;
        pcts(end+1) = outlierResults(i).pctOutliers;
    end
end

ax2 = uiaxes(tab2, 'Position', [30 30 1020 620]);
b = bar(ax2, pcts);
ax2.XTick = 1:length(cols);
ax2.XTickLabel = cols;
ax2.XTickLabelRotation = 35;
ax2.YLabel.String = 'Outlier %';
ax2.Title.String = 'Outlier Rate per Column';
yline(ax2, 5.0, 'r--', 'LineWidth', 1.5, 'Label', 'High threshold (5%)');
yline(ax2, 1.0, 'b--', 'LineWidth', 1.5, 'Label', 'Med threshold (1%)');

% color bars by severity
cdata = zeros(length(pcts), 3);
for i = 1:length(pcts)
    if pcts(i) > 5.0
        cdata(i,:) = [0.85 0.2 0.2];   % red
    elseif pcts(i) > 1.0
        cdata(i,:) = [0.95 0.6 0.1];   % orange
    else
        cdata(i,:) = [0.2 0.7 0.3];    % green
    end
end
b.CData = cdata;
b.FaceColor = 'flat';

%% TAB 3: Correlation Overview
if isempty(correlationResults) || ~isstruct(correlationResults) || isempty(fieldnames(correlationResults))
    uilabel(tab3, 'Text', 'No high correlation pairs found above threshold', ...
        'Position', [30 300 600 40], 'FontSize', 14);
else
    spearmanData = {};
    pbData = {};
    cramerData = {};

    for i = 1:length(correlationResults)
        row = {correlationResults(i).col1, correlationResults(i).col2, sprintf('%.4f', correlationResults(i).r)};
        if strcmp(correlationResults(i).type, 'spearman')
            spearmanData(end+1, :) = row;
        elseif strcmp(correlationResults(i).type, 'point-biserial')
            pbData(end+1, :) = row;
        elseif strcmp(correlationResults(i).type, 'cramers-v')
            cramerData(end+1, :) = row;
        end
    end

    yPos = 630;

    %% Spearman
    uilabel(tab3, 'Text', 'Key Spearman Correlations Identified', ...
        'Position', [10 yPos 800 25], 'FontSize', 14, 'FontWeight', 'bold');

    if isfile('pearson_correlation.png') && isfile('spearman_correlation.png')
        uibutton(tab3, 'Text', 'View Heatmaps', ...
            'Position', [850 yPos 200 25], ...
            'FontSize', 12, ...
            'ButtonPushedFcn', @(btn, event) open_heatmap_window());
    end
    yPos = yPos - 30;

    if ~isempty(spearmanData)
        nRows = size(spearmanData, 1);
        tableH = nRows * 35 + 50;
        uitable(tab3, 'Data', spearmanData, ...
            'ColumnName', {'Feature 1', 'Feature 2', 'r'}, ...
            'Position', [10 yPos-tableH 1100 tableH], ...
            'ColumnWidth', {420, 420, 180});
        yPos = yPos - tableH - 20;
    else
        uilabel(tab3, 'Text', 'No high Spearman pairs above threshold', ...
            'Position', [10 yPos-25 800 22], 'FontSize', 14);
        yPos = yPos - 35;
    end

    yPos = yPos - 20;

    %% Point-Biserial
    uilabel(tab3, 'Text', 'Key Point-Biserial Correlations Identified', ...
        'Position', [10 yPos 800 25], 'FontSize', 14, 'FontWeight', 'bold');

    if ~isempty(pbData)
        uibutton(tab3, 'Text', 'View Plot', ...
            'Position', [850 yPos 200 25], ...
            'FontSize', 12, ...
            'ButtonPushedFcn', @(btn, event) open_pb_window(pbData));
    end
    yPos = yPos - 30;

    if ~isempty(pbData)
        nRows = size(pbData, 1);
        tableH = nRows * 35 + 50;
        uitable(tab3, 'Data', pbData, ...
            'ColumnName', {'Categorical', 'Continuous', 'r'}, ...
            'Position', [10 yPos-tableH 1100 tableH], ...
            'ColumnWidth', {420, 420, 180});
        yPos = yPos - tableH - 20;
    else
        uilabel(tab3, 'Text', 'No categorical columns detected; point-biserial not computed', ...
            'Position', [10 yPos-25 800 22], 'FontSize', 14);
        yPos = yPos - 35;
    end

    yPos = yPos - 20;

    %% Cramers V
    uilabel(tab3, 'Text', "Key Cramer's V Relations Identified", ...
        'Position', [10 yPos 800 25], 'FontSize', 14, 'FontWeight', 'bold');
    
    if ~isempty(cramerData)
        uibutton(tab3, 'Text', 'View Heatmap', ...
            'Position', [850 yPos 200 25], ...
            'FontSize', 12, ...
            'ButtonPushedFcn', @(btn, event) open_cramer_window(cramerData));
    end
    yPos = yPos - 30;
    
    if ~isempty(cramerData)
        nRows = size(cramerData, 1);
        tableH = nRows * 35 + 50;
        uitable(tab3, 'Data', cramerData, ...
            'ColumnName', {'Categorical 1', 'Categorical 2', 'V'}, ...
            'Position', [10 yPos-tableH 1100 tableH], ...
            'ColumnWidth', {420, 420, 180});
        yPos = yPos - tableH - 15;
    else
        uilabel(tab3, 'Text', 'Fewer than 2 categorical columns; Cramers V not computed', ...
            'Position', [10 yPos-25 800 22], 'FontSize', 14);
        yPos = yPos - 35;
    end
    
    yPos = yPos - 20;
    uilabel(tab3, ...
        'Text', 'Note: tree-based models handle multicollinearity natively. For linear models or KNN, consider PCA or feature dropping.', ...
        'Position', [10 yPos 1100 25], 'FontSize', 12, 'WordWrap', 'on');
end

%% TAB 4: Recommendations Overview
recData = {};
for i = 1:length(recommendations)
    recData{end+1, 1} = recommendations(i).column;
    recData{end, 2} = recommendations(i).type;
    recData{end, 3} = recommendations(i).recommendation;
end

uitable(tab4, ...
    'Data', recData, ...
    'ColumnName', {'Column', 'Type', 'Recommendation'}, ...
    'Position', [10 10 1055 640], ...
    'ColumnWidth', {150, 100, 780});

end



%% Helper funcs
function open_heatmap_window()
    f = uifigure('Name', 'Correlation Heatmaps', 'Position', [100 100 1100 550]);
    axP = uiaxes(f, 'Position', [20 20 520 500]);
    imshow(imread('pearson_correlation.png'), 'Parent', axP);
    axP.Title.String = 'Pearson Heatmap';
    axP.Title.FontSize = 13;
    axS = uiaxes(f, 'Position', [560 20 520 500]);
    imshow(imread('spearman_correlation.png'), 'Parent', axS);
    axS.Title.String = 'Spearman Heatmap';
    axS.Title.FontSize = 13;
end

function open_pb_window(pbData)
    pbCols = pbData(:, 2);
    pbVals = cellfun(@str2double, pbData(:, 3));
    f = uifigure('Name', 'Point-Biserial Correlation', 'Position', [100 100 800 400]);
    ax = uiaxes(f, 'Position', [20 20 760 360]);
    bh = barh(ax, pbVals);
    ax.YTick = 1:length(pbCols);
    ax.YTickLabel = pbCols;
    ax.XLabel.String = 'r value';
    ax.Title.String = 'Point-Biserial r';
    ax.Title.FontSize = 13;
    ax.FontSize = 12;
    xline(ax, 0, 'k-', 'LineWidth', 1.5);
    xline(ax, 0.6, 'r--', 'LineWidth', 1.5);
    xline(ax, -0.6, 'r--', 'LineWidth', 1.5);
    cdata = zeros(length(pbVals), 3);
    for i = 1:length(pbVals)
        if pbVals(i) > 0
            cdata(i,:) = [0.2 0.5 0.8];
        else
            cdata(i,:) = [0.8 0.3 0.2];
        end
    end
    bh.CData = cdata;
    bh.FaceColor = 'flat';
end

function open_cramer_window(cramerData)
    cramerVals = cellfun(@str2double, cramerData(:, 3));
    cats1 = cramerData(:, 1);
    cats2 = cramerData(:, 2);
    allCats = unique([cats1; cats2]);
    n = length(allCats);
    vMatrix = eye(n);
    for i = 1:size(cramerData, 1)
        r = find(strcmp(allCats, cramerData{i,1}));
        c = find(strcmp(allCats, cramerData{i,2}));
        vMatrix(r,c) = cramerVals(i);
        vMatrix(c,r) = cramerVals(i);
    end
    f = uifigure('Name', "Cramer's V", 'Position', [100 100 600 500]);
    ax = uiaxes(f, 'Position', [20 20 560 460]);
    heatmap(ax, allCats, allCats, vMatrix, ...
        'Title', "Cramer's V Heatmap", ...
        'ColorbarVisible', 'on');
end