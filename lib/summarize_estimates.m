function stats = summarize_estimates(est, regions, image_set, wavelength_nm)
%SUMMARIZE_ESTIMATES  Mean and standard deviation of the estimates of one image set.
%   stats = SUMMARIZE_ESTIMATES(est, regions, image_set, wavelength_nm)
%   returns a table with one row for the whole mask ("all") and one row per
%   region of the struct array regions (see LOAD_REGION_MASKS). These are
%   the values compared with the reference albedo in Sec. 5. Pixels where
%   the albedo is undefined (NaN) are left out.

names = [{'all'}, {regions.name}];
masks = [{est.mask}, cellfun(@(r) r & est.mask, {regions.mask}, 'UniformOutput', false)];
n = numel(names);

n_pixels      = zeros(n, 1);
albedo_mean   = zeros(n, 1);
albedo_std    = zeros(n, 1);
sigma_mean    = zeros(n, 1);
sigma_std     = zeros(n, 1);
converged_pct = zeros(n, 1);

for k = 1:n
    in = masks{k};
    albedo = est.albedo(in);
    sigma  = est.sigma(in);
    n_pixels(k)      = nnz(in);
    albedo_mean(k)   = mean(albedo, 'omitnan');
    albedo_std(k)    = std(albedo, 'omitnan');
    sigma_mean(k)    = mean(sigma, 'omitnan');
    sigma_std(k)     = std(sigma, 'omitnan');
    converged_pct(k) = 100 * mean(est.converged(in));
end

stats = table(repmat(wavelength_nm, n, 1), repmat(string(image_set), n, 1), string(names(:)), ...
              n_pixels, albedo_mean, albedo_std, sigma_mean, sigma_std, converged_pct, ...
              'VariableNames', {'wavelength_nm', 'image_set', 'region', 'n_pixels', ...
                                'albedo_mean', 'albedo_std', 'sigma_mean', 'sigma_std', ...
                                'converged_pct'});
end
