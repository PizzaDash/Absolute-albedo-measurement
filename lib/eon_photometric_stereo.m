function est = eon_photometric_stereo(I, S, mask, opts)
%EON_PHOTOMETRIC_STEREO  Calibrated photometric stereo with the EON model (Sec. 3.3).
%   est = EON_PHOTOMETRIC_STEREO(I, S, mask, opts) estimates, at every
%   pixel of the mask, the diffuse albedo rho_d, the roughness sigma and
%   the unit normal n that best explain the observed gray levels:
%
%       min  sum_i ( I_i^obs - rho_EON(rho_d, sigma, n) * S~_i * (u_i . n) )^2
%       s.t. rho_d in [0, 1], sigma in [0, 1], ||n|| = 1
%
%   Each pixel is solved independently with fmincon (sequential quadratic
%   programming), in two passes (Algorithm 1 of the paper):
%     1. every pixel starts from the closed-form Lambertian PS solution for
%        rho_d and n, and from sigma = opts.sigma0;
%     2. every pixel where pass 1 did not converge is solved again,
%        starting from the average of the converged estimates of the
%        neighbouring pixels (the unknowns vary continuously over the
%        surface, so they make a better starting point).
%   The albedo is then computed from rho_d and sigma with the EON model.
%
%   Inputs
%     I     m x P observed images, one row per light source (P = H*W)
%     S     m x 3 x Q lighting matrices of the Q pixels of the mask, in the
%           order of find(mask): row i of S(:,:,q) is S~_i * u_i
%     mask  H x W logical, pixels to reconstruct
%     opts  struct with the fields
%             view_dir      viewing direction, [0 0 -1] for our setup
%             sigma0        initial roughness of pass 1
%             window_size   side of the averaging window of pass 2 (pixels)
%             albedo_theta  incidence angle (rad) at which the albedo is computed
%
%   Output: struct est with H x W maps (NaN outside the mask)
%     albedo     EON albedo at the incidence angle opts.albedo_theta
%     rho_d      diffuse albedo (EON parameter)
%     sigma      roughness
%     normals    H x W x 3 unit normals, in the camera frame
%     exitflag   fmincon exit flag of pass 1 (1 or 2: converged; -3 here:
%                fmincon raised an error), or 3 for the pixels solved again
%                in pass 2
%     converged  logical, true where the final estimate converged
%     mask       the input mask
%     options    the options used

[H, W] = size(mask);
inside = find(mask);
Q = numel(inside);
I_in = I(:, inside);
v = opts.view_dir(:) / norm(opts.view_dir);

% Solver settings, identical for both passes
solver.options = optimoptions(@fmincon, 'Display', 'none', 'Algorithm', 'sqp', ...
    'MaxIterations', 500, 'MaxFunctionEvaluations', 5000, ...
    'ConstraintTolerance', 1e-8, 'OptimalityTolerance', 1e-15, 'StepTolerance', 1e-15);
solver.lb = [0; 0; -1; -1; -1];   % unknowns x = [rho_d; sigma; n1; n2; n3]
solver.ub = [1; 1;  1;  1;  1];
solver.v  = v;

rho_d_in     = zeros(1, Q);
sigma_in     = zeros(1, Q);
n_in         = zeros(3, Q);
exitflag_in  = zeros(1, Q);
converged_in = false(1, Q);
progress_step = max(1, round(Q / 20));

%% Pass 1: initialization with Lambertian photometric stereo
fprintf('Pass 1 on %d pixels...\n', Q);
parfor q = 1:Q
    if mod(q, progress_step) == 0
        fprintf('  %d/%d\n', q, Q);
    end
    S_q = S(:, :, q);
    I_q = I_in(:, q);

    % Lambertian PS: with a BRDF rho_d / pi, I = S_q * (rho_d / pi * n), so
    % the linear least-squares solution M gives the normal direction, and
    % its norm (rho_d / pi under that model) is used as initial rho_d
    M  = S_q \ I_q;
    x0 = [norm(M); opts.sigma0; M / norm(M)];

    [x, exitflag] = solve_pixel(I_q, S_q, x0, solver);

    rho_d_in(q)     = x(1);
    sigma_in(q)     = x(2);
    n_in(:, q)      = x(3:5);
    exitflag_in(q)  = exitflag;
    converged_in(q) = (exitflag == 1 || exitflag == 2);
