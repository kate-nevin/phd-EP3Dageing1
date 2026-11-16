% Define source and destination directories
srcDir = 'C:\Users\multisensorylab\Documents\EPs_Exp\Draft 2 - Experiment\Data\973368_F2\Video';
destDir = 'C:\Users\multisensorylab\Documents\EPs_Exp\Draft 2 - Experiment\videos\973368';

% Get all .mp4 files in the source directory
videoFiles = dir(fullfile(srcDir, '*.mp4'));

if isempty(videoFiles)
    error('No .mp4 files found in: %s', srcDir);
end

fprintf('Found %d video files.\n', length(videoFiles));

% Loop through each video file
for i = 1:length(videoFiles)
    fileName = videoFiles(i).name;

    % Extract trial number using regex (digits after 'trial_')
    trialMatch = regexp(fileName, 'trial_(\d+)', 'tokens');

    % Extract camera number using regex (digits after 'camera-')
    camMatch = regexp(fileName, 'camera-(\d+)', 'tokens');

    if isempty(trialMatch) || isempty(camMatch)
        fprintf('Could not extract trial/camera number from: %s — skipping.\n', fileName);
        continue;
    end

    trialNum = trialMatch{1}{1};
    camNum   = camMatch{1}{1};

    trialFolder  = ['trial_' trialNum];
    newFileName  = ['cam' camNum '.mp4'];

    % Build destination folder path and create if needed
    trialDir = fullfile(destDir, trialFolder);
    if ~exist(trialDir, 'dir')
        mkdir(trialDir);
        fprintf('Created folder: %s\n', trialDir);
    end

    % Copy file to trial folder with new name
    srcFile  = fullfile(srcDir, fileName);
    destFile = fullfile(trialDir, newFileName);
    copyfile(srcFile, destFile);
    fprintf('Copied %s → %s\n', fileName, newFileName);
end

fprintf('\nDone. All videos organised and renamed.\n');