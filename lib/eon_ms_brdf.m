function f_ms = eon_ms_brdf(rho_d, sigma, N, S, V)
%EON_MS_BRDF  Multiple-scattering term of the EON BRDF.
%   f_ms = EON_MS_BRDF(rho_d, sigma, N, S, V) returns, for each light
%   source, the multiple-scattering term rho_ms of the Energy-preserving
%   Oren-Nayar model (Sec. 3.2), which restores the energy lost by the FON
%   lobe:
%
%       rho_ms = F(rho_d, sigma) / pi * (1 - E(u_i)) (1 - E(u_r)) / (1 - E_avg)^2
%
%       F      = rho_d^2 E_avg (1 - E_avg) / (1 - rho_d (1 - E_avg))
%       E(u)   = A_F (1 + sigma/pi G_F(theta))     normalized FON albedo for
%                                                  the direction u (rho^_F)
%       E_avg  = A_F (1 + (2/3 - 28/(15 pi)) sigma) its hemispherical average (rho-_F)
%
%   Below, the factor (1 - E_avg) of F is cancelled against the
%   denominator, so F only holds rho_d^2 E_avg / (1 - rho_d (1 - E_avg)).
%   Reference: J. Portsmouth et al., "EON: A practical energy-preserving
%   rough diffuse BRDF", Journal of Computer Graphics Techniques, 2025.
%
%   Inputs and output: see FON_BRDF (f_ms is m x 1).

A = 1 ./ (1 + (1/2 - 2/(3*pi)) .* sigma);
B = sigma .* A;
E_avg = A + ((2 - 5.6/pi) / 3) * B;   % = A_F (1 + (2/3 - 28/(15 pi)) sigma)

u_i = S ./ vecnorm(S, 2, 2);
n   = N ./ vecnorm(N);
u_r = V ./ vecnorm(V);

% Normalized FON albedos in the incidence and viewing directions
E_i = A + B .* fon_G(u_i*n) ./ pi;
E_r = A + B .* fon_G(u_r'*n) ./ pi;

F = rho_d.^2 .* E_avg ./ (1 - rho_d .* (1 - E_avg));

if abs(1 - E_avg) <= 1e-9
    % sigma -> 0: Lambertian limit, where the term vanishes (avoids 0/0)
    f_ms = zeros(size(E_i));
else
    f_ms = (F ./ pi) .* ((1 - E_i) .* (1 - E_r) ./ (1 - E_avg));
end
end
