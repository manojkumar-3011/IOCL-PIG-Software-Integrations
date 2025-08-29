current_folder = fileparts(mfilename("fullpath"));
source_folder = cd(current_folder);
% Get the parent directory of the 'patch' folder
patch_folder = fileparts(mfilename('fullpath')); % Absolute path of 'patch' folder
base_dir = fullfile(patch_folder, '..', 'CSV_OUTPUT'); % MATLAB folder at the same level
addpath(base_dir);
disp(base_dir);
% Get a list of all subfolders inside 'MATLAB/CSV_OUTPUT'
if ~isfolder(base_dir)
    error("MATLAB/CSV_OUTPUT directory not found!");
end

subfolders = dir(base_dir);
subfolders = subfolders([subfolders.isdir]); % Keep only directories
subfolders = subfolders(~ismember({subfolders.name}, {'.', '..'})); % Remove . and ..

% Loop through each subfolder
for i = 1:length(subfolders)
    folder_path = fullfile(base_dir, subfolders(i).name);
    
    % Check for 'estimates.csv' and absence of 'all_estimates.csv'
    if exist(fullfile(folder_path, 'estimates.csv'), 'file') && ...
       ~exist(fullfile(folder_path, 'all_estimates.csv'), 'file')
       
        fprintf('Processing: %s\n', folder_path);
        
        % Call gen_all_estimates for the folder
        gen_all_estimates(folder_path);
    else
        fprintf('Skipping: %s\n', folder_path);
    end
end
