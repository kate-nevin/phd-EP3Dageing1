% IMPORTANT: before start, select the video quality at 720p, 60 fps in Logitech app

% In this script, the cameras are at 60 cm height
% The length of the videos is set to 20 s
% The manual focus for each camera is set to 0

clear all;
imaqreset;

% --- Variables to adjust ---

% The length of the video recorded
seconds_video = 4;

% The manual focus value
manual_focus_cam1 = 0;
manual_focus_cam2 = 0;
manual_focus_cam3 = 0;

% Light levels
CT = 4;
dim = 100;

% --- Set paths ---

% Folder name
save_folder_name = 'CT_' + string(CT) + '_dim_' + string(dim) + '\';

% Path where to save individual videos
outDir = 'C:\Users\multisensorylab\Documents\EPs\Resampling_calibration_videos_for_Ivan\Version 8\3_Experimental_trial_videos\AVI';

SaveDir = fullfile(outDir, save_folder_name);

% Create save folder only if it does NOT exist
if ~exist(SaveDir, 'dir')
    mkdir(SaveDir);
    fprintf('Created directory: %s\n', SaveDir);
else
    fprintf('Directory already exists: %s\n', SaveDir);
end

% --- Setup and open arduino ---
a = arduino('COM4', 'Uno','Libraries','Servo');
s = servo(a,'D4');

% --- Camera setup ---
infoCamera = imaqhwinfo('winvideo');
infoCamera.DeviceInfo(1).SupportedFormats;

fmt = 'MJPG_1280x720';

vid1 = videoinput('winvideo', 1, fmt);
vid2 = videoinput('winvideo', 2, fmt);
vid3 = videoinput('winvideo', 3, fmt);

% Manual trigger (we will trigger together)
triggerconfig(vid1, 'manual');
triggerconfig(vid2, 'manual'); 
triggerconfig(vid3, 'manual');

% IMPORTANT: must be 0 so acquisition completes (no infinite repeats)
vid1.TriggerRepeat = 0;
vid2.TriggerRepeat = 0;
vid3.TriggerRepeat = 0;

% Log to disk
vid1.LoggingMode = 'disk';
vid2.LoggingMode = 'disk';
vid3.LoggingMode = 'disk';

% --- Output paths (EDIT IF NEEDED) ---
file1 = fullfile(SaveDir, 'camera-1.AVI');
file2 = fullfile(SaveDir, 'camera-2.AVI');
file3 = fullfile(SaveDir, 'camera-3.AVI');

% Create writers first, set FPS, then attach
writer1 = VideoWriter(file1, 'Uncompressed AVI');
writer2 = VideoWriter(file2, 'Uncompressed AVI');
writer3 = VideoWriter(file3, 'Uncompressed AVI');

% Use 60 fps to match your intended acquisition/playback
writer1.FrameRate = 60;
writer2.FrameRate = 60;
writer3.FrameRate = 60;

vid1.DiskLogger = writer1;
vid2.DiskLogger = writer2;
vid3.DiskLogger = writer3;

% Source objects
vid1_src = getselectedsource(vid1);
vid2_src = getselectedsource(vid2);
vid3_src = getselectedsource(vid3);

% Optional tag
vid1_src.Tag = 'motion detection setup';
vid2_src.Tag = 'motion detection setup';
vid3_src.Tag = 'motion detection setup';

% See what properties are actually available on your system
disp('vid1 source props:'); disp(get(vid1_src));
disp('vid2 source props:'); disp(get(vid2_src));
disp('vid3 source props:'); disp(get(vid3_src));

% Lock focus BEFORE preview/start
try
    vid1_src.FocusMode = 'manual';
    vid2_src.FocusMode = 'manual';
    vid3_src.FocusMode = 'manual';
catch ME
    warning('Could not set FocusMode: %s', ME.message);
end

try
    vid1_src.Focus = manual_focus_cam1;
    vid2_src.Focus = manual_focus_cam2;
    vid3_src.Focus = manual_focus_cam3;
catch ME
    warning('Could not set Focus: %s', ME.message);
end

try
    fprintf('Cam1 FocusMode = %s, Focus = %g\n', vid1_src.FocusMode, vid1_src.Focus);
catch
    disp('Could not read back Cam1 focus settings');
end

try
    fprintf('Cam2 FocusMode = %s, Focus = %g\n', vid2_src.FocusMode, vid2_src.Focus);
catch
    disp('Could not read back Cam2 focus settings');
end

try
    fprintf('Cam3 FocusMode = %s, Focus = %g\n', vid3_src.FocusMode, vid3_src.Focus);
catch
    disp('Could not read back Cam3 focus settings');
end

% --- Frames to capture (exactly seconds_video * 60) ---
Nframes = seconds_video * 60;

vid1.FramesPerTrigger = Nframes;
vid2.FramesPerTrigger = Nframes;
vid3.FramesPerTrigger = Nframes;

% --- Sound setup (PsychToolbox) ---
nrchannels = 2; % stereo
freq = 44100;
beepLengthSecs = .1;
waitForDeviceStart = 1;

myBeep  = MakeBeep(1000, beepLengthSecs, freq);
myBeep2 = MakeBeep(500,  beepLengthSecs, freq);

InitializePsychSound(1);
pahandle = PsychPortAudio('Open', 5, 1, 0, freq, nrchannels);

% --- Start acquisition objects (they won't record until trigger) ---
start(vid1);
start(vid2);
start(vid3);

% preview(vid1);
% preview(vid2);
% preview(vid3);

% Countdown
writePosition(s, 0);
secPause = 10;
disp('press spacebar to start')
pause
for i = 1:secPause
    pause(1);
    disp(i);
end

% Start beep
disp('Acquisition started!')
PsychPortAudio('FillBuffer', pahandle, [myBeep; myBeep]);
PsychPortAudio('Start', pahandle);
PsychPortAudio('Stop', pahandle, 1, 1);

% Trigger all cameras together
trigger([vid1 vid2 vid3]);

% Wait until just before the video ends
pause(seconds_video - 0.5);

% Move the arm near the end of recording
writePosition(s, 1);

% Wait for acquisition to complete (safety timeout)
wait(vid1, seconds_video + 10);
wait(vid2, seconds_video + 10);
wait(vid3, seconds_video + 10);

% Stop everything
stop(vid1); stop(vid2); stop(vid3);
closepreview(vid1); closepreview(vid2); closepreview(vid3);

disp('Acquisition STOP!')

% Stop beep
PsychPortAudio('FillBuffer', pahandle, [myBeep2; myBeep2]);
PsychPortAudio('Start', pahandle, 1, 0, waitForDeviceStart);
PsychPortAudio('Stop', pahandle, 1, 1);

% Check the frame rate for each of the videos recorded:
paths = {file1, file2, file3};

for i = 1:length(paths)

    v = VideoReader(paths{i});
    
    % count frames
    nFrames = 0;
    while hasFrame(v)
        readFrame(v);
        nFrames = nFrames + 1;
    end
    
    fprintf('\nCamera %d\n', i);
    fprintf('Frames: %d\n', nFrames);
    fprintf('Video FPS: %.2f\n', v.FrameRate);
    fprintf('Duration: %.2f seconds\n', v.Duration);
    
end

% Cleanup (important)
delete(v); delete(vid1); delete(vid2); delete(vid3);
clear vid1 vid2 vid3

PsychPortAudio('Close');