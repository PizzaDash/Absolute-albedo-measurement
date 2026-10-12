function data = preprocess_raw_captures(folder)
%PREPROCESS_RAW_CAPTURES  Average and dark-correct the raw captures of an image set.
%   data = PREPROCESS_RAW_CAPTURES(folder) builds the observed image
%   I_i^obs of every light source from its N raw frames, following the
%   acquisition model of Sec. 4.2:
%
%       I_i^obs = mean_k(I_i^k) / t_i  -  mean_k(I_dark^k) / t_dark
%
%   which is the paper's (1 / (N t_i)) * sum_k (I_i^k - I_dark^k) when the
%   dark frames are acquired with the same integration time as the lit
%   frames. Dividing by the integration time expresses every image in gray
%   levels per second. Negative values, which can only come from noise,
%   are set to zero.
%
%   Expected content of folder:
%     - one subfolder per light source, whose name contains "p" and ends
%       with the integration time in ms, holding the N frames as .tif files
%       (e.g. p1_im_ti_100/, p2_im_ti_100/, ...);
%     - one subfolder whose name contains "bg" and ends with the integration
%       time in ms, holding the dark frames acquired with every light source
%       off (e.g. bg_ti_100/). It is shared by all light sources.
%   The light-source subfolders are processed in alphabetical order, which
%   must be the order of the light directions.
%
%   Output: struct with the fields
%     I   m x H x W grayscale images, in gray levels per second
%     ti  m x 1 integration times, in seconds

format   = 'tif';
ms_to_s  = 1e-3;   % integration times are written in ms in the folder names

entries = dir(folder);
entries = entries([entries.isdir] & ~startsWith({entries.name}, '.'));
names   = {entries.name};
is_dark = contains(names, 'bg');
light_folders = names(contains(names, 'p') & ~is_dark);
dark_folders  = names(is_dark);

if isempty(light_folders) || isempty(dark_folders)
    error('preprocess_raw_captures:layout', ...
          ['%s contains neither data.mat nor raw captures (one subfolder per ' ...
           'light source and one "bg" subfolder). See data/README.md.'], folder);
end

% Dark signal, averaged over its frames
dark_name = dark_folders{1};
dark_mean = average_frames(fullfile(folder, dark_name), format);
t_dark    = ms_to_s * integration_time_from_name(dark_name);

m = numel(light_folders);
for i = 1:m
    fprintf('  averaging %s (%d/%d)\n', light_folders{i}, i, m);
    t_i = ms_to_s * integration_time_from_name(light_folders{i});
    lit_mean = average_frames(fullfile(folder, light_folders{i}), format);

    if i == 1
        data.I  = zeros(m, size(lit_mean, 1), size(lit_mean, 2));
        data.ti = zeros(m, 1);
    end
    data.I(i, :, :) = max(lit_mean / t_i - dark_mean / t_dark, 0);
    data.ti(i)      = t_i;
end
end

function t = integration_time_from_name(name)
% The integration time (in ms) is the last "_"-separated token of the name.
parts = split(name, '_');
t = str2double(parts{end});
if isnan(t)
    error('preprocess_raw_captures:name', ...
          'Cannot read the integration time at the end of the folder name "%s".', name);
end
end

function mean_img = average_frames(frame_folder, format)
% Average of all the frames of a folder, as a grayscale image in [0, 1].
files = dir(fullfile(frame_folder, ['*.' format]));
if isempty(files)
    error('preprocess_raw_captures:empty', 'No .%s frame in %s.', format, frame_folder);
end
mean_img = 0;
for k = 1:numel(files)
    frame = im2double(imread(fullfile(frame_folder, files(k).name)));
    mean_img = mean_img + mean(frame, 3);   % average of the color channels, if any
end
mean_img = mean_img / numel(files);
end
