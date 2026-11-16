%% Draft 1 - Exploratory Procedures 3D Shape experiment (Tactable)
% Kate Nevin
% 06 May 2026
% updated 22 May 2026
% updated 25 Sep 2026 - updated new demographic questions to add

% Clear everything
clc
clear

imaqreset

%% Set paths

raw_data_dir = "D:\1_EP3Dageing\2. Raw Data and Videos";

%% ---- Camera variables to adjust ----

% The length of the video recorded
seconds_obj = 4;                   % Time object exploration
seconds_isi = 4;                   % Time ISI
seconds_video = 12;

% The manual focus value
manual_focus_cam1 = 0;
manual_focus_cam2 = 0;
manual_focus_cam3 = 0;

% Video file type
% MP4
video_file_type = 'MPEG-4';
video_extention_type = 'mp4';

% Light levels
CT = 1;
dim = 50;

%% ---- Set up the objects while the participant is reading consent form ----

disp("----------------------------------------");
disp("While the participant is reading the consent form, set the up the objects.");
disp("The objects that you will need for this experiment are the following:");
disp("1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35");
disp("-----------------------------------------");

disp("press the spacebar to continue")
pause;

% ---- Check that hand size has been recorded -----
disp("---------------------------------------");
disp("Have you traced the participant's right hand? If not, do so now");
disp("Press the spacebar to continue");
pause;

% ---- Check that grooved pegboard task and von frey filament task has been completed -----
disp("---------------------------------------");
disp("Have you completed the grooved pegboard and von frey filement tasks? If not, do so now");
disp("Press the spacebar to continue");
pause;

% ---- Start recording experiment time ----

% Record time that the experiment started here:
exp_start = datetime("now");

%% DEBUGGING OR MAIN?

% ---- Ask if it is a debugging session or main trial session ----

% Find out if debugging session
debugging_yn = "";

while true
    debugging_prompt = "---------- \nIs this a debugging session? [y/n]: ";
    debugging_yn = input(debugging_prompt, "s");

    if debugging_yn == "y" || debugging_yn == "n"
        break;
    else
        disp("Invalid input. Please enter y or n.");
    end
end

if debugging_yn == "y"
    num_practice = 0;
    num_trials = 2;
    participant_ID = "000000";
    shape_condition = "F";
    birth_date = "01/01/2000";
    birth_date_dt = datetime(birth_date, 'InputFormat', 'dd/MM/yyyy');
    age_condition = "younger";
    fprintf("Debugging session activated.\n The number of practice trials is %d and number of main trials is %d.\n", num_practice, num_trials);
elseif debugging_yn == "n"
    num_practice = 4;
    num_trials = 24;
    fprintf("Main experiment activated.\n The number of practice trials is %d and number of main trials is %d.\n", num_practice, num_trials);
end


%% ---- Collect demographics ----

% ---- Participant ID ----

% Get participant ID number:
if debugging_yn == "n"
    participant_ID = "";
    while true
        participant_ID_prompt = "-------------------- \nParticipant ID: ";
        participant_ID = strtrim(string(input(participant_ID_prompt, "s")));
    
        if strlength(participant_ID) == 6 && all(isstrprop(char(participant_ID), 'digit'))
            break;
        else
            disp("Invalid ID. Please enter exactly 6 digits.");
        end
    end
end

disp("The participant ID is " + participant_ID);

% ---- Shape Condition ----

if debugging_yn == "n"
    shape_condition = "";
    while true
        shape_condition_prompt = "---------- \nWhat is the experimental condition? [F/B] (must be in caps): ";
        shape_condition = input(shape_condition_prompt, "s");
    
        if shape_condition == "F" || shape_condition == "B"
            break;
        else
            disp("Invalid shape condition. Please enter F/B");
        end
    end
end

disp("The shape condition is " + shape_condition);

% --- Read in data and double check ----

% Read in appropriate data file based on shape condition
if shape_condition == "B"
    filename = "groupB.csv";
elseif shape_condition == "F"
    filename = "groupF.csv";
end
shape_file = readtable(filename);

% ---- Check --- 
% Check conditions if not debugging
if debugging_yn == "n"
    check_prompt = "---------------------------------- \nThe participant ID is " + participant_ID + ... 
        " and the shape condition is " + shape_condition + ... 
        ". \nIs this correct? y/n [y]: ";
    redo = input(check_prompt, "s");
