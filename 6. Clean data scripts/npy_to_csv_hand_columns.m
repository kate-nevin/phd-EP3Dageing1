%% Convert Athena 3D landmark files to CSV
% Right hand landmarks extracted and labelled by anatomical location
% Based on MediaPipe hand landmark ordering (0-20):
%   M0  = Wrist
%   M1  = Thumb CMC,  M2  = Thumb MCP,  M3  = Thumb IP,   M4  = Thumb tip
%   M5  = Index MCP,  M6  = Index PIP,  M7  = Index DIP,  M8  = Index tip
%   M9  = Middle MCP, M10 = Middle PIP, M11 = Middle DIP, M12 = Middle tip
%   M13 = Ring MCP,   M14 = Ring PIP,   M15 = Ring DIP,   M16 = Ring tip
%   M17 = Little MCP, M18 = Little PIP, M19 = Little DIP, M20 = Little tip

clear;
clc;

%% ── CONFIG ──────────────────────────────────────────────────────────────────
sourceDir = 'D:\1_EP3Dageing\5. Triangulation\landmarks';
outputDir = 'D:\1_EP3Dageing\7. Cleaned data\Raw 3D landmark csv data';

% Right hand landmark indices in full 75-landmark array (1-indexed for MATLAB)
% Python indices 33:53  →  MATLAB indices 34:54
HAND_START = 34;
HAND_END   = 54;
N_HAND     = 21;
%% ───────────────────────────────────────────────────────────────────────────

% Create output folder if it does not exist
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% Find all landmark files recursively
files = dir(fullfile(sourceDir, '**', '*_3Dlandmarks.npy'));
fprintf('Found %d landmark files.\n', length(files));

%% Build column names: M0_x, M0_y, M0_z ... M20_x, M20_y, M20_z
varNames = strings(1, N_HAND * 3);
idx = 1;
for lm = 0:(N_HAND-1)
    varNames(idx)   = sprintf('M%d_x', lm);
    varNames(idx+1) = sprintf('M%d_y', lm);
    varNames(idx+2) = sprintf('M%d_z', lm);
    idx = idx + 3;
end

%% Process files
for k = 1:length(files)
    try
        npyFile = fullfile(files(k).folder, files(k).name);
        fprintf('Processing %d/%d: %s\n', k, length(files), files(k).name);

        % Load NPY — shape: (240, 75, 3)
        data3D = readNPY(npyFile);

        % Extract right hand landmarks only (MATLAB indices 34:54)
        handData = data3D(:, HAND_START:HAND_END, :);  % (240, 21, 3)

        % Permute so coordinates are the inner dimension, then reshape
        % (240, 21, 3) → permute → (240, 3, 21) → reshape → (240, 63)
        handData_perm = permute(handData, [1, 3, 2]);
        reshaped = reshape(handData_perm, size(handData, 1), []);  % 240 x 63

        % Save as table
        T = array2table(reshaped, 'VariableNames', cellstr(varNames));

        [~, baseName, ~] = fileparts(files(k).name);
        writetable(T, fullfile(outputDir, [baseName '.csv']));

    catch ME
        fprintf('ERROR: %s\n', files(k).name);
        fprintf('%s\n', ME.message);
    end
end

fprintf('\nFinished.\n');