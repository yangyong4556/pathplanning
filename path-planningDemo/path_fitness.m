function [total_cost, len_cost, obs_cost, alt_cost, smooth_cost] = path_fitness(x, start_point, end_point, num_points, city_map, obstacle_mask, D, smooth_weight, h_min, h_max, h_ideal)
    % 重构路径
    path = reconstruct_path2(x, start_point, end_point, num_points);
    
    % 1. 路径长度成本
    len_cost = 0;
    for i = 1:size(path,1)-1
        dx = path(i+1,1) - path(i,1);
        dy = path(i+1,2) - path(i,2);
        dz = path(i+1,3) - path(i,3);
        len_cost = len_cost + sqrt(dx^2 + dy^2 + dz^2);
    end
    
    % 2. 碰撞成本
    obs_cost = collision_threat_cost(path, city_map, obstacle_mask, D);
    
    % 3. 高度成本
    alt_cost = flight_height_cost(path, h_min, h_max, h_ideal);
    
    % 4. 平滑度成本
    smooth_cost = check_smoothness_constraint(path, smooth_weight);
    
    % 总成本
    total_cost = len_cost + obs_cost + alt_cost + smooth_cost;
end