end

% ---- DOB ----

if debugging_yn == "n"
    birth_date = "";
    while true
        birth_date_prompt = "---------- \nWhat is the participant's date of birth [dd/mm/yyyy]: ";
        birth_date = input(birth_date_prompt, "s");
    
        % Check format using regexp (2 digits / 2 digits / 4 digits)
        if ~isempty(regexp(birth_date, '^\d{2}/\d{2}/\d{4}$', 'once'))
            % Try to convert to a real date to catch invalid dates e.g. 31/02/2000
            try
                birth_date_dt = datetime(birth_date, 'InputFormat', 'dd/MM/yyyy');
                break;
            catch
                disp("Invalid date. Please check the day and month are correct.");
            end
        else
            disp("Invalid format. Please enter date as dd/mm/yyyy (e.g. 05/03/1990).");
        end
    end
end

% Calculate age in years with decimal for months
today = datetime("now");
age_years = years(today - birth_date_dt);

% Get whole years and remaining months
age_whole_years = floor(age_years);
remaining_months = floor(mod(age_years * 12, 12));
age_years_decimal = age_whole_years + (remaining_months / 12);

% Print
fprintf('Participant age: %d years and %d months (%.2f)\n', age_whole_years, remaining_months, age_years_decimal);

% ---- Age condition ----
if debugging_yn == "n"
    age_condition = "";
    while true
        age_condition_prompt = "---------- \nWhat condition does the participant belong to? [older/younger]: ";
        age_condition = string(input(age_condition_prompt, "s"));
    
        if age_condition == "older" || age_condition == "younger"
            break;
        else
            disp("Invalid input. Please enter older or younger.");
        end
    end
end

% ---- Sex at birth ----
if debugging_yn == "n"
    sex = "";
    while true
        sex_prompt = "------- \nWhat was your sex at birth? [male/female]: ";
        sex = lower(strtrim(string(input(sex_prompt, "s"))));

        if sex == "male" || sex == "female"
            break;
        else
            disp("Invalid input. Please enter male or female.");
        end
    end
else
    sex = "female"; % preset value for debugging
end

% ---- Education level ----
if debugging_yn == "n"
    education_level = "";
    while true
        education_prompt = "------- \nWhat is the highest level of education that you have completed? [none/primary/secondary/tertiary]: ";
        education_level = lower(strtrim(string(input(education_prompt, "s"))));

        if any(education_level == ["none", "primary", "secondary", "tertiary"])
            break;
        else
            disp("Invalid input. Please enter none, primary, secondary, or tertiary.");
        end
    end
else
    education_level = "tertiary"; % preset value for debugging
end

% ---- Hand / finger surgery ----
if debugging_yn == "n"
    hand_surgery_yn = "";
    while true
        hand_surgery_prompt = "------- \nHave you ever had surgery on your fingers or hands? [y/n]: ";
        hand_surgery_yn = lower(strtrim(string(input(hand_surgery_prompt, "s"))));

        if hand_surgery_yn == "y" || hand_surgery_yn == "n"
            break;
        else
            disp("Invalid input. Please enter y or n.");
        end
    end
else
    hand_surgery_yn = "y"; % preset value for debugging
end

% ---- How long ago was the surgery (years) ----
if hand_surgery_yn == "y"
    if debugging_yn == "n"
        while true
            surgery_years_prompt = "------- \nHow long ago was this surgery? [years, number]: ";
            hand_surgery_years_ago = str2double(input(surgery_years_prompt, "s"));

            if ~isnan(hand_surgery_years_ago) && hand_surgery_years_ago >= 0
                break;
            else
                disp("Invalid input. Please enter a number of years (e.g. 3 or 0.5).");
            end
        end
    else
        hand_surgery_years_ago = 3; % preset value for debugging
    end
else
    hand_surgery_years_ago = NaN; % not applicable
end

