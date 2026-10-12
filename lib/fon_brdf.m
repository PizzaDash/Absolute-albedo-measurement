function f = fon_brdf(sigma, N, S, V)
%FON_BRDF  Fujii Oren-Nayar (FON) BRDF divided by the diffuse albedo.
%   f = FON_BRDF(sigma, N, S, V) returns, for each light source, the FON
%   lobe of the EON model divided by rho_d (Sec. 3.2):
%
%       rho_F / rho_d = (1/pi) * A_F(sigma) * (1 + sigma * g_F(u_i, u_r, n))
%
%   with
%       A_F(sigma) = 1 / (1 + (1/2 - 2/(3 pi)) sigma)
%       g_F        = s / t_F,  s = u_i.u_r - (n.u_i)(n.u_r),
%                  t_F = max(n.u_i, n.u_r) if s > 0, 1 otherwise.
%   It is computed below in the expanded form (1/pi) (A + B s / t_F), with
%   B = sigma * A.
%   Reference: Y. Fujii, "A tiny improvement of Oren-Nayar reflectance
%   model", https://mimosa-pudica.net/improved-oren-nayar.html
%
%   Inputs
%     sigma  roughness, in [0, 1]
%     N      3 x 1 surface normal
%     S      m x 3, one light vector per row (only its direction is used)
%     V      3 x 1 viewing direction (towards the camera)
%   Output
%     f      m x 1

A = 1 ./ (1 + (1/2 - 2/(3*pi)) .* sigma);
B = sigma .* A;

u_i = S ./ vecnorm(S, 2, 2);
n   = N ./ vecnorm(N);
u_r = V ./ vecnorm(V);

s = u_i*u_r - (u_i*n)*(n'*u_r);
t = ones(size(s));
idx = s > 0;
t(idx) = max(u_i(idx, :)*n, n'*u_r);

f = (1/pi) * (A + B.*s./t);
end
