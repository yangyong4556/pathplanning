% 路径长度成本计算
function total_dist = calculate_path_distance(path)
    % 计算三维路径的总长度
    total_dist = 0;
    for i = 1:size(path,1)-1
        dx = path(i+1,1) - path(i,1);
        dy = path(i+1,2) - path(i,2);
        dz = path(i+1,3) - path(i,3);
        total_dist = total_dist + sqrt(dx^2 + dy^2 + dz^2);
    end
end