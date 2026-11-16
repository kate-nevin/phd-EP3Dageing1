% IMPORTANT: before start, select the video quality at 720p, 60 fps in Logitech app

% In this version, videos are automatically stored as .SMP4 files and not
% .AVI files.

clear all;
imaqreset;

% --- Variables to adjust ---

% The length of the video recorded
seconds_video = 20;

% The manual focus value
manual_focus_cam1 = 0;
manual_focus_cam2 = 0;
manual_focus_cam3 = 0;

% --- Set paths ---

% Folder name
% save_folder_name = 'CT_' + string(CT) + '_dim_' + string(dim) + '\';

% Path where to save individual videos
outDir = 'C:\Users\multisensorylab\Documents\Kate\5. Pilot Experiments - Behavioural\Draft 3 - Final\calibration_videos_and_scripts\Intrinsic\';

% SaveDir = fullfile(outDir, save_folder_name);
SaveDir = outDir;

% Create save folder only if it does NOT exist
if ~exist(SaveDir, 'dir')
    mkdir(SaveDir);
    fprintf('Created directory: %s\n', SaveDir);
else
    fprintf('Directory already exists: %s\n', SaveDir);
end

% --- Setup and open arduino ---
a = arduino('COM4', 'Uno', 'Libraries', 'Servo');
s = servo(a, 'D4');

% --- Camera setup ---
infoCamera = imaqhwinfo('winvideo');
disp(infoCamera.DeviceInfo(1).SupportedFormats);

fmt = 'MJPG_1280x720';

vid1 = videoinput('winvideo', 1, fmt);
vid2 = videoinput('winvideo', 2, fmt);
vid3 = videoinput('winvideo', 3, fmt);

% Manual trigger
triggerconfig(vid1, 'manual');
triggerconfig(vid2, 'manual');
triggerconfig(vid3, 'manual');

% IMPORTANT: must be 0 so acquisition completes
vid1.TriggerRepeat = 0;
vid2.TriggerRepeat = 0;
vid3.TriggerRepeat = 0;

% Log to disk
vid1.LoggingMode = 'disk';
vid2.LoggingMode = 'disk';
vid3.LoggingMode = 'disk';

% --- Output paths ---
file1 = fullfile(SaveDir, 'camera_1.mp4');
file2 = fullfile(SaveDir, 'camera_2.mp4');
file3 = fullfile(SaveDir, 'camera_3.mp4');

% Store cameras/files in arrays for easier indexing
vids = {vid1, vid2, vid3};
files = {file1, file2, file3};
manual_focus = [manual_focus_cam1, manual_focus_cam2, manual_focus_cam3];

% --- Source objects ---
vid1_src = getselectedsource(vid1);
vid2_src = getselectedsource(vid2);
vid3_src = getselectedsource(vid3);
srcs = {vid1_src, vid2_src, vid3_src};

% Optional tag
for k = 1:3
    srcs{k}.Tag = 'motion detection setup';
end

% See what properties are actually available on your system
disp('vid1 source props:'); disp(get(vid1_src));
disp('vid2 source props:'); disp(get(vid2_src));
disp('vid3 source props:'); disp(get(vid3_src));

% Lock focus BEFORE preview/start
for k = 1:3
    try
        srcs{k}.FocusMode = 'manual';
    catch ME
        warning('Could not set FocusMode for camera %d: %s', k, ME.message);
    end
end

for k = 1:3
    try
        srcs{k}.Focus = manual_focus(k);
    catch ME
        warning('Could not set Focus for camera %d: %s', k, ME.message);
    end
end

for k = 1:3
    try
        fprintf('Cam%d FocusMode = %s, Focus = %g\n', ...
            k, srcs{k}.FocusMode, srcs{k}.Focus);
    catch
        fprintf('Could not read back Cam%d focus settings\n', k);
    end
end

% --- Frames to capture ---
Nframes = seconds_video * 60;
for k = 1:3
    vids{k}.FramesPerTrigger = Nframes;
end

% --- Sound setup (PsychToolbox) ---
nrchannels = 2; % stereo
freq = 44100;
beepLengthSecs = .1;
waitForDeviceStart = 1;

myBeep  = MakeBeep(1000, beepLengthSecs, freq);
myBeep2 = MakeBeep(1000,  beepLengthSecs, freq);

