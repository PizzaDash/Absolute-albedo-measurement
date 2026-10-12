function [I, ti] = load_image_set(folder)
%LOAD_IMAGE_SET  Load the preprocessed images of one image set.
%   [I, ti] = LOAD_IMAGE_SET(folder) returns the image stack I, of size
%   m x H x W (one image per light source), and the integration times ti
%   (m x 1, in seconds) of the image set stored in folder.
%
%   Two layouts are accepted:
%     1. folder/data.mat, holding a struct "data" with the fields data.I
%        (m x H x W) and data.ti (m x 1), as written by
%        PREPROCESS_RAW_CAPTURES. These images are already averaged,
%        corrected for the dark signal and divided by their integration
%        time.
%     2. The raw captures (one subfolder per light source and one dark
%        subfolder, see PREPROCESS_RAW_CAPTURES). They are preprocessed
%        here and the result is cached in folder/data.mat, so this is done
%        only once.

data_file = fullfile(folder, 'data.mat');
if isfile(data_file)
    loaded = load(data_file, 'data');
    data = loaded.data;
else
    fprintf('No data.mat in %s: preprocessing the raw captures...\n', folder);
    data = preprocess_raw_captures(folder);
    save(data_file, 'data');
end

I  = data.I;
ti = data.ti(:);
end
