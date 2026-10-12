%% Physically accurate albedo calibration for Photometric Stereo
% Main script: reflectometric calibration followed by photometric stereo
% (PS) with the Energy-preserving Oren-Nayar (EON) model, as described in
%
%   T. Fevrier, J. Delpech, T. Sentenac, Y. Queau, F. Bugarin,
%   "Physically accurate albedo calibration for Photometric Stereo".
%
% For each acquisition run (one wavelength, one set of light positions) the
% script:
%   1. computes the calibration coefficient S~_i of every light source at
%      every pixel, from images of a frontoparallel Spectralon standard of
%      known albedo (Sec. 4);
%   2. estimates on every measured image set the diffuse albedo rho_d, the
%      roughness sigma and the normals with the EON model, then the albedo
%      (Sec. 3);
%   3. saves the maps, the figures and a table of the mean and standard
%      deviation of the albedo of every image set (Sec. 5).
%
% Inputs are read from data/ (see data/README.md for the expected layout).
% Every output is written to results/.
%
% Conventions
%   - Camera frame (OpenCV convention): x along the image columns, y along
%     the image rows (pointing down), z along the optical axis, away from
%     the camera.
%   - Light direction u_i: unit vector from the target towards the i-th
%     source, so its z component is negative.
%   - A surface facing the camera has the normal n = [0 0 -1]. The camera
%     is orthographic: the viewing direction is u_r = [0 0 -1] everywhere.
%   - Images are expressed in gray levels per second (divided by their
%     integration time), so that images acquired with different exposures
%     can be compared.

clear; close all; clc;

root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'lib'));
rng(0, 'twister');   % the random pixel subsets drawn for some figures are reproducible

%% Settings
cfg.data_dir    = fullfile(root, 'data/experiment_1');
cfg.results_dir = fullfile(root, 'results');

% Reflectometric calibration (Sec. 4)
cfg.rho_ref         = 0.99;        % certified albedo of the Spectralon standard
cfg.standard_normal = [0 0 -1];    % the standard is flat and faces the camera

% EON photometric stereo (Sec. 3.3)
cfg.view_dir     = [0 0 -1];       % orthographic camera looking along +z
cfg.sigma0       = 0.1;            % initial roughness of the first pass
cfg.window_size  = 3;              % side of the averaging window of the second pass (pixels)
cfg.albedo_theta = deg2rad(8);     % incidence angle at which the albedo is reported: 8 deg is
                                   % the illumination angle of the integrating sphere used for
                                   % the reference measurements (Sec. 5.1)
cfg.reuse_estimates = false;       % true: reload results/<set>/<set>_estimates.mat when it
                                   % exists instead of running the (slow) optimisation again

% Figures
cfg.save_figures  = true;          % save every figure as .png and .fig in results/
cfg.close_figures = true;          % close each figure once saved (one run = many figures)
cfg.plot_brdf     = true;          % polar plot of the reconstructed EON BRDF (Sec. 5.3)
cfg.brdf_samples  = 200;           % number of pixels drawn at random for that plot

%% Acquisition runs
% One entry per calibration. Each run gives:
%   wavelength_nm     centre wavelength of the filter (only used to label the outputs)
%   calibration_set   subfolder of data/ with the images of the Spectralon standard
%   light_directions  file of data/ with the light directions (see data/README.md)
%   light_sources     rows of that file to use, in the order of the images
%                     ([] = all of them, e.g. [1 2 4 5] to use 4 sources out of 5)
%   ps_sets           subfolders of data/ with the image sets to reconstruct, acquired
%                     with the same light positions, filter and camera settings as
%                     the calibration set
% With image sets named as below, the figures are written under the file names
% used in the paper (e.g. 450nm_flat_albedo_map.png).

runs = struct('wavelength_nm', {}, 'calibration_set', {}, 'light_directions', {}, ...
              'light_sources', {}, 'ps_sets', {});

% Example: one acquisition session at the three wavelengths of the paper
wavelengths = [450 630 780];
for k = 1:numel(wavelengths)
    w = sprintf('%dnm', wavelengths(k));
    runs(end+1).wavelength_nm  = wavelengths(k); %#ok<SAGROW>
    runs(end).calibration_set  = [w '_calib'];
    runs(end).light_directions = 'light_directions.mat';
    runs(end).light_distances = 'light_distances.mat';
    runs(end).light_sources    = [];
    % runs(end).ps_sets          = {[w '_spectralon_99'], [w '_spectralon_50'], ...
    %                               [w '_spectralon_20'], [w '_flat'], [w '_sphere']};
    runs(end).ps_sets          = {[w '_flat']};
end

% Image sets acquired in another session (other light positions) need a run of
% their own, with their own calibration images and light directions, e.g.:
% runs(end+1).wavelength_nm  = 450;
% runs(end).calibration_set  = 'session2_450nm_calib';
% runs(end).light_directions = 'session2_light_directions.mat';
% runs(end).light_sources    = [];
% runs(end).ps_sets          = {'450nm_flatdark', '450nm_spheredark'};

%% Check that every input exists before starting (the optimisation is long)
missing = {};
for r = 1:numel(runs)
    folders = [{runs(r).calibration_set}, runs(r).ps_sets];
    for k = 1:numel(folders)
        if ~isfolder(fullfile(cfg.data_dir, folders{k}))
            missing{end+1} = [folders{k} filesep]; %#ok<SAGROW>
        end
    end
    if ~isfile(fullfile(cfg.data_dir, runs(r).light_directions))
        missing{end+1} = runs(r).light_directions; %#ok<SAGROW>
    end
