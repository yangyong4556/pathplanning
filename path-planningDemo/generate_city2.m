function [city_map, x_grid, y_grid, obstacle_mask, start_point, end_point] = generate_city2()
% GENERATE_CITY 生成城市地形模型
%
% 输出参数：
%   city_map      : 100x100的地形高度矩阵（单位：米）
%   x_grid        : x坐标网格
%   y_grid        : y坐标网格  
%   obstacle_mask : 120x120的逻辑矩阵，true表示障碍物
%   start_point   : 起点坐标 [x, y, z]
%   end_point     : 终点坐标 [x, y, z]
%
% 使用示例：
%   [city_map, x_grid, y_grid, obstacle_mask, start, goal] = generate_city();

    % 调整地图尺寸（100x100网格）
    city_size = [120, 120];
    x_grid = 1:city_size(2);
    y_grid = 1:city_size(1);
    [X, Y] = meshgrid(x_grid, y_grid);
    
    % 初始化地图（0表示平坦路面，值表示高度）
    city_map = zeros(city_size);
    obstacle_mask = false(city_size);  % 障碍物掩码（true表示障碍物）
    
    % 1. 生成建筑物（长方体形状）
    buildings = [
        % x0, y0, 宽度, 高度, 建筑高度, 类型(1-商业,2-住宅,3-工业)   
        30, 25, 12, 14, 18, 1;
        80, 40, 18, 9, 12, 2;
        45, 80, 10, 20, 22, 1;
        90, 70, 15, 15, 9, 2;
        15, 50, 11, 11, 28, 3;
        60, 30, 16, 12, 14, 2;
        100, 45, 10, 13, 20, 1;
        20, 90, 14, 16, 30, 3;
        70, 100, 13, 10, 25, 3;
    ];
       
    % 绘制建筑物 - 长方体形状
    for i = 1:size(buildings, 1)
        x0 = buildings(i, 1);
        y0 = buildings(i, 2);
        w = buildings(i, 3);
        h = buildings(i, 4);
        b_height = buildings(i, 5);
        
        % 建筑边界
        x1 = min(x0 + w - 1, city_size(2));
        y1 = min(y0 + h - 1, city_size(1));
        
        % 创建长方体建筑 - 统一高度
        city_map(y0:y1, x0:x1) = b_height;
        obstacle_mask(y0:y1, x0:x1) = true;
    end
    
    % 2. 树木 - 圆锥形状（只避开建筑物，不避开道路）
    num_trees = 40;
    for i = 1:num_trees
        % 随机位置（避开建筑物）
        while true
            x = randi([10, city_size(2)-10]);
            y = randi([10, city_size(1)-10]);
            if ~obstacle_mask(y, x)
                break;
            end
        end
        
        % 创建圆锥形树木
        size_tree = randi([1, 3]);
        height_tree = 4 + 4*rand(1);
        
        % 树木半径
        tree_radius = size_tree;
        [tree_X, tree_Y] = meshgrid(-tree_radius:tree_radius, -tree_radius:tree_radius);
        distance = sqrt(tree_X.^2 + tree_Y.^2);
        
        % 创建圆锥形状
        tree_mask = distance <= tree_radius;
        tree_height_map = height_tree * (1 - distance/tree_radius);
        tree_height_map(~tree_mask) = 0;
        
        % 将树木添加到地图中
        y_range = max(1,y-tree_radius):min(city_size(1),y+tree_radius);
        x_range = max(1,x-tree_radius):min(city_size(2),x+tree_radius);
        
        tree_y_range = (y_range - y) + tree_radius + 1;
        tree_x_range = (x_range - x) + tree_radius + 1;
        
        valid_tree_heights = tree_height_map(tree_y_range, tree_x_range);
        city_map(y_range, x_range) = max(city_map(y_range, x_range), valid_tree_heights);
        obstacle_mask(y_range, x_range) = true;
    end
    
    % 3. 添加轻微的自然地形起伏
    [terrain_X, terrain_Y] = meshgrid(linspace(0, 3, city_size(2)), linspace(0, 3, city_size(1)));
    terrain_noise = zeros(city_size);
    for octave = 1:2
        scale = 2^(octave-1);
        terrain_noise = terrain_noise + 0.3/scale * sin(scale * terrain_X) .* sin(scale * terrain_Y);
    end
    
    % 只对非建筑、非树木的平坦区域添加轻微起伏
    terrain_mask = ~obstacle_mask & city_map == 0;
    city_map(terrain_mask) = city_map(terrain_mask) + 1 * terrain_noise(terrain_mask);
    
    % 4. 起点和终点位置
    start_point = [10, 110, 10];
    end_point = [110, 10, 10];
    
    % 确保起点和终点不在障碍物上
    if obstacle_mask(round(start_point(2)), round(start_point(1)))
        start_point = [10, 110, 10];
    end
    if obstacle_mask(round(end_point(2)), round(end_point(1)))
        end_point = [110, 10, 10];
    end
end