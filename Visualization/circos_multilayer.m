function circos_multilayer(A, varargin)

% This function draws circos plot with multiple layers.
%
%
% :Usage:
% ::
%     circos_multilayer(A, varargin)
%
%
% :Input:
% ::
%   - A                  Adjacency matrix
%
%
% :Optional Input:
%
%   - group              group assignment of nodes. ex) [1,1,1,2,2,2,3,4], ...
%   - group_color        RGB color values for each group. [groups X 3]
%   - rotate             rotate circos plot clockwise. (degree)
%   - add_layer          add additional layers, specified by following key-value pairs.
%                        (e.g., 'add_layer', {'layer', deg_cent, 'color', deg_cent_cols})
%                        the values followed by 'layer' will be presented
%                        with the colormap values following 'color'.
%                        for example, if you want to add 'degree centrality'
%                        layer in the circos plot and define color with 5-level,
%                        put degree centrality value in 'deg_cent'
%                        and 5 RGB values [5 X 3] in 'deg_cent_cols'.
%                        (Note: all values for layer should be normalized,
%                        ranging from 0 to 1)
%   - region_names       labels for regions (or nodes)
%   - region_names_size  size of labels for regions
%   - laterality         laterality index for circos plot (usually for cortex)
%                        -1: Left, 1: Right, 0: No laterality
%   - radiological       laterality display in radiological convention. (default: neurological)
%   - sep_pos_neg        separate positive and negative connections.
%   - alpha_fun          user-defined function for setting alpha value of
%                        connections corresponding to connectivity values.
%                        (default: @(x) (((abs(x) - min(abs(x))) ./ (max(abs(x)) - min(abs(x))))).^4.5;)
%   - width_fun          user-defined function for setting alpha value of
%                        connections corresponding to connectivity values.
%                        (default: @(x) (abs(x) - min(abs(x))) ./ (max(abs(x)) - min(abs(x))) * 2.25 + 0.25;)
%
%
% :Output:
% ::   
%
%
% :Example:
% ::
%   % generating undirected and weighted adjacency matrix
%   A = randn(100,100); % to make realistic network, use other fx.
%   A = A + A';
%   A = A ./ max(abs(A(:)));
%   A(1:length(A)+1:end) = 0;
%   % defining groups of nodes
%   A_group = randi(5,100,1);
%   A_group_cols = [0    0.4470    0.7410
%       0.8500    0.3250    0.0980
%       0.9290    0.6940    0.1250
%       0.4940    0.1840    0.5560
%       0.4660    0.6740    0.1880];
%   % add 'weighted degree centrality' layer
%   A_pos_deg_cent = sum(A .* double(A>0), 2) ./ (size(A, 1) - 1);
%   A_pos_deg_cent_cols = cell2mat(arrayfun(@(x, y) linspace(x, y, 10), ...
%       [179,0,0], [254,240,17], 'UniformOutput', false)')' ./ 255;
%   A_neg_deg_cent = -sum(A .* double(A<0), 2) ./ (size(A, 1) - 1);
%   A_neg_deg_cent_cols = cell2mat(arrayfun(@(x, y) linspace(x, y, 10), ...
%       [8,104,172], [240,290,232], 'UniformOutput', false)')' ./ 255;
%   % region names
%   A_names = cellstr(strcat(repmat('node', 100, 1), num2str((1:100)')));
%   % laterality
%   A_lat = [repmat([-1; 1], 45, 1); zeros(10,1)];
%   % draw circos plot
%   circos_multilayer(A, 'group', A_group, 'group_color', A_group_cols, ...
%       'add_layer', {'layer', A_pos_deg_cent, 'color', A_pos_deg_cent_cols, ...
%       'layer', A_neg_deg_cent, 'color', A_neg_deg_cent_cols}, ...
%       'region_names', A_names, 'laterality', A_lat, 'sep_pos_neg');
%   
% ..
%     Author and copyright information:
%
%     Copyright (C) Jan 2019  Choong-Wan Woo & Jae-Joong Lee
%
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
%
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
%
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.
% ..

rotate_angle = 0;
add_layer = {};
do_region_label = false;
pos_edge_color = [255,0,0]./255;
neg_edge_color = [10,150,255]./255;
region_names_size = 6;
laterality = false;
radiological = false;
sep_pos_neg = false;
dot_node = 10;
dot_interval = 3;
patch_size_coef = 0.05;
layer = {};
alpha_fun = @(x) (((abs(x) - min(abs(x))) ./ (max(abs(x)) - min(abs(x))))).^4.5;
width_fun = @(x) (abs(x) - min(abs(x))) ./ (max(abs(x)) - min(abs(x))) * 2.25 + 0.25;
% alpha_fun = @(x) (x - min(x)) ./ (max(x) - min(x)) * 0.9 + 0.1;
% width_fun = @(x) (abs(x) - min(abs(x))) ./ (max(abs(x)) - min(abs(x))) * 2 + 1;

default_col_names = { ...
    'degree', ...
    'lesion', ...
    'clcoef', ...
    };
default_col = { ...
    [255,255,178
    254,204,92
    253,141,60
    240,59,32
    189,0,38]./255, ...
    repmat(linspace(1, 0, 10)', 1, 3), ...
    [237,248,251
    178,226,226
    102,194,164
    44,162,95
    0,109,44]./255, ...
    };

for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            case {'group'}
                group = varargin{i+1};
            case {'group_color'}
                gcols = varargin{i+1};
            case {'rotate'}
                rotate_angle = varargin{i+1};
            case {'add_layer'}
                add_layer = varargin{i+1};
            case {'region_names'}
                do_region_label = true;
                region_names = varargin{i+1};
            case {'region_names_size'}
                region_names_size = varargin{i+1};
            case {'laterality'}
                laterality = true;
                lat_index = varargin{i+1};
            case {'radiological'}
                radiological = true;
            case {'sep_pos_neg'}
                sep_pos_neg = true;
            case {'alpha_fun'}
                alpha_fun = varargin{i+1};
            case {'width_fun'}
                width_fun = varargin{i+1};
        end
    end
end

j = 0;
for i = 1:length(add_layer)
    if ischar(add_layer{i})
        switch add_layer{i}
            case {'layer'}
                j = j + 1;
                layer{j} = add_layer{i+1};
                if max(layer{j}) > 1 || min(layer{j}) < 0
                    error('Values of each layer should be between 0 and 1.');
                end
            case {'color'}
                if ~ischar(add_layer{i+1})
                    layer_color{j} = add_layer{i+1};
                elseif ischar(add_layer{i+1})
                    layer_color{j} = default_col{contains(default_col_names, add_layer{i+1})};
                end
        end
    end
end




%% Calculating theta

if laterality
    
    before_N_group = max(group);
    group(lat_index == 0) = before_N_group + 1;
    if ~radiological % Right is Right, Left is Left
        group(lat_index == -1) = before_N_group*2 + 2 - group(lat_index == -1);
    elseif radiological % Right is Left, Left is Right
        group(lat_index == 1) = before_N_group*2 + 2 - group(lat_index == 1);
    end
    gcols = [gcols; gcols(end,:); flipud(gcols)];

end

N_node = size(A, 1);
N_group = numel(unique(group));
unit_theta = (2*pi) / (N_node * dot_node + N_group * dot_interval);

[group_val, group_idx] = sort(group, 'ascend');
if laterality
    for i = (before_N_group+1):before_N_group*2+1
        wh_mirror = group_val == i;
        group_val(wh_mirror) = flipud(group_val(wh_mirror));
        group_idx(wh_mirror) = flipud(group_idx(wh_mirror));
    end
end
A = A(group_idx, group_idx);

for i = 1:numel(layer)
    layer{i} = layer{i}(group_idx);
end
if exist('region_names', 'var')
    region_names = region_names(group_idx);
end
    
wh_interval = find(diff([group_val]) == 1); % find where group index differs = find where interval is located

j = 0:(dot_node-1);
% j = [0:(dot_node-1)] + dot_interval;
for i = 1:N_node
    
    range_theta{i} = -(unit_theta * j) + pi/2 + deg2rad(rotate_angle);
    j = j + dot_node;
    if ismember(i, wh_interval)
        j = j + dot_interval; % interval
    end
    
end


%% Draw circular sectors

for i = 1:N_node
    
    ref_line = [cos(range_theta{i})', sin(range_theta{i})'];
    
    %% Layer
    for j = 1:length(layer)
        
        bottom_line = ref_line .* (1 + (j-1)*patch_size_coef);
        top_line = ref_line .* (1 + j*patch_size_coef);
        if mod(j, 2) == 1
            top_line = flipud(top_line);
        elseif mod(j, 2) == 0
            bottom_line = flipud(bottom_line);
        end
        patch_vec = [bottom_line; top_line];
        patch_color = layer_color{j}(sum(layer{j}(i) >= linspace(0, 1+eps, size(layer_color{j},1) + 1)), :);
        patch([patch_vec(:,1)], [patch_vec(:,2)], patch_color, 'linewidth', 0.5, 'edgecolor', [.5 .5 .5], 'edgealpha', .5);
        
    end
    
    %% Group color
    if isempty(j); j = 1;
    elseif ~isempty(j); j = j + 1;
    end
    bottom_line = ref_line .* (1 + (j-1)*patch_size_coef);
    top_line = ref_line .* (1 + j*patch_size_coef);
    if mod(j, 2) == 1
        top_line = flipud(top_line);
    elseif mod(j, 2) == 0
        bottom_line = flipud(bottom_line);
    end
    patch_vec = [bottom_line; top_line];
    patch_color = gcols(group_val(i),:);
    patch([patch_vec(:,1)], [patch_vec(:,2)], patch_color, 'linewidth', 0.5, 'edgecolor', [.5 .5 .5], 'edgealpha', .5);
    
    %% ROI text
    if do_region_label
        text_line = mean(ref_line) .* (1 + j*patch_size_coef);
        text_rotate = rad2deg(mean(range_theta{i}));
        if text_rotate < -90
            text_rotate = text_rotate + 180;
            h = text(text_line(1), text_line(2), [region_names{i} '- '], 'HorizontalAlignment', 'Right', 'Fontsize', region_names_size, 'Rotation', text_rotate);
        else
            h = text(text_line(1), text_line(2), [' -' region_names{i}], 'HorizontalAlignment', 'Left', 'Fontsize', region_names_size, 'Rotation', text_rotate);
        end
    end
    
end


%% Draw connections

[row,col,w] = find(triu(A,1));

alpha_w = alpha_fun(w);
width_w = width_fun(w);

for i = 1:numel(w)
    
    u = [cos(mean(range_theta{row(i)})), sin(mean(range_theta{row(i)}))];
    v = [cos(mean(range_theta{col(i)})), sin(mean(range_theta{col(i)}))];
    
    x0 = -(u(2)-v(2))/(u(1)*v(2)-u(2)*v(1));
    y0 =  (u(1)-v(1))/(u(1)*v(2)-u(2)*v(1));
    r  = sqrt(x0^2 + y0^2 - 1);
    thetaLim(1) = atan2(u(2)-y0,u(1)-x0);
    thetaLim(2) = atan2(v(2)-y0,v(1)-x0);
    
    if u(1) >= 0 && v(1) >= 0
        % ensure the arc is within the unit disk
        theta = [linspace(max(thetaLim),pi,50),...
            linspace(-pi,min(thetaLim),50)].';
    else
        theta = linspace(thetaLim(1),thetaLim(2)).';
    end
    
    if ~sep_pos_neg
        edge_color = pos_edge_color;
        line(...
            r*cos(theta)+x0,...
            r*sin(theta)+y0,...
            'LineWidth', width_w(i),...
            'PickableParts','none', 'color', [edge_color alpha_w(i)]);
    elseif sep_pos_neg
        if w(i) >= 0; edge_color = pos_edge_color;
        elseif w(i) < 0; edge_color = neg_edge_color;
        end
        line(...
            r*cos(theta)+x0,...
            r*sin(theta)+y0,...
            'LineWidth', width_w(i),...
            'PickableParts','none', 'color', [edge_color alpha_w(i)]);
    end

end

axis off;
set(gcf, 'color', 'w');
end