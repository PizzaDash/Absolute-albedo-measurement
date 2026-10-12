function S_tilde = reflectometric_calibration(I, light_dirs, rho_ref, standard_normal, mask)
%REFLECTOMETRIC_CALIBRATION  Per-pixel calibration coefficients of the light sources (Sec. 4).
%   S_tilde = REFLECTOMETRIC_CALIBRATION(I, light_dirs, rho_ref,
%   standard_normal, mask) computes the reflectometric calibration
%   coefficient S~_i of every light source at every pixel, from images of
%   a flat white reflectance standard (Spectralon) of certified albedo
%   rho_ref.
%
%   The PS image model (Sec. 3.1) is
%
%       I_i = rho^{u_i,u_r} * S~_i * (u_i . n)
%
%   On the standard, both factors besides S~_i are known:
%     - the normal n is known, because the standard is flat and placed
%       frontoparallel to the camera;
%     - the BRDF is known, because the standard is assumed Lambertian, so
%       that its BRDF is its albedo divided by pi: rho_ref / pi.
%   Hence, at every pixel (Sec. 4.3):
%
%       S~_i = pi * I_i / (rho_ref * cos(theta_i)),   cos(theta_i) = u_i . n
%
%   As the standard is frontoparallel, cos(theta_i) is the same over the
%   whole image of a given source. The spatial variations of S~_i therefore
%   come only from the imaging chain (vignetting, filter, sensor
%   non-uniformity) and from the non-uniformity of the irradiance, which is
%   why the calibration is done pixel by pixel.
%
%   Inputs
%     I                m x H x W images of the standard, one per light source
%                      (gray levels per second)
%     light_dirs       m x 3 unit light directions
%     rho_ref          certified albedo of the standard (0.99 for our Spectralon)
%     standard_normal  normal of the standard, [0 0 -1] when it faces the camera
%     mask             H x W logical, true where the standard is visible
%
%   Output
%     S_tilde          m x H x W calibration coefficients
%
%   Outside the mask, where the standard is not visible, S~_i is
%   extrapolated with a second-order polynomial surface in (row, column),
%   fitted to the values measured inside the mask. The measured values are
%   kept unchanged inside the mask.

[m, H, W] = size(I);

n0 = standard_normal(:) / norm(standard_normal);
cos_theta = light_dirs * n0;   % m x 1, cos(theta_i) of each source on the standard
if any(cos_theta <= 0)
    error('reflectometric_calibration:geometry', ...
          ['Some light directions do not illuminate the standard (u_i . n <= 0). ' ...
           'Light directions must point from the target towards the sources, ' ...
           'in the camera frame described in main.m.']);
end

% Gray level that a coefficient S~_i = 1 would produce on the standard:
% reference BRDF (rho_ref / pi) times the foreshortening cos(theta_i)
ref_signal = (rho_ref / pi) * cos_theta;

[rows_in,  cols_in]  = find(mask);
[rows_out, cols_out] = find(~mask);

S_tilde = zeros(m, H, W);
for i = 1:m
    S_i = reshape(I(i, :, :), H, W) / ref_signal(i);

    if ~isempty(rows_out)
        S_i(~mask) = fit_poly2_surface(rows_in, cols_in, S_i(mask), rows_out, cols_out);
    end
    S_tilde(i, :, :) = S_i;
end
end