% ---- Occupational hand use (repetitive movements / power tools) ----
if debugging_yn == "n"
    occupation_hand_use_yn = "";
    while true
        occupation_hand_use_prompt = "------- \nDoes your previous or current occupation require you to use your hands by performing any repetitive movements or to use power tools? [y/n]: ";
        occupation_hand_use_yn = lower(strtrim(string(input(occupation_hand_use_prompt, "s"))));

        if occupation_hand_use_yn == "y" || occupation_hand_use_yn == "n"
            break;
        else
            disp("Invalid input. Please enter y or n.");
        end
    end
else
    occupation_hand_use_yn = "y"; % preset value for debugging
end

% ---- Occupational tasks (list) and hours per 8-hr workday for each task ----
if occupation_hand_use_yn == "y"

    % Task list
    if debugging_yn == "n"
        while true
            tasks_prompt = "------- \nWhat type of tasks do you do? (separate multiple tasks with commas): ";
            occupation_tasks = strtrim(string(input(tasks_prompt, "s")));

            if strlength(occupation_tasks) > 0
                break;
            else
                disp("Please enter at least one task.");
            end
        end
    else
        occupation_tasks = "typing, assembly line"; % preset value for debugging
    end

    task_list = strtrim(split(occupation_tasks, ","));
    task_list(task_list == "") = [];
    occupation_tasks = strjoin(task_list, ", "); % tidy formatting

    % Hours per task (asked in the same order as the task list)
    hours_list = strings(1, numel(task_list));

    for t = 1:numel(task_list)
        this_task = task_list(t);

        if debugging_yn == "n"
            while true
                hours_prompt = "------- \nHow many hours in a workday (8 hrs) would you typically perform " + ...
                    this_task + "? [0-8]: ";
                hours_input = str2double(input(hours_prompt, "s"));

                if ~isnan(hours_input) && hours_input >= 0 && hours_input <= 8
                    break;
                else
                    disp("Invalid input. Please enter a number of hours from 0 to 8.");
                end
            end
        else
            hours_input = 2 * t; % preset value for debugging
        end

        hours_list(t) = string(hours_input);
    end

    occupation_task_hours = strjoin(hours_list, ", ");

else
    occupation_tasks = "none";
    occupation_task_hours = "0";
end

% ---- Number of languages fluent in ----
if debugging_yn == "n"
    while true
        num_languages_prompt = "------- \nHow many languages are you fluent in? [number]: ";
        num_languages = str2double(input(num_languages_prompt, "s"));

        if ~isnan(num_languages) && num_languages == floor(num_languages) && num_languages >= 1
            break;
        else
            disp("Invalid input. Please enter a whole number (1 or more).");
        end
    end
else
    num_languages = 1; % preset value for debugging
end

% ---- List of languages fluent in ----
if debugging_yn == "n"
    while true
        languages_prompt = "------- \nList the languages that you are fluent in (separate with commas): ";
        languages_input = strtrim(string(input(languages_prompt, "s")));

        language_list = strtrim(split(languages_input, ","));
        language_list(language_list == "") = [];

        if isempty(language_list)
            disp("Please enter at least one language.");
        elseif numel(language_list) ~= num_languages
            fprintf("You said %d language(s) but listed %d. Please re-enter the list.\n", ...
                num_languages, numel(language_list));
        else
            break;
        end
    end
    languages_fluent = strjoin(language_list, ", ");
else
    languages_fluent = "English"; % preset value for debugging
end

% ---- Musical instrument background ----
if debugging_yn == "n"
    musician_yn = "";
    while true
        musician_yn_prompt = "------- \nDo you play a musical instrument? [y/n]: ";
        musician_yn = string(input(musician_yn_prompt, "s"));

        if musician_yn == "y" || musician_yn == "n"
            break;
        else
            disp("Invalid input. Please enter y or n.");
        end
    end
else
    musician_yn = "y"; % preset value for debugging
end

% ---- Which instrument(s) — open-ended ----
if debugging_yn == "n" && musician_yn == "y"
    instruments_played = "";
    while true
        instruments_played_prompt = "------- \nWhat instrument(s) do you play? (separate multiple with commas): ";
        instruments_played = strtrim(string(input(instruments_played_prompt, "s")));

        if strlength(instruments_played) > 0
            break;
        else
            disp("Please enter at least one instrument.");
        end
    end
elseif musician_yn == "y"
    instruments_played = "piano, guitar"; % preset value for debugging
