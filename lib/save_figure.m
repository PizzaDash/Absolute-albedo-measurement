function save_figure(fig, out_dir, base_name, formats)
%SAVE_FIGURE  Save a figure in several formats.
%   SAVE_FIGURE(fig, out_dir, base_name) writes out_dir/base_name.png and
%   out_dir/base_name.fig. SAVE_FIGURE(fig, out_dir, base_name, formats)
%   writes only the formats listed (e.g. {'fig'}).

if nargin < 4
    formats = {'png', 'fig'};
end
for k = 1:numel(formats)
    file = fullfile(out_dir, [base_name '.' formats{k}]);
    switch formats{k}
        case 'fig'
            savefig(fig, file);
        case 'png'
            exportgraphics(fig, file, 'Resolution', 200);
        otherwise
            saveas(fig, file);
    end
end
end
