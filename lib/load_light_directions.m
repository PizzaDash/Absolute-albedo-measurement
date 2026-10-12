function light_dirs = load_light_directions(file, sources)
%LOAD_LIGHT_DIRECTIONS  Read the light directions of a run.
%   light_dirs = LOAD_LIGHT_DIRECTIONS(file) returns an m x 3 matrix whose
%   i-th row is the unit vector u_i pointing from the target towards the
%   i-th light source, in the camera frame (see main.m). The paper assumes
%   that these directions are known (Sec. 4): ours were measured beforehand
%   with a separate geometric calibration based on AprilTag markers.
%
%   The file must contain either a variable "light_dirs" (m x 3) or a
%   struct "calib" with a field "S" (m x 3), the format written by that
%   geometric calibration.
%
%   light_dirs = LOAD_LIGHT_DIRECTIONS(file, sources) keeps only the rows
%   listed in sources (e.g. [1 2 4 5]). An empty sources keeps every row.

if nargin < 2
    sources = [];
end

loaded = load(file);
if isfield(loaded, 'light_dirs')
    light_dirs = loaded.light_dirs;
elseif isfield(loaded, 'calib') && isfield(loaded.calib, 'S')
    light_dirs = loaded.calib.S;
else
    error('load_light_directions:format', ...
          '%s must contain "light_dirs" (m x 3) or "calib.S" (m x 3).', file);
end

if ~isempty(sources)
    light_dirs = light_dirs(sources, :);
end

% Only the direction matters: the calibration coefficient S~_i carries the
% intensity. Normalize the rows, and warn if they were far from unit.
row_norms = vecnorm(light_dirs, 2, 2);
if any(abs(row_norms - 1) > 1e-3)
    warning('load_light_directions:norm', ...
            'Light directions in %s are not unit vectors: they have been normalized.', file);
end
light_dirs = light_dirs ./ row_norms;
end