InitializePsychSound(1);
pahandle = PsychPortAudio('Open', 5, 1, 0, freq, nrchannels);

% --- MAIN LOOP ---
disp(' ');
disp('Type camera number to record: 1, 2, or 3');
disp('Type q to stop');
disp('You can re-record any camera and it will overwrite the old AVI.');
disp(' ');

done = false;

while ~done

    userChoice = input('Enter camera number (1/2/3) or q to quit: ', 's');
    userChoice = strtrim(lower(userChoice));

    if strcmp(userChoice, 'q')
        done = true;
        break;
    end

    camNum = str2double(userChoice);

    if ~ismember(camNum, [1 2 3])
        fprintf('Invalid input: %s\n', userChoice);
        fprintf('Please enter 1, 2, 3, or q.\n\n');
        continue;
    end

    vid = vids{camNum};
    file = files{camNum};

    fprintf('\n--- Preparing camera %d ---\n', camNum);

    % Make sure camera is not already running
    try
        stop(vid);
    catch
    end

    % Close any previous preview for this camera
    try
        closepreview(vid);
    catch
    end

    % Overwrite old video if it exists
    if exist(file, 'file')
        delete(file);
        fprintf('Old file deleted and will be overwritten: %s\n', file);
    end

    % Create a fresh writer each time
    writer = VideoWriter(file, 'MPEG-4'); %'Uncompressed AVI' if want .AVI file
    writer.FrameRate = 60;
    vid.DiskLogger = writer;

    % Reset servo position before recording
    writePosition(s, 0);

    % Start and preview selected camera
    start(vid);
    preview(vid);

    fprintf('Press any key in MATLAB command window to start recording for camera %d...\n', camNum);
    pause

    % Display that recording has started
    fprintf('Camera %d recording started!\n', camNum);

    % Start beep
    PsychPortAudio('FillBuffer', pahandle, [myBeep; myBeep]);
    PsychPortAudio('Start', pahandle);
    PsychPortAudio('Stop', pahandle, 1, 1);

    % Trigger video acquisition
    trigger(vid);

    % Wait until just before the video ends
    pause(seconds_video - 0.5);

    % Move the arm near the end of recording
    writePosition(s, 1);

    % Wait until recording finishes
    wait(vid, seconds_video + 20);
    stop(vid);
    closepreview(vid);

    % Stop beep
    PsychPortAudio('FillBuffer', pahandle, [myBeep2; myBeep2]);
    PsychPortAudio('Start', pahandle, 1, 0, waitForDeviceStart);
    PsychPortAudio('Stop', pahandle, 1, 1);

    fprintf('Camera %d acquisition STOP!\n', camNum);

    % Quick check of saved video
    try
        vcheck = VideoReader(file);
        nFrames = 0;
        while hasFrame(vcheck)
            readFrame(vcheck);
            nFrames = nFrames + 1;
        end

        fprintf('Saved file check for camera %d:\n', camNum);
        fprintf('Frames: %d\n', nFrames);
        fprintf('Video FPS: %.2f\n', vcheck.FrameRate);
        fprintf('Duration: %.2f seconds\n\n', vcheck.Duration);
        clear vcheck
    catch ME
        warning('Could not read saved video for camera %d: %s', camNum, ME.message);
    end
end

% --- Final check for all videos that exist ---
disp(' ');
disp('--- Final summary of saved videos ---');

for i = 1:length(files)
    if exist(files{i}, 'file')
        try
            v = VideoReader(files{i});

            nFrames = 0;
            while hasFrame(v)
                readFrame(v);
                nFrames = nFrames + 1;
            end

            fprintf('\nCamera %d\n', i);
            fprintf('Frames: %d\n', nFrames);
            fprintf('Video FPS: %.2f\n', v.FrameRate);
            fprintf('Duration: %.2f seconds\n', v.Duration);

            clear v
        catch ME
            warning('Could not read file for camera %d: %s', i, ME.message);
        end
    else
        fprintf('\nCamera %d\n', i);
        fprintf('No saved video found.\n');
    end
end

% --- Cleanup ---
writePosition(s, 0);

delete(vid1); delete(vid2); delete(vid3);
clear vid1 vid2 vid3

PsychPortAudio('Close');