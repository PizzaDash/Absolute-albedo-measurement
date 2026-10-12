function regions = load_region_masks(folder)
%LOAD_REGION_MASKS  Optional sub-regions of an image set.
%   regions = LOAD_REGION_MASKS(folder) reads every folder/mask_<name>.tif
%   file and returns a struct array with the fields "name" and "mask". The
%   albedo statistics are then also computed separately on each region, as
%   for the two halves of the "Bear" object, painted white on one side and
%   gray on the other (Sec. 5.6).
%   mask_radiance.tif, which belongs to calibration sets, is ignored.

regions = struct('name', {}, 'mask', {});
files = dir(fullfile(folder, 'mask_*.tif'));
for k = 1:numel(files)
    [~, base] = fileparts(files(k).name);
    region_name = extractAfter(base, 'mask_');
    if strcmp(region_name, 'radiance')
        continue
    end
    regions(end+1).name = region_name; %#ok<AGROW>
    regions(end).mask   = load_mask(fullfile(folder, files(k).name));
end
end
