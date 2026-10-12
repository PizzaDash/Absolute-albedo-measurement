function rgb = normals_to_rgb(normals, mask)
%NORMALS_TO_RGB  Color-coded normal map.
%   rgb = NORMALS_TO_RGB(normals, mask) converts the H x W x 3 normals of
%   the camera frame (y pointing down, normals facing the camera with a
%   negative z) into the usual normal-map colors: y and z are flipped, so
%   that y points up and z towards the viewer, and each component is mapped
%   from [-1, 1] to [0, 1]. Pixels outside the mask are black.

n = normals ./ vecnorm(normals, 2, 3);
n(:, :, 2) = -n(:, :, 2);
n(:, :, 3) = -n(:, :, 3);
rgb = (n + 1) / 2;
rgb(repmat(~mask, 1, 1, 3)) = 0;
rgb(isnan(rgb)) = 0;
end
