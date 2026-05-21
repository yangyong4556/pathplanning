function path = reconstruct_path2(optimized_pos, start_point, end_point, num_points)
    % 重构三维路径（x,y,z）
    num_mid = num_points - 2;  % 中间点数量
    mid_x = optimized_pos(1:num_mid);          % 中间点x
    mid_y = optimized_pos(num_mid+1:2*num_mid); % 中间点y
    mid_z = optimized_pos(2*num_mid+1:end);    % 中间点z
    
    path = zeros(num_points, 3);
    path(1, :) = start_point;  % 起点（含z）
    for i = 1:num_mid
        path(i+1, :) = [mid_x(i), mid_y(i), mid_z(i)];
    end
    path(end, :) = end_point;  % 终点（含z）
end
