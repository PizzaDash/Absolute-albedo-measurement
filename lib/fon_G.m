function G = fon_G(cos_theta)
%FON_G  Angular function G_F of the Fujii albedo.
%   G = FON_G(cos_theta) evaluates, for theta in [0, pi/2],
%
%       G_F(theta) = sin(theta) (theta - 2/3 - sin(theta) cos(theta))
%                    + 2/3 tan(theta) (1 - sin(theta)^3)
%
%   which is the paper's G_q(theta) - 2/3 sin(theta) (Sec. 3.2). At grazing
%   incidence tan(theta) diverges, so the first-order approximation used in
%   Blender, G_F ~ (pi/2 - 2/3) - cos(theta), is used instead.
%
%   NOTE: with a vector input, the grazing approximation is applied only
%   when *every* element is grazing (this is how MATLAB evaluates "if" on
%   an array, and it is the behaviour of the code used for the paper).
%   Pass a scalar to get the element-wise behaviour.

if all(cos_theta < 1e-6)
    G = (pi/2 - 2/3) - cos_theta;
else
    sin_theta = sqrt(1 - cos_theta.^2);
    theta = acos(cos_theta);
    G = sin_theta .* (theta - 2/3 - sin_theta .* cos_theta) + ...
        (2/3) .* (sin_theta ./ cos_theta) .* (1 - sin_theta.^3);
end
end
