function plot_ps_results(est, I, regions, light_dirs, name, out_dir, cfg)
%PLOT_PS_RESULTS  Figures of one photometric stereo result (Sec. 5).
%   PLOT_PS_RESULTS(est, I, regions, light_dirs, name, out_dir, cfg) draws,
%   for the image set "name":
%     <name>_input          the input images, one per light source
%     <name>_albedo_map     the estimated albedo
%     <name>_normals        the estimated normals (a PNG with transparency
%                           outside the mask is also written)
%     <name>_sigma          the estimated roughness
%     <name>_convergence    the fmincon exit flags
%     <name>_albedo         the albedo histogram, with mean and +/- 1 std
%     <name>_sigma_hist     the roughness histogram
%     <name>_albedo_split   the albedo histogram of each region, if any
%     <name>_brdf_polar     the reconstructed EON BRDF, if cfg.plot_brdf
%   When cfg.save_figures is true, each figure is saved in out_dir as .png
%   and .fig, then closed if cfg.close_figures is true.

mask = est.mask;
m = size(I, 1);

%% Input images
fig = figure('Name', [name ': input images']);
layout = tiledlayout(fig, 1, m, 'TileSpacing', 'compact', 'Padding', 'compact');
for i = 1:m
    ax = nexttile(layout);
    imagesc(ax, reshape(I(i, :, :), size(mask)));
    axis(ax, 'image', 'off');
    colormap(ax, gray);
    title(ax, sprintf('Source %d', i));
end
finish(fig, 'input');

%% Albedo map
fig = figure('Name', [name ': albedo']);
h = imagesc(est.albedo, [0 1]);
set(h, 'AlphaData', double(mask));
axis image off;
colormap(gca, gray);
colorbar;
title('Estimated albedo');
finish(fig, 'albedo_map');

%% Normal map
rgb = normals_to_rgb(est.normals, mask);
fig = figure('Name', [name ': normals']);
image(rgb, 'AlphaData', double(mask));
axis image off;
title('Estimated normals');
if cfg.save_figures
    imwrite(rgb, fullfile(out_dir, [name '_normals.png']), 'Alpha', double(mask));
end
finish(fig, 'normals', {'fig'});   % the PNG is the image written just above

%% Roughness map
fig = figure('Name', [name ': roughness']);
h = imagesc(est.sigma, [0 1]);
set(h, 'AlphaData', double(mask));
axis image off;
colorbar;
title('Estimated roughness \sigma');
finish(fig, 'sigma');

%% Convergence map
fig = figure('Name', [name ': convergence']);
h = imagesc(est.exitflag, [-3 3]);
set(h, 'AlphaData', double(mask));
axis image off;
colormap(gca, turbo(7));
cb = colorbar;
cb.Label.String = 'fmincon exit flag (1, 2: converged; 3: solved again in pass 2)';
title(sprintf('Converged on %.1f %% of the pixels', 100 * mean(est.converged(mask))));
finish(fig, 'convergence');

%% Albedo histogram
fig = figure('Name', [name ': albedo distribution']);
[~, mu, sd] = histogram_with_stats(est.albedo(mask));
subtitle(sprintf('mean %.4f, std %.4f', mu, sd));
xlim([0 1]);
xlabel('Albedo');
ylabel('Number of pixels');
title('Albedo distribution');
finish(fig, 'albedo');

%% Roughness histogram
fig = figure('Name', [name ': roughness distribution']);
[~, mu, sd] = histogram_with_stats(est.sigma(mask));
subtitle(sprintf('mean %.3g, std %.3g', mu, sd));
xlabel('\sigma');
ylabel('Number of pixels');
title('Roughness distribution');
finish(fig, 'sigma_hist');

%% Albedo histogram of each region (e.g. the white and gray sides of the Bear)
if ~isempty(regions)
    fig = figure('Name', [name ': albedo per region']);
    hold on;
    colors = lines(numel(regions));
    handles = gobjects(1, numel(regions));
    labels  = cell(1, numel(regions));
    for k = 1:numel(regions)
        values = est.albedo(regions(k).mask & mask);
        [handles(k), mu, sd] = histogram_with_stats(values, colors(k, :), colors(k, :));
        labels{k} = sprintf('%s: %.4f \\pm %.4f', regions(k).name, mu, sd);
    end
    hold off;
    xlim([0 1]);
    xlabel('Albedo');
    ylabel('Number of pixels');
    title('Albedo distribution per region');
    legend(handles, labels, 'Interpreter', 'tex');
    finish(fig, 'albedo_split');
end

%% Reconstructed EON BRDF (Sec. 5.3)
if cfg.plot_brdf
    fig = plot_eon_brdf_polar(est, light_dirs, cfg.brdf_samples);
    finish(fig, 'brdf_polar');
end

    function finish(fig, suffix, formats)
        % Save the figure as <name>_<suffix> and close it if requested.
        if ~cfg.save_figures
            return
        end
        if nargin < 3
            formats = {'png', 'fig'};
        end
        save_figure(fig, out_dir, [name '_' suffix], formats);
        if cfg.close_figures
            close(fig);
        end
    end
end

function [h, mu, sd] = histogram_with_stats(values, color, line_color)
% Histogram of the values, with their mean (solid line) and the mean +/- one
% standard deviation (dashed lines). NaN values are ignored.
if nargin < 2
    color = [0 0.4470 0.7410];
end
if nargin < 3
    line_color = 'r';
end
mu = mean(values, 'omitnan');
sd = std(values, 'omitnan');
h = histogram(values, 'EdgeColor', 'none', 'FaceColor', color);
xline(mu, '-', 'Color', line_color);
xline(mu + sd, '--', 'Color', line_color);
xline(mu - sd, '--', 'Color', line_color);
end
