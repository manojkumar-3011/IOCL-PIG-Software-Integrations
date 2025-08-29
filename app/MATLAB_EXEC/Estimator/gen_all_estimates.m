function gen_all_estimates(filepath)
    if nargin < 1
        filepath = uigetdir('', 'Folder containing estimates.csv');
        if filepath == 0
            filepath = 'F:\Academic\GDbckpd_Projects\PROjects\FSP_ILI_2025\CSV_OUTPUT\results_250122-1339_[11 13]';
        end
    end

    % Read estimates data
    estm = readtable([filepath, '\estimates.csv']);
    col_names = estm.Properties.VariableNames;

    % Extract independent (x) and dependent (y) values
    x_vals = estm{:, end};        % Last column as x-values
    y_vals = estm{:, 1:end-1};    % All except last column as y-values

    % Ensure unique x-values
    [x_unique, idx] = unique(x_vals, 'stable');  % Keep order stable
    y_unique = y_vals(idx, :);                   % Corresponding y-values

    % Define interpolation range
    odo_all = ceil(min(x_unique)):floor(max(x_unique));

    % Use gridded interpolant for robustness
    F = griddedInterpolant(x_unique, y_unique, 'linear', 'none');
    itab_data = F(odo_all');

    % Convert to table and write to file
    estm_all = array2table([itab_data, odo_all'], 'VariableNames', col_names);
    writetable(estm_all, [filepath, '\all_estimates.csv']);
end
