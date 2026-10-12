function albedo = eon_albedo(rho_d, sigma, theta)
%EON_ALBEDO  Albedo of the Energy-preserving Oren-Nayar model.
%   albedo = EON_ALBEDO(rho_d, sigma, theta) returns the directional-
%   hemispherical reflectance (albedo) of an EON surface of diffuse albedo
%   rho_d and roughness sigma, for the incidence angle theta (rad):
%
%       rho_EON^{u_i,cap} = rho_F^{u_i,cap} + rho_ms^{u_i,cap}     (Sec. 3.2)
%
%   Because EON conserves energy, this albedo is a physical quantity that
%   can be compared with integrating-sphere measurements. rho_d and sigma
%   can be arrays of the same size (one value per pixel).

albedo = fon_albedo(rho_d, sigma, theta) + eon_ms_albedo(rho_d, sigma, theta);
end
