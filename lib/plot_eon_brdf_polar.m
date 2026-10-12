function fig = plot_eon_brdf_polar(est, light_dirs, n_samples)
%PLOT_EON_BRDF_POLAR  BRDF reconstructed from the EON estimates (Sec. 5.3).
%   fig = PLOT_EON_BRDF_POLAR(est, light_dirs, n_samples) draws n_samples
%   pixels at random among the converged ones and plots, for each of them,
%   the EON BRDF given by its estimated rho_d and sigma, for incidence
%   angles from 0 to 90 deg and a reflection angle of 0 deg (surface
%   observed along its normal, as in our setup). The values at the
%   incidence angles of the actual light sources are marked with "+".
%
%   For a Lambertian surface of albedo rho (sigma -> 0), every curve is the
%   constant rho / pi: 0.315 sr^-1 for the 99 % Spectralon.

candidates = find(est.mask & est.converged);
if isempty(candidates)
    candidates = find(est.mask);
end
pick = candidates(randperm(numel(candidates), min(n_samples, numel(candidates))));

n = [0; 0; -1];                    % surface facing the camera
v = [0; 0; -1];                    % viewing direction (reflection angle 0)
theta = linspace(0, pi/2, 100);    % incidence angles of the curve
theta_src = acos(light_dirs * n);  % incidence angles of the light sources
m = size(light_dirs, 1);

fig = figure('Name', 'Reconstructed EON BRDF');
if isempty(pick)
    title('No pixel to plot');
    return
end
pax = polaraxes(fig);
hold(pax, 'on');
for k = 1:numel(pick)
    rho_d = est.rho_d(pick(k));
    sigma = est.sigma(pick(k));

    % Incidence directions in the (y, z) plane, pointing towards the light.
    % The BRDF is evaluated one angle at a time so that the grazing-angle
    % approximation of FON_G applies at 90 deg.
    brdf = zeros(size(theta));
    for t = 1:numel(theta)
        u = [0, sin(theta(t)), -cos(theta(t))];
        brdf(t) = eon_brdf(rho_d, sigma, n, u, v);
    end
    brdf_src = zeros(m, 1);
    for i = 1:m
        brdf_src(i) = eon_brdf(rho_d, sigma, n, light_dirs(i, :), v);
    end

    h_curve  = polarplot(pax, theta, brdf, 'b');
    h_source = polarplot(pax, theta_src, brdf_src, 'b+');
end
hold(pax, 'off');
pax.ThetaDir = 'clockwise';
pax.ThetaZeroLocation = 'top';
thetalim(pax, [0 90]);
title(pax, 'EON BRDF reconstructed from the estimates (sr^{-1})');
legend(pax, [h_curve, h_source], {'EON BRDF model', 'BRDF at the light source directions'}, ...
       'Location', 'southoutside');
end