else
    instruments_played = "none";
end

% ---- Years played per instrument (asked in same order as instruments_played) ----
if musician_yn == "y"
    instrument_list = strtrim(split(instruments_played, ","));
    instrument_list(instrument_list == "") = [];

    years_list = strings(1, numel(instrument_list));

    for i = 1:numel(instrument_list)
        this_instrument = instrument_list(i);

        if debugging_yn == "n"
            while true
                years_prompt = "------- \nHow many years have you played " + this_instrument + "? [number]: ";
                years_input = input(years_prompt);

                if isnumeric(years_input) && isscalar(years_input) && years_input >= 0
                    break;
                else
                    disp("Invalid input. Please enter a number.");
                end
            end
        else
            years_input = 5; % preset value for debugging
        end

        years_list(i) = string(years_input);
    end

    num_years_instrument = strjoin(years_list, ", ");
else
    num_years_instrument = "0";
end

%% ---- Read in practice file ----

% Read in practice csv sheet
practice_file = readtable("practice.csv");

%% ---- Shuffle the stimulus presentation order once for each participant ----

% ---- Practice trials ----

% Shuffle up the rows so that there is a random presentation for each
% participant
practice_file_rand = practice_file(randperm(height(practice_file)), :);

% ---- Main trials ----

% Shuffle up the rows so that there is a random presentation for each
% participant
shape_file_rand = shape_file(randperm(height(shape_file)), :);

%% ---- Set folder paths ----

behavioural_data_dir = fullfile(raw_data_dir, "1. Behavioural_Data");
if ~exist(behavioural_data_dir,'dir')
    mkdir(behavioural_data_dir);
    disp("Created behavioural data folder")
else
    disp("Behavioural data folder already exists!")
end

for k = 1:num_trials

    % Where the videos are stored
    video_data_dir = fullfile(raw_data_dir, "2. Raw_videos", sprintf("%s_trial_%02d", string(participant_ID), k));

    % Create video save folder only if it does NOT exist
    if ~exist(video_data_dir, 'dir')
        mkdir(video_data_dir);
        fprintf('Created directory: %s\n', video_data_dir);
    else
        fprintf('Directory already exists: %s\n', video_data_dir);
    end

end

%% ---- Setup and open arduino ----

a = arduino('COM4', 'Uno','Libraries','Servo');
s = servo(a,'D4');

%% ---- Camera setup ----

% Query all available windos video hardware and store device info
infoCamera = imaqhwinfo('winvideo');
% Display the supported video formats for the first detected device
infoCamera.DeviceInfo(1).SupportedFormats;

% Define the desired video formats for the first detected device
fmt = 'MJPG_1280x720';

% Create video objects for each camera using the windows video capture and
% specified format
vid1 = videoinput('winvideo', 1, fmt);
vid2 = videoinput('winvideo', 2, fmt);
vid3 = videoinput('winvideo', 3, fmt);

% Set cameras to manual trigger mode so acquisition only starts with an
% explicit trigger call
triggerconfig(vid1, 'manual');
triggerconfig(vid2, 'manual'); 
triggerconfig(vid3, 'manual');

% IMPORTANT: must be 0 so acquisition completes (no infinite repeats)
% Set cameras to fire its trigger exactly once, preventing infinite looping
vid1.TriggerRepeat = 0;
vid2.TriggerRepeat = 0;
vid3.TriggerRepeat = 0;

% Log to disk
% configure cameras to write frames directly to disk rather than holding
% them in memory
vid1.LoggingMode = 'disk';
vid2.LoggingMode = 'disk';
vid3.LoggingMode = 'disk';

% Source objects
% Retrieve the device-specific source object for each camera
vid1_src = getselectedsource(vid1);
vid2_src = getselectedsource(vid2);
vid3_src = getselectedsource(vid3);

% Attach a descriptive text tag to each camera's source object for
% identification purposes
vid1_src.Tag = 'motion detection setup';
vid2_src.Tag = 'motion detection setup';
vid3_src.Tag = 'motion detection setup';

% Print all hardware-level properties available for each camera
disp('vid1 source props:'); disp(get(vid1_src));
disp('vid2 source props:'); disp(get(vid2_src));
disp('vid3 source props:'); disp(get(vid3_src));

