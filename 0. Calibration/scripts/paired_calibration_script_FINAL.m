% IMPORTANT:
% Before starting, set Logitech app video quality to 720p, 60 fps.

% here the videos are saved as MP4 files

clear;
clc;
imaqreset;

%% --- Variables to adjust ---

% The length of the video recorded
seconds_video = 20;

% Manual focus value for each physical camera
manual_focus_cam1 = 0;
manual_focus_cam2 = 0;
manual_focus_cam3 = 0;

%% --- Set paths ---

% Folder name
% save_folder_name = "CT_" + string(CT) + "_dim_" + string(dim);

% Path where to save individual videos
outDir = 'C:\Users\multisensorylab\Documents\Kate\5. Pilot Experiments - Behavioural\Draft 3 - Final\calibration_videos_and_scripts\Extrinsic\';
% SaveDir = fullfile(outDir, save_folder_name);
SaveDir = outDir;

% Create main save folder only if it does NOT exist
if ~exist(SaveDir, 'dir')
    mkdir(SaveDir);
    fprintf('Created directory: %s\n', SaveDir);
else
    fprintf('Directory already exists: %s\n', SaveDir);
end

% Define paired calibration subfolders
paired_folders = {'camera_1-camera_2', 'camera_2-camera_3', 'camera_3-camera_1'};

% Create each subfolder inside SaveDir if it does not exist
for i = 1:length(paired_folders)
    subDir = fullfile(SaveDir, paired_folders{i});
    if ~exist(subDir, 'dir')
        mkdir(subDir);
        fprintf('Created subdirectory: %s\n', subDir);
    else
        fprintf('Subdirectory already exists: %s\n', subDir);
    end
end

%% --- Setup and open arduino ---
a = arduino('COM4', 'Uno', 'Libraries', 'Servo');
s = servo(a, 'D4');

%% --- Camera setup ---
fmt = 'MJPG_1280x720';

% Exactly seconds_video * 60 frames
Nframes = seconds_video * 60;

%% --- Sound setup (PsychToolbox) ---
nrchannels = 2; % stereo
freq = 44100;
beepLengthSecs = .1;
waitForDeviceStart = 1;
myBeep  = MakeBeep(1000, beepLengthSecs, freq);
myBeep2 = MakeBeep(1000,  beepLengthSecs, freq);


InitializePsychSound(1);
pahandle = PsychPortAudio('Open', [], 1, 0, freq, nrchannels);

%% --- Main loop ---
disp(' ');
disp('Available camera pairings: 1-2, 2-3, 3-1');
disp('Type q to quit.');
disp(' ');

writePosition(s, 0);

while true
    pairStr = strtrim(input('Enter camera pairing to record (example: 1-2): ', 's'));
    pairStr = erase(pairStr, ' ');

    if strcmpi(pairStr, 'q')
        disp('Exiting program.');
        break;
    end

    switch pairStr
        case {'1-2', '2-1'}
            camA = 1;
            camB = 2;
            pairFolder = 'camera_1-camera_2';

        case {'2-3', '3-2'}
            camA = 2;
            camB = 3;
            pairFolder = 'camera_2-camera_3';

        case {'3-1', '1-3'}
            camA = 3;
            camB = 1;
            pairFolder = 'camera_3-camera_1';

        otherwise
            fprintf('Invalid pairing: %s\n', pairStr);
            fprintf('Please enter 1-2, 2-3, 3-1, or q.\n\n');
            continue;
    end

    % --- Pair folder setup ---
    pairDir = fullfile(SaveDir, pairFolder);

    % Create pair folder if it does not exist
    if ~exist(pairDir, 'dir')
        mkdir(pairDir);
        fprintf('Created pair directory: %s\n', pairDir);
    else
        fprintf('Pair directory already exists: %s\n', pairDir);
    end

    % Check if recordings already exist
    oldFiles = dir(fullfile(pairDir, '*.mp4'));

    if ~isempty(oldFiles)
        redoAns = lower(strtrim(input( ...
            sprintf('Recording already exists for %s. Delete and redo? (y/n): ', pairFolder), 's')));

        if strcmp(redoAns, 'y')
            delete(fullfile(pairDir, '*.mp4'));
            fprintf('Old recordings deleted.\n');
        else
            fprintf('Skipping recording for %s.\n\n', pairFolder);
            continue;
        end
    end

    try
        recordCameraPair( ...
            camA, camB, fmt, Nframes, seconds_video, pairDir, ...
            manual_focus_cam1, manual_focus_cam2, manual_focus_cam3, ...
            pahandle, myBeep, myBeep2, waitForDeviceStart, s);

        fprintf('Finished recording pair %d-%d\n\n', camA, camB);

    catch ME
        warning('Recording failed for pair %d-%d: %s', camA, camB, ME.message);
    end
end

%% --- Cleanup ---
PsychPortAudio('Close');
imaqreset;
disp('All done.');

%% ========================================================================
%% Local functions
%% ========================================================================

