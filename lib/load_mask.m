function mask = load_mask(file)
%LOAD_MASK  Read a binary mask image as a logical array.
%   mask = LOAD_MASK(file) returns true where the image is non-zero. Only
%   the first channel is read, so the mask can be saved in grayscale or RGB.

if ~isfile(file)
    error('load_mask:missing', 'Mask not found: %s', file);
end
img  = imread(file);
mask = logical(img(:, :, 1));
end
