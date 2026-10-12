function plot_calibration(S_tilde, distances, mask, name, out_dir, cfg)
%PLOT_CALIBRATION  Distribution of the calibration coefficients of one run (Sec. 4.3).
%   PLOT_CALIBRATION(S_tilde, mask, name, out_dir, cfg) prints the mean and
%   standard deviation of S~_i of each light source over the pixels where
%   the standard is visible, and plots their histograms. Within one image,
%   S~_i varies only through the imaging chain and the non-uniformity of the
%   irradiance; from one source to another, the means mostly follow the
%   inverse-square law of the source-target distance.
%   The figure is saved as <name>_S_tilde.png/.fig if cfg.save_figures.

m = size(S_tilde, 1);
S_flat = reshape(S_tilde, m, []);
colors = lines(m);

fig = figure('Name', [name ': calibration coefficients']);
hold on;
fprintf('Calibration coefficients over the standard:\n');
[distances_sort,idx_sort] = sort(distances./1000); % sort and convert to meters while at it
rad_mean = mean(S_flat,2);
rad_std = std(S_flat,[],2);
errorbar(distances_sort,rad_mean(idx_sort),rad_std(idx_sort),'-o')
point_labels = strings(1,m);
for i=1:m
    point_labels(i) = strcat("p",num2str(idx_sort(i)));
end
grid
xlabel('distance (m)')
ylabel('calibrated $\tilde{S}_i$',Rotation=0)
title("Calibrated intensity of light sources")

% fit inverse square law on existing points
hold on
funth = @(x,xdata)  x./(xdata.^2);
fitcoeff = lsqcurvefit(funth,1,distances_sort,rad_mean(idx_sort));
% plot fitted curve
D = linspace(0, 2, 100);
plot(D,funth(fitcoeff,D));
xlim([min(distances_sort) - 0.02, max(distances_sort) + 0.02])

legends = strings(1,2);
legends(1) = "Calibrated intensities";
legends(2) = "Inverse square law";
legend(legends);

if cfg.save_figures
    save_figure(fig, out_dir, [name '_S_tilde']);
    if cfg.close_figures
        close(fig);
    end
end
end
