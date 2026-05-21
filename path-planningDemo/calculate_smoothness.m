% calculate_smoothness.m
function avg_angle = calculate_smoothness(path)
    % 计算路径的平滑度（平均转角，单位为度）
    if size(path, 1) < 3
        avg_angle = 0;
        return;
    end
    
    angles = [];
    for i = 2:size(path,1)-1
        % 计算前后两个向量
        vec1 = path(i, :) - path(i-1, :);
        vec2 = path(i+1, :) - path(i, :);
        
        % 计算夹角余弦值
        cos_theta = dot(vec1, vec2) / (norm(vec1) * norm(vec2) + eps);
        
        % 限制余弦值在[-1,1]范围内，避免数值误差
        cos_theta = min(max(cos_theta, -1), 1);
        
        % 计算夹角角度（度）
        theta = acosd(cos_theta);
        angles = [angles, theta];
    end
    
    % 计算平均转角
    avg_angle = mean(angles);
end