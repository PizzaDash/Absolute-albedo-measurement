function albedo = fon_albedo(rho_d, sigma, theta)
%FON_ALBEDO  Directional-hemispherical albedo of the FON lobe.
%   albedo = FON_ALBEDO(rho_d, sigma, theta) returns the albedo of the
%   Fujii Oren-Nayar lobe for the incidence angle theta (rad), i.e. rho_d
%   times the normalized Fujii albedo of Sec. 3.2:
%
%       rho_F^{u_i,cap} = rho_d * A_F(sigma) * (1 + sigma/pi * G_F(theta))
%
%   rho_d and sigma can be arrays of the same size (one value per pixel).

A = 1 ./ (1 + (1/2 - 2/(3*pi)) .* sigma);
B = sigma .* A;
G = fon_G(cos(theta));
albedo = rho_d .* (A + (B ./ pi) .* G);
end