% Lock focus BEFORE preview/start
% Attempt to disable autofocus on each camera
try
    vid1_src.FocusMode = 'manual';
    vid2_src.FocusMode = 'manual';
    vid3_src.FocusMode = 'manual';
catch ME
    % Warn if the camera hardware does not support focusmode
    warning('Could not set FocusMode: %s', ME.message);
end

try
    % Set cameras focus to the pre-defined manual value for each camera
    vid1_src.Focus = manual_focus_cam1;
    vid2_src.Focus = manual_focus_cam2;
    vid3_src.Focus = manual_focus_cam3;
catch ME
    % Warn if this focus value cannot be applied
    warning('Could not set Focus: %s', ME.message);
end

try
    % Read back and print each camera's focus mode and value to confirm
    % settings
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

%% ---- Sound setup (Pyschtoolbox) ----

nrchannels = 2; % stereo
freq = 44100;
beepLengthSecs = .15;
waitForDeviceStart = 1;

myBeep  = MakeBeep(1000, beepLengthSecs, freq);
myBeep2 = MakeBeep(1000,  beepLengthSecs, freq);

InitializePsychSound(1);
pahandle = PsychPortAudio('Open', 5, 1, 0, freq, nrchannels);


%% Create empty dataframe to store data in

N = height(shape_file_rand);

% Create the empty variables where to store participant data
participant_col = strings(N, 1);
group_col = strings(N, 1);
age_group_col = strings(N, 1);
DOB_col = strings(N, 1);
age_yrs_col = zeros(N, 1);
age_yrs_dec_col = zeros(N, 1);
sex_col = strings(N, 1);
education_level_col = strings(N, 1);
hand_surgery_yn_col = strings(N, 1);
hand_surgery_years_ago_col = NaN(N, 1);
occupation_hand_use_yn_col = strings(N, 1);
occupation_tasks_col = strings(N, 1);
occupation_task_hours_col = strings(N, 1);
num_languages_col = zeros(N, 1);
languages_fluent_col = strings(N, 1);
musician_yn_col = strings(N, 1);
instruments_played_col = strings(N, 1);
num_years_instrument_col = strings(N, 1);
ref_stim_col = zeros(N, 1);
comp_stim_col = zeros(N, 1);
first_stim_col = zeros(N, 1);
second_stim_col = zeros(N, 1);
trial_num_col = zeros(N, 1);
step_size_col = zeros(N, 1);
trial_type_col = strings(N, 1);
key_resp_col = strings(N, 1);
corr_col = zeros(N, 1);
first_dur_col = zeros(N, 1);
second_dur_col = zeros(N, 1);
isi_dur_col = zeros(N, 1);
confidence_rating_col = zeros(N, 1);

% Create table with placeholder columns, explicit variable names so
% they don't collide with your demographic answer variables
data = table(participant_col, group_col, age_group_col, DOB_col, age_yrs_col, age_yrs_dec_col, ...
    sex_col, education_level_col, hand_surgery_yn_col, hand_surgery_years_ago_col, ...
    occupation_hand_use_yn_col, occupation_tasks_col, occupation_task_hours_col, ...
    num_languages_col, languages_fluent_col, ...
    musician_yn_col, instruments_played_col, num_years_instrument_col, ...
    ref_stim_col, comp_stim_col, first_stim_col, second_stim_col, trial_num_col, step_size_col, ...
    trial_type_col, key_resp_col, corr_col, first_dur_col, second_dur_col, isi_dur_col, confidence_rating_col, ...
    'VariableNames', {'participant','group','age_group','DOB','age_yrs','age_yrs_dec', ...
    'sex','education_level','hand_surgery_yn','hand_surgery_years_ago', ...
    'occupation_hand_use_yn','occupation_tasks','occupation_task_hours', ...
    'num_languages','languages_fluent', ...
    'musician_yn','instruments_played','num_years_instrument', ...
    'ref_stim','comp_stim','first_stim','second_stim','trial_num','step_size', ...
    'trial_type','key_resp','corr','first_dur','second_dur','isi_dur', 'confidence_rating'});

%% Practice trials

