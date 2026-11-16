% AVI to MP4 converter

clc;
clear all;
close all;

% ============================================
% PASTE AVI FILE PATHS HERE
% ============================================

path1 = 'C:\Users\multisensorylab\Documents\EPs\Resampling_calibration_videos_for_Ivan\Version 8\1_Individual_calibration_videos\AVI\CT_1_dim_50\';
path2 = 'C:\Users\multisensorylab\Documents\EPs\Resampling_calibration_videos_for_Ivan\Version 8\1_Individual_calibration_videos\AVI\CT_4_dim_100\';
path3 = 'C:\Users\multisensorylab\Documents\EPs\Resampling_calibration_videos_for_Ivan\Version 8\2_Paired_calibration_videos\AVI\CT_1_dim_50\camera_1-camera_2\';
path4 = 'C:\Users\multisensorylab\Documents\EPs\Resampling_calibration_videos_for_Ivan\Version 8\2_Paired_calibration_videos\AVI\CT_1_dim_50\camera_2-camera_3\';
path5 = 'C:\Users\multisensorylab\Documents\EPs\Resampling_calibration_videos_for_Ivan\Version 8\2_Paired_calibration_videos\AVI\CT_1_dim_50\camera_3-camera_1\';
path6 = 'C:\Users\multisensorylab\Documents\EPs\Resampling_calibration_videos_for_Ivan\Version 8\2_Paired_calibration_videos\AVI\CT_4_dim_100\camera_1-camera_2\';
path7 = 'C:\Users\multisensorylab\Documents\EPs\Resampling_calibration_videos_for_Ivan\Version 8\2_Paired_calibration_videos\AVI\CT_4_dim_100\camera_2-camera_3\';
path8 = 'C:\Users\multisensorylab\Documents\EPs\Resampling_calibration_videos_for_Ivan\Version 8\2_Paired_calibration_videos\AVI\CT_4_dim_100\camera_3-camera_1\';
path9 = 'C:\Users\multisensorylab\Documents\EPs\Resampling_calibration_videos_for_Ivan\Version 8\3_Experimental_trial_videos\AVI\CT_1_dim_50\';
path10 = 'C:\Users\multisensorylab\Documents\EPs\Resampling_calibration_videos_for_Ivan\Version 8\3_Experimental_trial_videos\AVI\CT_4_dim_100\';

aviFiles = {

fullfile(path1, 'camera-1.AVI'),
fullfile(path1, 'camera-2.AVI'),
fullfile(path1, 'camera-3.AVI'),

fullfile(path2, 'camera-1.AVI'),
fullfile(path2, 'camera-2.AVI'),
fullfile(path2, 'camera-3.AVI'),

fullfile(path3, 'camera-1.AVI'),
fullfile(path3, 'camera-2.AVI'),

fullfile(path4, 'camera-2.AVI'),
fullfile(path4, 'camera-3.AVI'),

fullfile(path5, 'camera-3.AVI'),
fullfile(path5, 'camera-1.AVI'),

fullfile(path6, 'camera-1.AVI'),
fullfile(path6, 'camera-2.AVI'),

fullfile(path7, 'camera-2.AVI'),
fullfile(path7, 'camera-3.AVI'),

fullfile(path8, 'camera-3.AVI'),
fullfile(path8, 'camera-1.AVI'),

fullfile(path9, 'camera-1.AVI'),
fullfile(path9, 'camera-2.AVI'),
fullfile(path9, 'camera-3.AVI'),

fullfile(path10, 'camera-1.AVI'),
fullfile(path10, 'camera-2.AVI'),
fullfile(path10, 'camera-3.AVI')

};

fprintf('\n=====================================\n');
fprintf('AVI → MP4 (MATLAB MODE)\n');
fprintf('=====================================\n');

for i = 1:length(aviFiles)

    aviPath = aviFiles{i};

    if ~isfile(aviPath)
        warning('File not found: %s', aviPath);
        continue;
    end

    [folder, name, ~] = fileparts(aviPath);
    mp4Path = fullfile(folder, [name '.mp4']);

    fprintf('\nProcessing (%d/%d): %s\n', i, length(aviFiles), name);

    if isfile(mp4Path)
        fprintf('MP4 already exists → skipping\n');
        continue;
    end

    try
        v = VideoReader(aviPath);

        writer = VideoWriter(mp4Path, 'MPEG-4');
        writer.FrameRate = v.FrameRate;

        open(writer);

        frameCount = 0;

        while hasFrame(v)
            frame = readFrame(v);
            writeVideo(writer, frame);
            frameCount = frameCount + 1;
        end

        close(writer);

        fprintf('✓ Converted → %s\n', mp4Path);
        fprintf('Frames written: %d\n', frameCount);

    catch ME
        fprintf('✗ Failed on %s\n', aviPath);
        disp(ME.message);
    end

end

fprintf('\n=====================================\n');
fprintf('DONE\n');
fprintf('=====================================\n');