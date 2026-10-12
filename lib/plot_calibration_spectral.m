function plot_calibration_spectral(samples, labels, out_dir, cfg)
%PLOT_CALIBRATION_SPECTRAL  Calibration coefficients of every run, side by side (Sec. 4.3).
%   PLOT_CALIBRATION_SPECTRAL(samples, labels, out_dir, cfg) draws one box
%   per run, from samples{k} (calibration coefficients of run k, all light
%   sources together, drawn at random over the standard) and labels{k}
%   (the name of its calibration set). The logarithmic scale shows the
%   orders of magnitude between filters, due to the emission spectrum of
%   the sources, the bandwidth of the filters and the spectral sensitivity
%   of the sensor.
%   The figure is saved as calibration_spectral.png/.fig if cfg.save_figures.

samples = cellfun(@(s) s(:), samples, 'UniformOutput', false);   % as columns
values = vertcat(samples{:});
groups = repelem((1:numel(samples))', cellfun(@numel, samples(:)));
labels = matlab.lang.makeUniqueStrings(labels);
groups = categorical(groups, 1:numel(labels), labels);

fig = figure('Name', 'Calibration coefficients of every run');
boxchart(groups, values(:));
set(gca, 'YScale', 'log', 'TickLabelInterpreter', 'none');
grid on;
xlabel('Calibration set');
ylabel('Calibration coefficient $\tilde{S}_i$', 'Interpreter', 'latex');
title('Calibration coefficients of every run');

if cfg.save_figures
    save_figure(fig, out_dir, 'calibration_spectral');
    if cfg.close_figures
        close(fig);
    end
end
end