for i = 1:num_practice

    % ---- Load in the variables for this trial ----
    p_first_stim = practice_file_rand.first_stim(i);
    p_second_stim = practice_file_rand.second_stim(i);
    p_trial_type = string(practice_file_rand.trial_type{i});
    p_trial_num = string(i);

    % ---- Researcher setup ----

    % Tell the researcher which stimuli are to be used in this trial
    % (outputs to the command window)
    disp ("--------------- PRACTICE TRIAL " + i + "------------------")
    disp("The stimuli for this trial are " + p_first_stim + " and " + p_second_stim + ".");

    % ---- Wait for key press before starting trial ----
    disp("Press SPACEBAR to start trial");
    pause

    % ---- Start practice object 1 exploration ----

    disp('Practice object 1 exploration start')

    % Move servo motor back to start position
    writePosition(s, 0);

    % Start beep
    PsychPortAudio('FillBuffer', pahandle, [myBeep; myBeep]);
    PsychPortAudio('Start', pahandle);
    PsychPortAudio('Stop', pahandle, 1, 1);

    % Wait until just before the video ends
    pause(seconds_obj - 0.35);

    % Stop beep
    PsychPortAudio('FillBuffer', pahandle, [myBeep2; myBeep2]);
    PsychPortAudio('Start', pahandle);
    PsychPortAudio('Stop', pahandle, 1, 1);

    disp('Practice object 1 exploration complete');

    % Move the arm near the end of recording
    writePosition(s, 1);

    % ---- 4 second ISI ----

    % ISI
    pause(3.5);

    % ---- Start object 2 exploration -----

    % Move servo motor back to start position
    writePosition(s, 0);

    disp('Practice object 2 exploration start')

    % Start beep
    PsychPortAudio('FillBuffer', pahandle, [myBeep; myBeep]);
    PsychPortAudio('Start', pahandle);
    PsychPortAudio('Stop', pahandle, 1, 1);

    % Wait until just before the video ends
    pause(seconds_obj - 0.35);

    % Stop beep
    PsychPortAudio('FillBuffer', pahandle, [myBeep2; myBeep2]);
    PsychPortAudio('Start', pahandle);
    PsychPortAudio('Stop', pahandle, 1, 1);

    disp('Practice object 2 exploration complete')

    % Move the arm near the end of recording
    writePosition(s, 1);

    % ---- Log participant response ----

    % Press the 's' key if participant says they feel the same
    % Press the 'd' key if participant says they feel different

    % Only accept 's' or 'd' as valid responses
    p_valid_response = false;
    while ~p_valid_response
        p_key.resp = string(input("Are these stimuli the SAME or DIFFERENT? s/d ", "s"));
        if p_key.resp == "s" || p_key.resp == "d"
            p_valid_response = true;
        else
            disp("Invalid input. Please press 's' for same or 'd' for different.");
        end
    end

    % Compute whether the participant was correct or incorrect
    if p_trial_type == "same" && p_key.resp == "s"
        disp("Correct!")
        corr = 1;
    elseif p_trial_type == "diff" && p_key.resp == "d"
        disp("Correct!")
        corr = 1;
    elseif p_trial_type == "same" && p_key.resp == "d"
        disp("Incorrect!")
        corr = 0;
    elseif p_trial_type == "diff" && p_key.resp == "s"
        disp("Incorrect!")
        corr = 0;
    else
        disp("Something went wrong")
    end

end

disp("------------------------------------------");
disp("Practice trials are now complete!");
disp("Press SPACEBAR to continue to main trials");
pause;


%% Main trials

disp("--------------------------------------------------");
disp("Let the participant know that some of the shapes are spiky. Press SPACEBAR to continue.")
pause

