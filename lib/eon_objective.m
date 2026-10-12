function f = eon_objective(x, pars)
%EON_OBJECTIVE  Least-squares cost of EON photometric stereo at one pixel.
%   f = EON_OBJECTIVE(x, pars) returns
%
%       f = 1/2 * sum_i ( I_i^obs - rho_EON(rho_d, sigma, n) * S~_i * (u_i . n) )^2
%
%   for the unknowns x = [rho_d; sigma; n1; n2; n3] (Sec. 3.3).
%
%   pars is a struct with the fields
%     I  m x 1 observed gray levels of the pixel
%     S  m x 3 lighting matrix of the pixel, row i = S~_i * u_i
%     V  3 x 1 viewing direction

rho_d = x(1);
sigma = x(2);
n     = x(3:5);

brdf     = eon_brdf(rho_d, sigma, n, pars.S, pars.V);   % m x 1
residual = pars.I - (pars.S * n) .* brdf;               % S * n = S~_i (u_i . n)
f = sum((residual.^2) ./ 2);
end