end
fprintf('Pass 1: fmincon converged for %.3g %% of the pixels\n', 100 * mean(converged_in));

%% Pass 2: pixels that did not converge, initialized from their neighbours
% Full-image maps of the pass-1 results, to look up the neighbours
converged_map = false(1, H*W);
converged_map(inside) = converged_in;
x_map = zeros(5, H*W);
x_map(:, inside) = [rho_d_in; sigma_in; n_in];
half = floor(opts.window_size / 2);

fprintf('Pass 2 on %d pixels...\n', sum(~converged_in));
parfor q = 1:Q
    if converged_in(q)
        continue
    end

    % Average of the converged estimates in the window centred on the pixel
    [r, c] = ind2sub([H, W], inside(q));
    x_sum = zeros(5, 1);
    count = 0;
    for dr = -half:half
        for dc = -half:half
            rr = r + dr;
            cc = c + dc;
            if rr < 1 || rr > H || cc < 1 || cc > W
                continue   % neighbour outside the image
            end
            k = rr + (cc - 1) * H;   % linear index of the neighbour
            if converged_map(k)
                x_sum = x_sum + x_map(:, k);
                count = count + 1;
            end
        end
    end
    if count == 0
        continue   % no converged neighbour: the pass-1 estimate is kept
    end
    x0 = x_sum / count;
    x0(3:5) = x0(3:5) / norm(x0(3:5));

    [x, exitflag] = solve_pixel(I_in(:, q), S(:, :, q), x0, solver);

    rho_d_in(q)     = x(1);
    sigma_in(q)     = x(2);
    n_in(:, q)      = x(3:5);
    exitflag_in(q)  = 3;   % marks the pixels solved again in pass 2
    converged_in(q) = (exitflag == 1 || exitflag == 2);
end
fprintf('Pass 2: fmincon converged for %.3g %% of the pixels\n', 100 * mean(converged_in));

%% Albedo
% The EON albedo depends on the incidence angle. It is computed at the
% angle of the reference measurements, so that both can be compared.
albedo_in = eon_albedo(rho_d_in, sigma_in, opts.albedo_theta);

%% Outputs as image maps
est.albedo   = to_map(albedo_in, inside, H, W);
est.rho_d    = to_map(rho_d_in, inside, H, W);
est.sigma    = to_map(sigma_in, inside, H, W);
normals = nan(H*W, 3);
normals(inside, :) = n_in.';
est.normals  = reshape(normals, H, W, 3);
est.exitflag = to_map(exitflag_in, inside, H, W);
est.converged = false(H, W);
est.converged(inside) = converged_in;
est.mask = mask;
est.options = struct('view_dir', v.', 'sigma0', opts.sigma0, ...
                     'window_size', opts.window_size, 'albedo_theta', opts.albedo_theta);
end

function [x, exitflag] = solve_pixel(I_q, S_q, x0, solver)
% Solve the EON least-squares problem of one pixel from the starting point x0.
pars = struct('I', I_q, 'S', S_q, 'V', solver.v);
objective = @(x) eon_objective(x, pars);
try
    [x, ~, exitflag] = fmincon(objective, x0, [], [], [], [], solver.lb, solver.ub, ...
                               @unit_normal_constraint, solver.options);
catch err
    fprintf('  fmincon failed (%s): starting point kept\n', err.message);
    x = x0;
    exitflag = -3;
end
end

function map = to_map(values, inside, H, W)
% Place the values of the pixels of the mask in an H x W map, NaN elsewhere.
map = nan(H, W);
map(inside) = values;
end