for i = 1:num_trials
% for i = 1:height(shape_file_rand)

    % ---- Load in the variables for this trial ----
    group = string(shape_file_rand.group{i});
    ref_stim = shape_file_rand.ref_stim(i);
    comp_stim = shape_file_rand.comp_stim(i);
    first_stim = shape_file_rand.first_stim(i);
    second_stim = shape_file_rand.second_stim(i);
    step_size = shape_file_rand.step_size(i);
    trial_type = string(shape_file_rand.trial_type{i});
    trial_num = string(i);

    disp("--------------- TRIAL " + i + "------------------")
    disp("The stimuli for this trial are " + first_stim + " and " + second_stim + ".");

    % ---- Set up cameras for this trial ----
    file1 = fullfile(raw_data_dir, "2. Raw_videos", sprintf("%s_trial_%02d", string(participant_ID), i), sprintf('cam0.%s', video_extention_type));
    file2 = fullfile(raw_data_dir, "2. Raw_videos", sprintf("%s_trial_%02d", string(participant_ID), i), sprintf('cam1.%s', video_extention_type));
    file3 = fullfile(raw_data_dir, "2. Raw_videos", sprintf("%s_trial_%02d", string(participant_ID), i), sprintf('cam2.%s', video_extention_type));

    writer1 = VideoWriter(file1, video_file_type); writer1.FrameRate = 60;
    writer2 = VideoWriter(file2, video_file_type); writer2.FrameRate = 60;
    writer3 = VideoWriter(file3, video_file_type); writer3.FrameRate = 60;

    vid1.DiskLogger = writer1;
    vid2.DiskLogger = writer2;
    vid3.DiskLogger = writer3;

    % Reset FramesPerTrigger each trial (good practice)
    vid1.FramesPerTrigger = Nframes;
    vid2.FramesPerTrigger = Nframes;
    vid3.FramesPerTrigger = Nframes;

    start(vid1); start(vid2); start(vid3);

    disp("Press SPACEBAR to start trial");
    pause

    % ---- Object 1 exploration ----
    trigger([vid1 vid2 vid3]);
    disp('Object 1 exploration start')

    writePosition(s, 0);

    PsychPortAudio('FillBuffer', pahandle, [myBeep; myBeep]);
    PsychPortAudio('Start', pahandle);
    PsychPortAudio('Stop', pahandle, 1, 1);

    t_first_start = datetime("now");
    pause(seconds_obj - 0.35);

    PsychPortAudio('FillBuffer', pahandle, [myBeep2; myBeep2]);
    PsychPortAudio('Start', pahandle);
    PsychPortAudio('Stop', pahandle, 1, 1);

    t_first_end = datetime("now");
    disp('Object 1 exploration complete');
    writePosition(s, 1);

    % ---- ISI ----
    pause(3);

    % ---- Object 2 exploration ----
    writePosition(s, 0);
    disp('Object 2 exploration start')

    PsychPortAudio('FillBuffer', pahandle, [myBeep; myBeep]);
    PsychPortAudio('Start', pahandle);
    PsychPortAudio('Stop', pahandle, 1, 1);

    t_second_start = datetime("now");
    pause(seconds_obj - 0.32);

    PsychPortAudio('FillBuffer', pahandle, [myBeep2; myBeep2]);
    PsychPortAudio('Start', pahandle);
    PsychPortAudio('Stop', pahandle, 1, 1);

    t_second_end = datetime("now");
    disp('Object 2 exploration complete')
    writePosition(s, 1);

    % ---- Wait for acquisition to finish, then clean up ----
    % FIX 1: timeout covers full video duration
    wait(vid1, seconds_video + 15);
    wait(vid2, seconds_video + 15);
    wait(vid3, seconds_video + 15);

    % FIX 2: stop AFTER wait completes
    stop(vid1); stop(vid2); stop(vid3);

    % FIX 3: flush any residual frames from memory
    flushdata(vid1); flushdata(vid2); flushdata(vid3);

    % FIX 4: close VideoWriter objects to release file handles and buffers
    close(writer1); close(writer2); close(writer3);

    % FIX 5: explicitly clear writer objects each trial
    clear writer1 writer2 writer3

    % ---- Log participant response ----
    valid_response = false;
    while ~valid_response
        key.resp = string(input("Are these stimuli the SAME or DIFFERENT? s/d ", "s"));
        if key.resp == "s" || key.resp == "d"
            valid_response = true;
        else
            disp("Invalid input. Please press 's' for same or 'd' for different.");
        end
    end

    if trial_type == "same" && key.resp == "s"
        disp("Correct!"); corr = 1;
    elseif trial_type == "diff" && key.resp == "d"
        disp("Correct!"); corr = 1;
    elseif trial_type == "same" && key.resp == "d"
        disp("Incorrect!"); corr = 0;
    elseif trial_type == "diff" && key.resp == "s"
        disp("Incorrect!"); corr = 0;
    else
        disp("Something went wrong")
    end

    first_duration  = seconds(t_first_end   - t_first_start);
    second_duration = seconds(t_second_end  - t_second_start);
    isi_duration    = seconds(t_second_start - t_first_end);
    fprintf('ISI duration for trial %d: %.3f seconds\n', i, isi_duration);

  % ---- Log data ----
    data{i, "participant"}  = participant_ID;
    data{i, "group"}        = group;
    data{i, "age_group"}    = age_condition;
    data{i, "DOB"}          = string(birth_date);
    data{i, "age_yrs"}      = age_whole_years;
    data{i, "age_yrs_dec"}  = age_years_decimal;
    data{i, "sex"}          = sex;
    data{i, "education_level"}        = education_level;
    data{i, "hand_surgery_yn"}        = hand_surgery_yn;
    data{i, "hand_surgery_years_ago"} = hand_surgery_years_ago;
    data{i, "occupation_hand_use_yn"} = occupation_hand_use_yn;
    data{i, "occupation_tasks"}       = occupation_tasks;
    data{i, "occupation_task_hours"}  = occupation_task_hours;
    data{i, "num_languages"}          = num_languages;
    data{i, "languages_fluent"}       = languages_fluent;
    data{i, "musician_yn"}            = musician_yn;
    data{i, "instruments_played"}     = instruments_played;
    data{i, "num_years_instrument"}   = num_years_instrument;
    data{i, "ref_stim"}     = ref_stim;
    data{i, "comp_stim"}    = comp_stim;
    data{i, "first_stim"}   = first_stim;
    data{i, "second_stim"}  = second_stim;
    data{i, "step_size"}    = step_size;
    data{i, "trial_type"}   = trial_type;
    data{i, "trial_num"}    = i;
    data{i, "key_resp"}     = key.resp;
    data{i, "corr"}         = corr;
    data{i, "first_dur"}    = first_duration;
    data{i, "second_dur"}   = second_duration;
    data{i, "isi_dur"}      = isi_duration;

    % FIX 6: save data after every trial so a crash doesn't lose everything
    timestamp_trial = string(datetime("now","Format","yyyy-MM-dd_HH-mm-ss"));
    writetable(data, behavioural_data_dir + "/" + string(participant_ID) + "_EPs_Exp_AUTOSAVE.csv");

    pause(1);

