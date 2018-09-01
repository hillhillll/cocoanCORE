function [out, o2] = brain_activations_wani(r, varargin)

% This function diplay brain activations on a inflated brain and few 
% saggital, axial slices. Cocoan style activation visualization.
%
% :Usage:
% ::
%
%    [out, o2] = brain_activations_wani(cl, varargin)
%
% :Inputs:
%
%   **r:**
%        region object/activation map
%
% :Optional Inputs:
%
%   **inflated:**
%        not recommended
%        use inflated brain. We use the 32k inflated brain surface from HCP
%        connectome workbench. (Q1-Q6_R440.R.inflated.32k_fs_LR.surf.gii and 
%        Q1-Q6_R440.L.inflated.32k_fs_LR.surf.gii)
%
%   **very_inflated (default):**
%        recommended
%        use freesurfer inflated brain with Thomas Yeo group's RF_ANTs mapping
%        from MNI to Freesurfer. (https://doi.org/10.1002/hbm.24213)
%
%   **very_inflated_workbench:**
%        use very inflated brain. We also use the 32k inflated brain surface 
%        from HCP connectome workbench. 
%        (Q1-Q6_R440.R.very_inflated.32k_fs_LR.surf.gii and 
%         Q1-Q6_R440.L.very_inflated.32k_fs_LR.surf.gii)
%   
%   **depth:**
%        depth for surface map, (e.g., 'depth', 3)
%        default is 2 mm
%
%   **color:**
%        if you want to use one color for blobs, you can specify color
%        using this option.
%
%   **axial_slice_range:**
%        followed by axial slice range in a cell
%            e.g., 'axial_slice_range', {[-10 30]}
%        You can also define spacing in the same cell.
%            e.g., 'axial_slice_range', {[-10 30], 6}
%        The default range is [-20 25] with the spacing of 10.
%
%   **outline:**
%        draw outline, default linewidth: 2
%
%   **surface_only:**
%        you can use this option to draw only surface
%
%   **montage_only:**
%        you can use this option to draw only montage
%
%   **x1:**
%        you can specify the sagittal slice numbers using this option
%        e.g., 'x1', [-5 4] (default: [-5 5])
%
%   **x2:**
%        you can specify the second set of sagittal slice numbers using
%        this option. If you don't want to draw this, just leave it blank.
%        e.g., 'x2', [-41 41] or 'x2', []  (default: [-37 37]);
%
%   **y:**
%        you can specify the coronal slice numbers using this option. 
%        e.g., 'y', [-10 10] (default: []);
%
%   **z:**
%        you can specify the axial slice numbers
%        e.g., 'z', [-25 -15 -6 13 22]    
%        (default: slice range between z = -20 and 25 with spacing 10 mm)
%
%   **squeeze_x1:**
%        you can specify squeeze percentage for x1 using this. default: 40
%        e.g., 'squeeze_x1', 0 or 'squeeze_x1', 30
%
%   **squeeze_x2:**
%        you can specify squeeze percentage for x2 using this. default: 50
%
%   **squeeze_y:**
%        you can specify squeeze percentage for y using this. default: 30
%
%   **squeeze_z:**
%        you can specify squeeze percentage for z using this. default: 20
%
%   **pruned:**
%        if you have pruned version of map, you can use this option. 
%        currently only works with (e.g., -3, -2, -1, 1, 2, 3)
%
%   **cmaprange:**
%        you can use this option to specify cmaprange. (see help of
%        addblob.m to see more details about cmaprange)
%
%   **o2:**
%        if you want to reuse montages underlay that are already exist, you
%        can simply provide o2 (fmridisplay object) as an input. It
%        automatically check whether there is an input that is fmridisplay
%        object, and reuse those montage. 

global surface_style color depth poscm negcm do_color do_all all_style

surface_style = 'veryinflated';
do_color = false;
depth = 2;
do_all = false;
do_montage = true;
do_surface = true;
do_medial_surface = false;

for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            % functional commands
            case {'inflated'}
                surface_style = 'inflated';
            case {'very_inflated'}
                % this is a default
                % surface_style = 'veryinflated';
            case {'very_inflated_workbench'}
                surface_style = 'veryinflated_wb';
            case {'color'}
                do_color = true;
                color = varargin{i+1};
            case {'depth'}
                depth = varargin{i+1};
            case {'surface_only'}
                do_montage = false;
            case {'surface_all'}
                do_medial_surface = true;
            case {'montage_only'}
                do_surface = false;
            case {'all'}
                do_all = true;
                all_style = 'v1';
                disp('***************************************************************************************************************');
                disp('You selected to ''all'' option. It will draw four sagittal slices and eight axial slices with two surface maps.');
                disp('If you want to specify x and z for sagittal and axial slices, you can use ''all_xyz'' option.');
                disp('E.g., ''all_xyz'', [-5 2 -35 35 -30:12:60], first four will be used as x''s and the eight numbers after that');
                disp('      will be used as z. More than 12 numbers will be ignored.');
                disp('***************************************************************************************************************');
            case {'all2'}
                do_all = true;
                all_style = 'v2';     
                disp('***************************************************************************************************************');
                disp('You selected to ''all2'' option. It will draw four sagittal slices and six axial slices with two surface maps.');
                disp('If you want to specify x and z for sagittal and axial slices, you can use ''all2_xyz'' option.');
                disp('E.g., ''all2_xyz'', [-5 2 -35 35 -30:12:60], first four will be used as x''s and the six numbers after that');
                disp('      will be used as z. More than 10 numbers will be ignored.');
                disp('***************************************************************************************************************');
        end
    end
end

out = [];
o2 = [];
s = get(0,'ScreenSize');

%% RIGHT

poscm = colormap_tor([0.96 0.41 0], [1 1 0]);  % warm
negcm = colormap_tor([.23 1 1], [0.11 0.46 1]);  % cools

if do_surface && ~do_all    
    
    set(gcf, 'position', [1 s(4)/1.5 s(3)/3 s(4)/2]); % figure size
    
    if do_medial_surface
        axes_positions = {[0.02 0.5 .46 .5], [0.52 0.5 .46 .5], [0.02 0.1 .46 .5], [0.52 0.1 .46 .5]};
    else
        axes_positions = {[0.02 0 .46 1], [0.52 0 .46 1]};
    end
    
    axes('Position', axes_positions{1});
    out = draw_surface(r, out, 'left');
    surface_light(gca);
    view(-90, 0);
    
    axes('Position', axes_positions{2});
    out = draw_surface(r, out, 'right');
    surface_light(gca);
    view(90, 0);
    
    if do_medial_surface
        axes('Position', axes_positions{3});
        out = draw_surface(r, out, 'left');
        camlight(-90,-20); axis vis3d;
        view(90, 0);
        
        axes('Position', axes_positions{4});
        out = draw_surface(r, out, 'right');
        camlight(-90,-20); axis vis3d;
        view(-90, 0);
    end
    
elseif do_all
    
    set(gcf, 'position', [0 s(4)/3*2 s(3) s(4)/3]);
    
    switch all_style
        
        case 'v1'
            axes_positions = {[0.87 0 .1 1], [0.01 0 .1 1]};
        case 'v2'
            axes_positions = {[0.85 0 .13 1], [0.02 0 .13 1]};
    end
    
    axes('Position', axes_positions{1});
    out = draw_surface(r, out, 'right');
    surface_light(gca);
    view(90, 0);
    
    axes('Position', axes_positions{2});
    out = draw_surface(r, out, 'left');
    surface_light(gca);
    view(-90, 0);
    
end

%% Montage: canlab visualization

% disply overlay
if do_montage
    o2 = brain_montage(r, varargin);
end

end

function o2 = brain_montage(r, vars)

global color do_color

% default

dooutline = false;
do_pruned = false;
reuse_o2 = false;
do_cmaprange = false;

% parsing varargin

for i = 1:length(vars)
    if ischar(vars{i})
        switch vars{i}
            % functional commands
            case {'outline'}
                dooutline = true;
            case {'pruned'}
                do_pruned = true;
            case {'cmaprange'}
                do_cmaprange = true;
                cmaprange = vars{i+1};
        end
    else
        if isa(vars{i}, 'fmridisplay')
            reuse_o2 = true;
            o2 = vars{i};
        end 
    end
end

if ~reuse_o2 
    o2 = draw_montage(vars);
end

%%
o2 = removeblobs(o2);

if ~do_color
    if ~do_pruned && ~do_cmaprange
        o2 = addblobs(o2, r, 'splitcolor', {[.23 1 1], [0.17 0.61 1], [0.99 0.46 0], [1 1 0]}); % A&B
    elseif do_pruned
        o2 = addblobs(o2, r, 'splitcolor', {[.23 1 1], [0.17 0.61 1], [0.99 0.46 0], [1 1 0]}, 'cmaprange', [-2.8 -1.2 1.2 2.8]);
    elseif do_cmaprange
        o2 = addblobs(o2, r, 'splitcolor', {[.23 1 1], [0.17 0.61 1], [0.99 0.46 0], [1 1 0]}, 'cmaprange', cmaprange);
    end
else
    o2 = addblobs(o2, r, 'color', color); % A&B
end

if dooutline, o2 = addblobs(o2, r, 'outline', 'linewidth', 2, 'outline_color', [0 0 0]); end

end

function surface_light(gca)

out.h = get(gca, 'children');
set(out.h(2), 'BackFaceLighting', 'lit')
camlight(-90,-20);
axis vis3d;

end

function out = draw_surface(r, out, hemisphere)

global surface_style color depth poscm negcm do_color

switch hemisphere
    
    case 'left'
        
        if ~do_color
            switch surface_style
                case 'inflated'
                    out.h_surf_L = cluster_surf(r ,which('surf_workbench_inflated_32k_Left.mat'), depth, 'heatmap', 'colormaps', poscm, negcm);
                case 'veryinflated'
                    out.h_surf_L = cluster_surf(r, 'fsavg_left', depth, 'heatmap', 'colormaps', poscm, negcm);
                case 'veryinflated_wb'
                    out.h_surf_L = cluster_surf(r ,which('surf_workbench_very_inflated_32k_Left.mat'), depth, 'heatmap', 'colormaps', poscm, negcm);
            end
        else
            switch surface_style
                case 'inflated'
                    out.h_surf_L = cluster_surf(r ,which('surf_workbench_inflated_32k_Left.mat'), depth, {color});
                case 'veryinflated'
                    out.h_surf_L = cluster_surf(r, 'fsavg_left', depth, {color});
                case 'veryinflated_wb'
                    out.h_surf_L = cluster_surf(r ,which('surf_workbench_very_inflated_32k_Left.mat'), depth, {color});
            end
        end
    case 'right'
        
        if ~do_color
            switch surface_style
                case 'inflated'
                    out.h_surf_R = cluster_surf(r ,which('surf_workbench_inflated_32k_Right.mat'), depth, 'heatmap', 'colormaps', poscm, negcm);
                case 'veryinflated'
                    out.h_surf_R = cluster_surf(r, 'fsavg_right', depth, 'heatmap', 'colormaps', poscm, negcm);
                case 'veryinflated_wb'
                    out.h_surf_R = cluster_surf(r ,which('surf_workbench_very_inflated_32k_Right.mat'), depth, 'heatmap', 'colormaps', poscm, negcm);
            end
        else
            switch surface_style
                case 'inflated'
                    out.h_surf_R = cluster_surf(r ,which('surf_workbench_inflated_32k_Right.mat'), depth, {color});
                case 'veryinflated'
                    out.h_surf_R = cluster_surf(r, 'fsavg_right', depth, {color});
                case 'veryinflated_wb'
                    out.h_surf_R = cluster_surf(r ,which('surf_workbench_very_inflated_32k_Right.mat'), depth, {color});
            end
        end
end
        
end

function o2 = draw_montage(vars)

global do_all all_style

% default
axial_slice_range = [-20 25];
spacing = 10;
do_slice_range = true;
x1 = [-5 5]';
x2 = [-37 37]';
y = [];
do_label = false;

squeeze_x1 = 40;
squeeze_x2 = 50;
squeeze_y = 30;
squeeze_z = 20;
fontsize = 15;

for i = 1:length(vars)
    if ischar(vars{i})
        switch vars{i}
            % functional commands
            case {'axial_slice_range'}
                axial_slice_range = vars{i+1}{1};
                if numel(vars{i+1}) == 2
                    spacing = vars{i+2}{2};
                end
            case {'x1'}
                x1 = vars{i+1};
                if size(x1,1) == 1, x1 = x1'; end
            case {'x2'}
                x2 = vars{i+1};
                if size(x2,1) == 1, x2 = x2'; end
            case {'y'}
                y = vars{i+1};
                if size(y,1) == 1, y = y'; end
            case {'z'}
                do_slice_range = false;
                z = vars{i+1};
                if size(z,1) == 1, z = z'; end
            case {'squeeze_x1'}
                squeeze_x1 = vars{i+1};
            case {'squeeze_x2'}
                squeeze_x2 = vars{i+1};
            case {'squeeze_y'}
                squeeze_y = vars{i+1};
            case {'squeeze_z'} 
                squeeze_z = vars{i+1};
            case {'label', 'labels'}
                do_label = true;
            case {'fontsize'}
                fontsize = vars{i+1};
        end
    end
end

o2 = fmridisplay;

if ~do_all
    
    xyz1 = x1;
    xyz2 = x2;
    xyz3 = y;
    
    xyz1(:, 2:3) = 0;
    xyz2(:, 2:3) = 0;
    
    xyz3(:, 2:3) = 0;
    xyz3 = xyz3(:,[2 1 3]);
    
    o2 = montage(o2, 'saggital', 'wh_slice', xyz1, 'onerow', 'brighten', .5);
    
    if ~isempty(x2)
        o2 = montage(o2, 'saggital', 'wh_slice', xyz2, 'onerow', 'brighten', .5);
    end
    
    if ~isempty(y)
        o2 = montage(o2, 'coronal', 'wh_slice', xyz3, 'onerow', 'brighten', .5);
    end
    
    if do_slice_range
        o2 = montage(o2, 'axial', 'slice_range', axial_slice_range, 'onerow', 'spacing', spacing, 'brighten', .5);
    else
        xyz4 = z;
        xyz4(:, 2:3) = 0;
        xyz4 = xyz4(:,[2 3 1]);
        
        o2 = montage(o2, 'axial', 'wh_slice', xyz4, 'onerow', 'brighten', .5);
    end
    
    k = 1;
    squeeze_axes_percent(o2.montage{k}.axis_handles, squeeze_x1);
    
    if ~isempty(x2)
        k = k + 1;
        squeeze_axes_percent(o2.montage{k}.axis_handles, squeeze_x2);
    end
    
    if ~isempty(y)
        k = k + 1;
        squeeze_axes_percent(o2.montage{k}.axis_handles, squeeze_y);
    end
    
    k = k + 1;
    squeeze_axes_percent(o2.montage{k}.axis_handles, squeeze_z);
    
else
    % predefined styles
    switch all_style
        case 'v1'

            s_first = [0.12 0.26];
            s_interval = [0.05 0.05];
            
            a_initial = 0.4;
            a_interval = 0.055;
            
            axes_positions = {[s_first(1) 0 .1 1], [s_first(1)+s_interval(1) 0 .1 1], ... % sagittal 1
                [s_first(2) 0 .1 1], [s_first(2)+s_interval(2) 0 .1 1], ... % sagittal 2
                [a_initial 0 .075 1], [a_initial+a_interval 0 .075 1], [a_initial+a_interval*2 0 .075 1], [a_initial+a_interval*3 0 .075 1], ... % axial
                [a_initial+a_interval*4 0 .075 1], [a_initial+a_interval*5 0 .075 1],  [a_initial+a_interval*6 0 .075 1], [a_initial+a_interval*7 0 .075 1]};
            
            xyz = [-2 2 -37 37 ... % sagittal
                -20 -10 0 10 20 30 40 50]; % axial
            if any(strcmp(vars, 'all_xyz')), xyz = vars(find(strcmp(vars, 'all_xyz'))+1); end
            
            texts{1} = [38 -50;10 -50;35, -60;15, -60;-30, -115;-15, -115;-5, -115;-10, -115;-10, -115;-10, -115;-10, -115;-10, -115];
            for i = 1:numel(xyz)
                if i == 1 || i == 3
                    texts{2}{i} = ['x = ' num2str(xyz(i))];
                elseif i == 5
                    texts{2}{i} = ['z = ' num2str(xyz(i))];
                else
                    texts{2}{i} = num2str(xyz(i));
                end
            end
            
            for i = 1:numel(axes_positions)
                axh = axes('Position', axes_positions{i});
                if i < 5
                    o2 = montage(o2, 'saggital', 'wh_slice', [xyz(i) 0 0], 'onerow', 'brighten', .5, 'existing_axes', axh);
                else
                    o2 = montage(o2, 'axial', 'wh_slice', [0 0 xyz(i)], 'onerow', 'brighten', .5, 'existing_axes', axh);
                end
                if do_label, text(texts{1}(i,1), texts{1}(i,2), texts{2}{i}, 'fontsize', fontsize); end
            end
            
        case 'v2'
            
            s_first = [0.15 0.32];
            s_interval = [0.07 0.05];
            
            a_initial = 0.46;
            a_interval = 0.06;
            
            axes_positions = {[s_first(1) 0 .12 1], [s_first(1)+s_interval(1) 0 .12 1], ... % sagittal 1
                [s_first(2) 0 .1 1], [s_first(2)+s_interval(2) 0 .1 1], ... % sagittal 2
                [a_initial 0 .08 1], [a_initial+a_interval 0 .08 1], [a_initial+a_interval*2 0 .08 1], ... % axial
                [a_initial+a_interval*3 0 .08 1], [a_initial+a_interval*4 0 .08 1], [a_initial+a_interval*5 0 .08 1]};
            
            
            xyz = [-2 2 -37 37 ... % sagittal
                -20 -10 0 10 20 30]; % axial
            
            if any(strcmp(vars, 'all2_xyz')), xyz = vars(find(strcmp(vars, 'all2_xyz'))+1); end
            
            texts{1} = [35 -50;25, -50;35, -60;15, -60;-25, -115;-15, -115;-2, -115;-7, -115;-7, -115;-7, -115];
            for i = 1:numel(xyz)
                if i == 1 || i == 3
                    texts{2}{i} = ['x = ' num2str(xyz(i))];
                elseif i == 5
                    texts{2}{i} = ['z = ' num2str(xyz(i))];
                else
                    texts{2}{i} = num2str(xyz(i));
                end
            end
            
            
            for i = 1:numel(axes_positions)
                axh = axes('Position', axes_positions{i});
                if i < 5
                    o2 = montage(o2, 'saggital', 'wh_slice', [xyz(i) 0 0], 'onerow', 'brighten', .5, 'existing_axes', axh);
                else
                    o2 = montage(o2, 'axial', 'wh_slice', [0 0 xyz(i)], 'onerow', 'brighten', .5, 'existing_axes', axh);
                end
                if do_label, text(texts{1}(i,1), texts{1}(i,2), texts{2}{i}, 'fontsize', fontsize); end
            end
            
    end
end
end