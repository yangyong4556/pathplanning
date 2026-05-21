% 平滑性约束检查函数
function [smoothness_penalty] = check_smoothness_constraint(path, weight)
    % 基于相邻线段夹角计算平滑性惩罚
    smoothness_penalty = 0;
    if size(path, 1) < 3  % 少于3个点无转角
        return;
    end
    
    for i = 2:size(path, 1)-1
        vec1 = path(i, :) - path(i-1, :);  % 前一线段向量
        vec2 = path(i+1, :) - path(i, :);  % 后一线段向量
        vec1_norm = vec1 / norm(vec1 + eps);  % 归一化（避免除零）
        vec2_norm = vec2 / norm(vec2 + eps);
        cos_theta = dot(vec1_norm, vec2_norm);  % 夹角余弦值（越接近-1，转角越急）
        smoothness_penalty = smoothness_penalty + weight * (1 - cos_theta);  % 转角越急惩罚越大
    end
end