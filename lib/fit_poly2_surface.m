function values_eval = fit_poly2_surface(rows, cols, values, rows_eval, cols_eval)
%FIT_POLY2_SURFACE  Least-squares fit of a second-order polynomial surface.
%   values_eval = FIT_POLY2_SURFACE(rows, cols, values, rows_eval, cols_eval)
%   fits the surface
%
%       v(r, c) = a1 + a2 r + a3 c + a4 r^2 + a5 r c + a6 c^2
%
%   to the samples values(k) observed at the pixels (rows(k), cols(k)), and
%   evaluates it at the pixels (rows_eval, cols_eval). It is used to
%   extrapolate the calibration coefficients outside the area covered by
%   the reflectance standard.
%
%   Coordinates are centred and scaled before the fit, to keep the least-
%   squares system well conditioned on large images. This does not change
%   the fitted surface, since any affine change of the coordinates maps
%   second-order polynomials onto second-order polynomials.

rows   = double(rows(:));
cols   = double(cols(:));
values = double(values(:));

r0 = mean(rows);
c0 = mean(cols);
scale = max([std(rows), std(cols), 1]);

x = (rows - r0) / scale;
y = (cols - c0) / scale;
A = [ones(size(x)), x, y, x.^2, x.*y, y.^2];
a = A \ values;   % least-squares solution

xe = (double(rows_eval(:)) - r0) / scale;
ye = (double(cols_eval(:)) - c0) / scale;
values_eval = a(1) + a(2)*xe + a(3)*ye + a(4)*xe.^2 + a(5)*xe.*ye + a(6)*ye.^2;
end
