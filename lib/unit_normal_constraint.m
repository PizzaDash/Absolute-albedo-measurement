function [c, ceq] = unit_normal_constraint(x)
%UNIT_NORMAL_CONSTRAINT  Nonlinear constraint ||n|| = 1 for fmincon.
%   For the unknowns x = [rho_d; sigma; n1; n2; n3], returns no inequality
%   constraint and the equality constraint ||n|| - 1 = 0, which keeps the
%   estimated normal a unit vector.

c   = [];
ceq = norm(x(3:5)) - 1;
end
