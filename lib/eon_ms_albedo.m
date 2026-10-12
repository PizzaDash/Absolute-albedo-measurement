function albedo = eon_ms_albedo(rho_d, sigma, theta)
%EON_MS_ALBEDO  Directional-hemispherical albedo of the EON multiple-scattering term.
%   albedo = EON_MS_ALBEDO(rho_d, sigma, theta) integrates the multiple-
%   scattering term of the EON BRDF over the reflection hemisphere, for the
%   incidence angle theta (rad). In the form that remains defined when
%   sigma -> 0 (Sec. 3.2):
%
%       rho_ms^{u_i,cap} = rho_d^2 E_avg (1 - E(theta)) / (1 - rho_d (1 - E_avg))
%
%   with E(theta) the normalized FON albedo and E_avg its hemispherical
%   average (see EON_MS_BRDF). rho_d and sigma can be arrays of the same
%   size (one value per pixel).

A = 1 ./ (1 + (1/2 - 2/(3*pi)) .* sigma);
B = sigma .* A;
E_avg = A + ((2 - 5.6/pi) / 3) .* B;

% Normalized FON albedo for the incidence angle theta. It is obtained by
% dividing the FON albedo by rho_d, so pixels with rho_d = 0 give NaN (and
% are then left out of the mean albedo).
E_theta = fon_albedo(rho_d, sigma, theta) ./ rho_d;

F = rho_d .* E_avg ./ (1 - rho_d .* (1 - E_avg));

if all(abs(1 - E_avg) <= 1e-7)
    % Every pixel is in the Lambertian limit sigma -> 0: no multiple scattering
    albedo = zeros(size(rho_d));
else
    albedo = rho_d .* F .* (1 - E_theta);
end
end
