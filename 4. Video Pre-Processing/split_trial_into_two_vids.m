% Divide videos into first and second segments (first 240 and last 240 frames)
% Kate
% 03 11 2026
clear;
clc;

%% Specify directories
source_dir = 'D:\1_EP3Dageing\4. Video Pre-Processing\0. videos_to_be_split';
videos_dest_dir = 'D:\1_EP3Dageing\4. Video Pre-Processing\1. split_videos_to_be_processed';

%% Find all trial folders within videos_long
% Trial folders are named: XXXXXX_trial_XX (6-digit participantID, trial 01-24)
trialFolders = dir(fullfile(source_dir, '*_trial_*'));
trialFolders = trialFolders([trialFolders.isdir]); % Keep only directories

% Filter to match the expected naming pattern (6-digit ID + _trial_ + 2-digit number)
validFolders = {};
for i = 1:length(trialFolders)
    if ~isempty(regexp(trialFolders(i).name, '^\d{6}_trial_\d{2}$', 'once'))
        validFolders{end+1} = trialFolders(i).name;
    end
end

if isempty(validFolders)
    error('No valid trial folders found in: %s', source_dir);
end
fprintf('Found %d trial folders.\n', length(validFolders));

%% Parameters
TOTAL_FRAMES   = 720;
SEGMENT_FRAMES = 240; % 4 seconds at 60 fps
FRAME_RATE     = 60;
LAST_START     = TOTAL_FRAMES - SEGMENT_FRAMES + 1; % Frame 481

%% Process each trial folder
for f = 1:length(validFolders)
    folderName = validFolders{f};
    trialPath  = fullfile(source_dir, folderName);

    % Parse participantID and trial number from folder name
    tokens = regexp(folderName, '^(\d{6})_trial_(\d{2})$', 'tokens');
    tokens = tokens{1};
    participantID = tokens{1};
    trialNum      = tokens{2};

    fprintf('\nProcessing folder: %s\n', folderName);

    % Define output folder names
    firstFolder  = fullfile(videos_dest_dir, sprintf('%s_trial_%s_first',  participantID, trialNum));
    secondFolder = fullfile(videos_dest_dir, sprintf('%s_trial_%s_second', participantID, trialNum));

    % Create output folders if they don't exist
    for outFolder = {firstFolder, secondFolder}
        if ~exist(outFolder{1}, 'dir')
            mkdir(outFolder{1});
            fprintf('  Created: %s\n', outFolder{1});
        end
    end

    % Process each camera video
    camFiles = {'cam0.mp4', 'cam1.mp4', 'cam2.mp4'};

    for c = 1:length(camFiles)
        camFile   = camFiles{c};
        videoPath = fullfile(trialPath, camFile);

        if ~exist(videoPath, 'file')
            fprintf('  WARNING: %s not found, skipping.\n', camFile);
            continue;
        end

        fprintf('  Processing %s...\n', camFile);

        % Read all frames into memory
        v      = VideoReader(videoPath);
        frames = cell(TOTAL_FRAMES, 1);
        frameCount = 0;

        while hasFrame(v) && frameCount < TOTAL_FRAMES
            frameCount         = frameCount + 1;
            frames{frameCount} = readFrame(v);
        end

        if frameCount ~= TOTAL_FRAMES
            fprintf('  WARNING: Expected %d frames but found %d in %s. Skipping.\n', ...
                    TOTAL_FRAMES, frameCount, camFile);
            continue;
        end

        % --- Write first segment (frames 1-240) ---
        outPathFirst = fullfile(firstFolder, camFile);
        vwFirst = VideoWriter(outPathFirst, 'MPEG-4');
        vwFirst.FrameRate = FRAME_RATE;
        open(vwFirst);
        for i = 1:SEGMENT_FRAMES
            writeVideo(vwFirst, frames{i});
        end
        close(vwFirst);
        fprintf('    Saved first segment:  %s\n', outPathFirst);

        % --- Write second segment (frames 481-720) ---
        outPathSecond = fullfile(secondFolder, camFile);
        vwSecond = VideoWriter(outPathSecond, 'MPEG-4');
        vwSecond.FrameRate = FRAME_RATE;
        open(vwSecond);
        for i = LAST_START:TOTAL_FRAMES
            writeVideo(vwSecond, frames{i});
        end
        close(vwSecond);
        fprintf('    Saved second segment: %s\n', outPathSecond);
    end
end

fprintf('\nAll done!\n');