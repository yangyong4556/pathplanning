function collision_cost = collision_threat_cost(path, city_map, obstacle_mask, D)
% 计算无人机在三维城市环境中的碰撞威胁成本
% 输入:
%   path - n×3矩阵，航迹节点坐标 [x,y,z]
%   city_map - 120×120地形高度矩阵
%   obstacle_mask - 120×120逻辑矩阵，true表示障碍物
%   D - 安全飞行阈值
% 输出:
%   collision_cost - 总碰撞成本

    n = size(path, 1);
    collision_cost = 0;
    
    for i = 1:n-1
        p1 = path(i, :);
        p2 = path(i+1, :);
        
        segment_length = norm(p2 - p1);
        num_samples = max(3, ceil(segment_length));
        
        for s = 0:num_samples
            t = s / num_samples;
            sample_point = p1 + t * (p2 - p1);
            
            x_idx = round(sample_point(1));
            y_idx = round(sample_point(2));
            
            if x_idx < 1 || x_idx > size(city_map, 2) || ...
               y_idx < 1 || y_idx > size(city_map, 1)
                continue;
            end
            
            if obstacle_mask(y_idx, x_idx)
                obstacle_height = city_map(y_idx, x_idx);
                drone_height = sample_point(3);
                
                if drone_height <= obstacle_height
                    % 直接碰撞，高惩罚
                    collision_cost = collision_cost + 10000;
                else
                    % 安全距离内的威胁
                    height_diff = drone_height - obstacle_height;
                    if height_diff <= D
                        collision_cost = collision_cost + (D - height_diff) * 100;
                    end
                end
            end
        end
    end
    
    % 检查路径点
    for i = 1:n
        x_idx = round(path(i, 1));
        y_idx = round(path(i, 2));
        
        if x_idx >= 1 && x_idx <= size(city_map, 2) && ...
           y_idx >= 1 && y_idx <= size(city_map, 1)
           
            if obstacle_mask(y_idx, x_idx)
                obstacle_height = city_map(y_idx, x_idx);
                drone_height = path(i, 3);
                
                if drone_height <= obstacle_height
                    collision_cost = collision_cost + 10000;
                end
            end
        end
    end
end