function recordCameraPair(camA, camB, fmt, Nframes, seconds_video, pairDir, ...
    manual_focus_cam1, manual_focus_cam2, manual_focus_cam3, ...
    pahandle, myBeep, myBeep2, waitForDeviceStart, s)

    fprintf('\nPreparing cameras %d and %d...\n', camA, camB);

    % Create video input objects
    vidA = videoinput('winvideo', camA, fmt);
    vidB = videoinput('winvideo', camB, fmt);

    cleanupObj = onCleanup(@() cleanupVideoObjects(vidA, vidB)); 

    % Manual trigger
    triggerconfig(vidA, 'manual');
    triggerconfig(vidB, 'manual');

    % IMPORTANT: must be 0 so acquisition completes
    vidA.TriggerRepeat = 0;
    vidB.TriggerRepeat = 0;

    % Number of frames
    vidA.FramesPerTrigger = Nframes;
    vidB.FramesPerTrigger = Nframes;

    % Log to disk
    vidA.LoggingMode = 'disk';
    vidB.LoggingMode = 'disk';

    % Output paths
    fileA = fullfile(pairDir, sprintf('camera_%d.mp4', camA));
    fileB = fullfile(pairDir, sprintf('camera_%d.mp4', camB));

    % Create writers first, set FPS, then attach
    writerA = VideoWriter(fileA, 'MPEG-4');
    writerB = VideoWriter(fileB, 'MPEG-4');

    writerA.FrameRate = 60;
    writerB.FrameRate = 60;

    vidA.DiskLogger = writerA;
    vidB.DiskLogger = writerB;

    % Source objects
    srcA = getselectedsource(vidA);
    srcB = getselectedsource(vidB);

    % Optional tags
    srcA.Tag = 'motion detection setup';
    srcB.Tag = 'motion detection setup';

    % Apply manual focus before preview/start
    applyManualFocus(srcA, camA, manual_focus_cam1, manual_focus_cam2, manual_focus_cam3);
    applyManualFocus(srcB, camB, manual_focus_cam1, manual_focus_cam2, manual_focus_cam3);

    % Read back focus settings
    try
        fprintf('Cam%d FocusMode = %s, Focus = %g\n', camA, srcA.FocusMode, srcA.Focus);
    catch
        fprintf('Could not read back focus settings for Cam%d\n', camA);
    end

    try
        fprintf('Cam%d FocusMode = %s, Focus = %g\n', camB, srcB.FocusMode, srcB.Focus);
    catch
        fprintf('Could not read back focus settings for Cam%d\n', camB);
    end

    % Start cameras
    start(vidA);
    start(vidB);

    % Move the trigger
    writePosition(s, 0);

    % Preview
    preview(vidA);
    preview(vidB);

    fprintf('Press ENTER to start recording for cameras %d and %d\n', camA, camB);
    input('', 's');

    % Display that recording has started
    fprintf('Cameras %d and %d recording started!\n', camA, camB);

    % Start beep
    PsychPortAudio('FillBuffer', pahandle, [myBeep; myBeep]);
    PsychPortAudio('Start', pahandle);
    PsychPortAudio('Stop', pahandle, 1, 1);

    % Trigger video acquisition
    trigger(vidA);
    trigger(vidB);

    % Wait until just before the video ends
    pause(seconds_video - 0.5);

    % Move the arm near the end of recording
    writePosition(s, 1);

    % Wait for acquisition to complete
    wait(vidA, seconds_video + 20);
    wait(vidB, seconds_video + 20);

    stop(vidA);
    stop(vidB);

    closepreview(vidA);
    closepreview(vidB);

    % Stop beep
    PsychPortAudio('FillBuffer', pahandle, [myBeep2; myBeep2]);
    PsychPortAudio('Start', pahandle, 1, 0, waitForDeviceStart);
    PsychPortAudio('Stop', pahandle, 1, 1);

    fprintf('Cameras %d and %d acquisition STOP!\n', camA, camB);

    % Check the frame rate for each of the videos recorded
    checkSavedVideo(fileA, camA);
    checkSavedVideo(fileB, camB);
end

function applyManualFocus(src, camNum, manual_focus_cam1, manual_focus_cam2, manual_focus_cam3)
    try
        src.FocusMode = 'manual';
    catch ME
        warning('Could not set FocusMode for camera %d: %s', camNum, ME.message);
    end

    switch camNum
        case 1
            focusValue = manual_focus_cam1;
        case 2
            focusValue = manual_focus_cam2;
        case 3
            focusValue = manual_focus_cam3;
        otherwise
            error('Unknown camera number: %d', camNum);
    end

    try
        src.Focus = focusValue;
    catch ME
        warning('Could not set Focus for camera %d: %s', camNum, ME.message);
    end
end

function checkSavedVideo(filePath, camNum)
    if ~exist(filePath, 'file')
        warning('Video file was not created for camera %d: %s', camNum, filePath);
        return;
    end

    try
        v = VideoReader(filePath);

        nFrames = 0;
        while hasFrame(v)
            readFrame(v);
            nFrames = nFrames + 1;
        end

        fprintf('\nCamera %d\n', camNum);
        fprintf('File: %s\n', filePath);
        fprintf('Frames: %d\n', nFrames);
        fprintf('Video FPS: %.2f\n', v.FrameRate);
        fprintf('Duration: %.2f seconds\n', v.Duration);

    catch ME
        warning('Could not verify video for camera %d: %s', camNum, ME.message);
    end
end

function cleanupVideoObjects(vidA, vidB)
    try
        if isvalid(vidA)
            try
                stop(vidA);
            catch
            end
            try
                closepreview(vidA);
            catch
            end
            delete(vidA);
        end
    catch
    end

    try
        if isvalid(vidB)
            try
                stop(vidB);
            catch
            end
            try
                closepreview(vidB);
            catch
            end
            delete(vidB);
        end
    catch
    end
end