end

% ---- Confidence rating ----
while true
    confidence_prompt = "------- \nOverall, how confident were you in your answers? " + ...
        "\n[1 = Very not confident, 2 = Not confident, 3 = Somewhat not confident, 4 = Neutral, 5 = Somewhat confidenct, 6 = Confident, 7 = Very confident]: ";
    confidence_input = str2double(input(confidence_prompt, "s"));

    if ~isnan(confidence_input) && confidence_input == floor(confidence_input) ...
            && confidence_input >= 1 && confidence_input <= 7
        confidence_rating = confidence_input;
        break;
    else
        disp("Invalid input. Please enter a whole number from 1 to 7.");
    end
end

fprintf("Confidence rating recorded: %d\n", confidence_rating);

% Add the rating to every completed trial row
data.confidence_rating(1:num_trials) = confidence_rating;

% Record time that the experiment started here:
exp_end = datetime("now");

% Calculate how long the experiment took:
exp_dur = minutes(exp_end -  exp_start);

% State how long the experiment took from start to finish
disp('The experiment duration was ' + string(exp_dur) + 'mins.');


%% Write the csv file
timestamp = string(datetime("now","Format","yyyy-MM-dd_HH-mm-ss"));

writetable(data, behavioural_data_dir + "/" + string(participant_ID) + "_EPs_Exp_" + timestamp + ".csv");

%% ---- Clean up ----

delete(vid1); delete(vid2); delete(vid3);

clear vid1 vid2 vid3

PsychPortAudio('Close');

%% ---- Goodbye message ----

% End experiment message
disp(" ---------------------------------- ");
disp("The experiment is now finished!")
disp("Press SPACEBAR to exit the experiment.");
pause;

%% If you accidentally stop the experiment halfway through, you can release the cameras by running the following line of code:
% imaqreset