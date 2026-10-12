function f = eon_brdf(rho_d, sigma, N, S, V)
%EON_BRDF  BRDF of the Energy-preserving Oren-Nayar (EON) model.
%   f = EON_BRDF(rho_d, sigma, N, S, V) returns the EON BRDF (in 1/sr) of
%   a surface of diffuse albedo rho_d, roughness sigma and normal N, for
%   each light direction (rows of S) and the viewing direction V
%   (Sec. 3.2). It is the BRDF fitted to the images by EON photometric
%   stereo.
%
%   Inputs
%     rho_d  diffuse albedo, in [0, 1]
%     sigma  roughness, in [0, 1]
%     N      3 x 1 surface normal
%     S      m x 3, one light vector per row (only its direction is used)
%     V      3 x 1 viewing direction (towards the camera)
%   Output
%     f      m x 1
%
%   NOTE: EON_MS_BRDF already includes the rho_d^2 factor of the multiple-
%   scattering term, so the product below weights that term by rho_d^3,
%   whereas the EON BRDF of the paper, rho_F + rho_ms, weights it by
%   rho_d^2 (as does the albedo computed in EON_MS_ALBEDO). This is the
%   formulation of the original code. The paper's would read
%       f = rho_d .* fon_brdf(sigma, N, S, V) + eon_ms_brdf(rho_d, sigma, N, S, V);

f = rho_d .* (fon_brdf(sigma, N, S, V) + eon_ms_brdf(rho_d, sigma, N, S, V));
end
