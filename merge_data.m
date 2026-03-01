red = readtable('winequality-red.csv', 'Delimiter', ';');
white = readtable('winequality-white.csv', 'Delimiter', ';');

fprintf('Red wine rows: %d', height(red));
fprintf('White wine rows: %d', height(white));

red.wineType = zeros(height(red), 1);
white.wineType = ones(height(white), 1);

data = [red; white];

fprintf('\nMerged red and white wine dataset: %d rows x %d columns\n', height(data), width(data));

fprintf('\nColumns:\n');
disp(data.Properties.VariableNames');

fprintf('\nDataframe head:\n');
disp(head(data, 5));

writetable(data, 'data.csv');