end
if ~isempty(missing)
    error('main:missingData', ['Missing inputs in %s:\n  %s\n' ...
          'Edit the "Acquisition runs" section of main.m or see data/README.md.'], ...
          cfg.data_dir, strjoin(unique(missing), '\n  '));
end

%% Processing
summary = table();
calib_samples = cell(1, numel(runs));   % S~ values of each run, for the spectral comparison

for r = 1:numel(runs)
    this_run = runs(r);
    fprintf('\n===== Run %d/%d: %d nm, calibration set "%s" =====\n', ...
            r, numel(runs), this_run.wavelength_nm, this_run.calibration_set);

    %% 1. Reflectometric calibration (Sec. 4)
    calib_dir  = fullfile(cfg.data_dir, this_run.calibration_set);
    light_dirs = load_light_directions(fullfile(cfg.data_dir, this_run.light_directions), ...
                                       this_run.light_sources);
    load(fullfile(cfg.data_dir, this_run.light_distances))
    light_distances = distances;
    I_calib    = load_image_set(calib_dir);
    calib_mask = load_mask(fullfile(calib_dir, 'mask_radiance.tif'));

    [m, H, W] = size(I_calib);
    if size(light_dirs, 1) ~= m
        error('main:sourceCount', '%s contains %d images but %d light directions were given.', ...
              this_run.calibration_set, m, size(light_dirs, 1));
    end

    S_tilde = reflectometric_calibration(I_calib, light_dirs, cfg.rho_ref, ...
                                         cfg.standard_normal, calib_mask);

    out_dir = fullfile(cfg.results_dir, this_run.calibration_set);
    if ~isfolder(out_dir), mkdir(out_dir); end
    calib = struct('S_tilde', S_tilde, 'light_dirs', light_dirs, 'mask', calib_mask, ...
                   'rho_ref', cfg.rho_ref, 'wavelength_nm', this_run.wavelength_nm);
    save(fullfile(out_dir, 'calib.mat'), 'calib');
    plot_calibration(S_tilde, light_distances, calib_mask, this_run.calibration_set, out_dir, cfg);

    % Keep a random subset of the measured coefficients for the comparison
    % between wavelengths drawn at the end (all pixels of all runs would use a lot of memory)
    S_flat = reshape(S_tilde, m, H * W);
    values = S_flat(:, calib_mask(:));
    calib_samples{r} = values(randperm(numel(values), min(numel(values), 2e5)));

    %% 2. EON photometric stereo on each image set (Sec. 3)
    for k = 1:numel(this_run.ps_sets)
        name    = this_run.ps_sets{k};
        set_dir = fullfile(cfg.data_dir, name);
        out_dir = fullfile(cfg.results_dir, name);
        if ~isfolder(out_dir), mkdir(out_dir); end
        fprintf('\n--- Image set "%s" ---\n', name);

        I    = load_image_set(set_dir);
        mask = load_mask(fullfile(set_dir, 'mask.tif'));
        if ~isequal(size(I), [m H W])
            error('main:size', '"%s" must contain %d images of %dx%d pixels, like "%s".', ...
                  name, m, H, W, this_run.calibration_set);
        end
        I = reshape(I, m, H * W);   % one row per light source, one column per pixel
        I(I < 0) = 0;

        est_file = fullfile(out_dir, [name '_estimates.mat']);
        if cfg.reuse_estimates && isfile(est_file)
            fprintf('Reusing %s\n', est_file);
            loaded = load(est_file, 'est');
            est = loaded.est;
        else
            % Lighting matrix of each pixel inside the mask: row i of S(:,:,q) is
            % S~_i(x_q) * u_i, so that S(:,:,q) * n = S~_i * (u_i . n), the factor
            % that multiplies the BRDF in the PS image model (Sec. 3.1)
            inside = find(mask);
            S = reshape(S_flat(:, inside), m, 1, []) .* light_dirs;   % m x 3 x numel(inside)

            tic;
            est = eon_photometric_stereo(I, S, mask, cfg);
            fprintf('EON photometric stereo done in %.1f min\n', toc / 60);
            est.image_set     = name;
            est.wavelength_nm = this_run.wavelength_nm;
            save(est_file, 'est', '-v7.3');   % v7.3 format: the maps of large images can exceed 2 GB
        end

        %% 3. Statistics and figures (Sec. 5)
        regions = load_region_masks(set_dir);   % optional mask_<region>.tif files
        stats = summarize_estimates(est, regions, name, this_run.wavelength_nm);
        disp(stats);
        summary = [summary; stats]; %#ok<AGROW>

        plot_ps_results(est, reshape(I, m, H, W), regions, light_dirs, name, out_dir, cfg);
    end
end

%% Summary of all runs
writetable(summary, fullfile(cfg.results_dir, 'summary.csv'));
fprintf('\n===== Summary (also in results/summary.csv) =====\n');
disp(summary);

% Distribution of the calibration coefficients of each run: they differ by
% orders of magnitude from one filter to another (Sec. 4.3)
if numel(runs) > 1
    plot_calibration_spectral(calib_samples, {runs.calibration_set}, cfg.results_dir, cfg);
end
