function height_cost = flight_height_cost(path, h_min, h_max, h_ideal)
% 计算无人机飞行高度成本
% 输入：
%   path - n×3矩阵，路径点坐标
%   h_min - 最低允许高度
%   h_max - 最高允许高度
%   h_ideal - 理想飞行高度
% 输出：height_cost - 飞行高度成本

    n = size(path, 1);
    height_cost = 0;
    
    for i = 1:n
        current_height = path(i, 3);
        
        % 检查高度约束
        if current_height < h_min
            % 低于最低高度，高惩罚
            height_cost = height_cost + 100 * (h_min - current_height);
        elseif current_height > h_max
            % 高于最高高度，高惩罚
            height_cost = height_cost + 100 * (current_height - h_max);
        else
            % 在允许范围内，但与理想高度的偏差
            height_deviation = abs(current_height - h_ideal);
            height_cost = height_cost + height_deviation;
        end
    end
end