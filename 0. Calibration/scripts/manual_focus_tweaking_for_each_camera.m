% Here I am doing testing to see what is the best manual focus for each
% camera:

% IMPORTANT: before start, select video quality at 720p, 60 fps in Logitech app

clear;
clc;
imaqreset;

% -------- User settings --------
fmt = 'MJPG_1280x720';
camera_ids   = [1 2 3];
focus_values = [20 15 20];   % starting values for cam1, cam2, cam3

% -------- Camera info --------
infoCamera = imaqhwinfo('winvideo');
disp(infoCamera.DeviceInfo);

fprintf('\n========================================\n');
fprintf('LIVE MANUAL FOCUS TUNER\n');
fprintf('========================================\n');
fprintf('Controls during preview:\n');
fprintf('  u = +1 focus\n');
fprintf('  j = -1 focus\n');
fprintf('  i = +5 focus\n');
fprintf('  k = -5 focus\n');
fprintf('  s = set specific numeric value\n');
fprintf('  q = accept this camera and continue\n');
fprintf('  x = quit the whole script\n\n');

quit_all = false;

for kCam = 1:length(camera_ids)

    camID = camera_ids(kCam);
    currentFocus = focus_values(kCam);

    fprintf('\n==============================\n');
    fprintf('CAMERA %d\n', camID);
    fprintf('==============================\n');

    % Create camera object
    vid = videoinput('winvideo', camID, fmt);
    src = getselectedsource(vid);

    % Optional tag
    try
        src.Tag = 'focus adjustment preview';
    catch
    end

    % Print available focus-related info if available
    fprintf('Source object created for camera %d.\n', camID);

    try
        disp('Focus property info:');
        disp(propinfo(src, 'Focus'));
    catch
        disp('Could not read propinfo for Focus.');
    end

    % Set manual focus mode
    try
        src.FocusMode = 'manual';
        fprintf('Camera %d: FocusMode set to manual.\n', camID);
    catch ME
        warning('Camera %d: Could not set FocusMode to manual: %s', camID, ME.message);
    end

    % Set initial focus
    try
        src.Focus = currentFocus;
        currentFocus = src.Focus;
        fprintf('Camera %d: Initial Focus = %g\n', camID, currentFocus);
    catch ME
        warning('Camera %d: Could not set initial Focus: %s', camID, ME.message);
    end

    % Create preview figure
    hFig = figure( ...
        'Name', sprintf('Camera %d Preview', camID), ...
        'NumberTitle', 'off', ...
        'MenuBar', 'none', ...
        'ToolBar', 'none', ...
        'Color', 'k');

    % Preview image placeholder
    hImage = image(zeros(720,1280,3,'uint8'));
    axis image off;

    % Start preview
    preview(vid, hImage);

    done_this_camera = false;

    while ~done_this_camera

        % Update figure title with current focus
        if ishghandle(hFig)
            title(sprintf('Camera %d | Current Focus = %g', camID, currentFocus), ...
                'Color', 'w', 'FontSize', 14);
        end

        fprintf('\nCamera %d current focus = %g\n', camID, currentFocus);
        userKey = lower(strtrim(input('Command [u/j/i/k/s/q/x]: ', 's')));

        if isempty(userKey)
            continue;
        end

        switch userKey

            case 'u'
                newFocus = currentFocus + 1;
                [currentFocus] = setFocusSafely(src, camID, newFocus);

            case 'j'
                newFocus = currentFocus - 1;
                [currentFocus] = setFocusSafely(src, camID, newFocus);

            case 'i'
                newFocus = currentFocus + 5;
                [currentFocus] = setFocusSafely(src, camID, newFocus);

            case 'k'
                newFocus = currentFocus - 5;
                [currentFocus] = setFocusSafely(src, camID, newFocus);

            case 's'
                valStr = input(sprintf('Enter focus value for camera %d: ', camID), 's');
                newFocus = str2double(valStr);

                if isnan(newFocus)
                    fprintf('Invalid number.\n');
                else
                    [currentFocus] = setFocusSafely(src, camID, newFocus);
                end

            case 'q'
                fprintf('Camera %d accepted. Final focus = %g\n', camID, currentFocus);
                done_this_camera = true;

            case 'x'
                fprintf('Stopping script early.\n');
                done_this_camera = true;
                quit_all = true;

            otherwise
                fprintf('Unknown command.\n');
        end

        pause(0.15); % small pause so preview updates
    end

    % Save chosen value
    focus_values(kCam) = currentFocus;

    % Clean up this camera
    try
        closepreview(vid);
    catch
    end

    try
        stop(vid);
    catch
    end

    if ishghandle(hFig)
        close(hFig);
    end

    delete(vid);
    clear vid src hFig hImage

    if quit_all
        break;
    end
end

% -------- Final summary --------
fprintf('\n========================================\n');
fprintf('FINAL FOCUS VALUES\n');
fprintf('========================================\n');

for kCam = 1:length(camera_ids)
    fprintf('manual_focus_cam%d = %g;\n', camera_ids(kCam), focus_values(kCam));
end

fprintf('\nCopy these into your recording script.\n');


% ==========================================================
% Local helper function
% ==========================================================
function currentFocus = setFocusSafely(src, camID, newFocus)

    try
        src.Focus = newFocus;
        pause(0.05); % allow update
        currentFocus = src.Focus; % read back actual applied value
        fprintf('Camera %d: Focus updated to %g\n', camID, currentFocus);
    catch ME
        warning('Camera %d: Could not set Focus to %g: %s', camID, newFocus, ME.message);
        try
            currentFocus = src.Focus;
        catch
            currentFocus = newFocus;
        end
    end
end
