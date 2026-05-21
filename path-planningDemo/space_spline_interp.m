% 使用示例：
% points = [0,0,0; 1,2,1; 2,1,3; 3,3,2; 4,2,4; 5,4,3; 6,3,5];
% [curve, t] = space_spline_interp(points, 100, 'spline');
% plot3(curve(:,1), curve(:,2), curve(:,3), 'b-', 'LineWidth', 2);
function [curve_xyz, t_param] = space_spline_interp(points, num_points, method)
    % 空间点样条插值函数
    % 输入：
    %   points - N×3 矩阵，每行为一个空间点 [x, y, z]
    %   num_points - 插值点数（默认200）
    %   method - 插值方法：'spline', 'pchip', 'makima'（默认'spline'）
    % 输出：
    %   curve_xyz - 插值后的曲线点 (num_points×3)
    %   t_param - 参数化对应的t值
    
    if nargin < 3
        method = 'spline';
    end
    if nargin < 2
        num_points = 200;
    end
    
    % 提取坐标
    x = points(:,1);
    y = points(:,2);
    z = points(:,3);
    
    % 累计弦长参数化
    n = length(x);
    t = zeros(n, 1);
    for i = 2:n
        t(i) = t(i-1) + sqrt((x(i)-x(i-1))^2 + (y(i)-y(i-1))^2 + (z(i)-z(i-1))^2);
    end
    
    % 插值
    t_param = linspace(min(t), max(t), num_points);
    
    switch lower(method)
        case 'spline'
            xx = spline(t, x, t_param);
            yy = spline(t, y, t_param);
            zz = spline(t, z, t_param);
        case 'pchip'
            xx = pchip(t, x, t_param);
            yy = pchip(t, y, t_param);
            zz = pchip(t, z, t_param);
        case 'makima'
            xx = makima(t, x, t_param);
            yy = makima(t, y, t_param);
            zz = makima(t, z, t_param);
        otherwise
            error('未知方法：%s', method);
    end
    
    curve_xyz = [xx', yy', zz'];
end

