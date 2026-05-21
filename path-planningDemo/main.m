% 主程序：DBO、DBO_PSO、PSO、IDBO、ECFDBO算法在模拟城市中的路径规划对比
clear all;
clc;
rng(23);
nRuns = 1;  % 正式运行时改为30
num_algorithms = 5;

% 1. 路径参数设置
num_points = 7;
dim = 3 * (num_points - 2);
safe_distance = 5;
smooth_weight = 100;
D = 2;
h_min = 5;
h_max = 100;
h_ideal = 40;

% 2. 生成模拟城市
[city_map, ~, ~, obstacle_mask, start_point, end_point] = generate_city2();
start_point(3) = 10;
end_point(3) = 10;

% 3. 算法参数
popsize = 50;
maxIter = 500;
lb = [ones(1, num_points-2)*1, ones(1, num_points-2)*1, ones(1, num_points-2)*safe_distance];
ub = [ones(1, num_points-2)*size(city_map,2), ones(1, num_points-2)*size(city_map,1), ones(1, num_points-2)*50];

% 4. 定义适应度函数（返回总成本和各分量）
fobj = @(x) path_fitness(x, start_point, end_point, num_points, city_map, obstacle_mask, D, smooth_weight, h_min, h_max, h_ideal);

% 5. 初始化存储变量
algorithms = {'DBO', 'DBO_PSO', 'PSO', 'IDBO', 'ECFDBO'};
for i = 1:length(algorithms)
    eval(strcat([algorithms{i}, '_scores = zeros(1, nRuns);']));
    eval([algorithms{i}, '_times = zeros(1, nRuns);']);
    eval([algorithms{i}, '_distances = zeros(1, nRuns);']);
    eval([algorithms{i}, '_smoothnesses = zeros(1, nRuns);']);
    eval([algorithms{i}, '_len_cost = zeros(1, nRuns);']);
    eval([algorithms{i}, '_obs_cost = zeros(1, nRuns);']);
    eval([algorithms{i}, '_alt_cost = zeros(1, nRuns);']);
    eval([algorithms{i}, '_smooth_cost = zeros(1, nRuns);']);
end

% 6. 运行实验
for exp_idx = 1:nRuns
    fprintf('正在进行第%d次实验...\n', exp_idx);
    
    % DBO
    tic;
    [DBO_Best_score, DBO_Best_pos, ~] = DBO(popsize, maxIter, lb, ub, dim, fobj);
    DBO_times(exp_idx) = toc;
    DBO_scores(exp_idx) = DBO_Best_score;
    DBO_path = reconstruct_path2(DBO_Best_pos, start_point, end_point, num_points);
    DBO_distances(exp_idx) = calculate_path_distance(DBO_path);
    DBO_smoothnesses(exp_idx) = calculate_smoothness(DBO_path);
    [~, DBO_len_cost(exp_idx), DBO_obs_cost(exp_idx), DBO_alt_cost(exp_idx), DBO_smooth_cost(exp_idx)] = fobj(DBO_Best_pos);
    
    % DBO_PSO
    tic;
    [DBO_PSO_Best_score, DBO_PSO_Best_pos, ~] = DBOPSO(popsize, maxIter, lb, ub, dim, fobj);
    DBO_PSO_times(exp_idx) = toc;
    DBO_PSO_scores(exp_idx) = DBO_PSO_Best_score;
    DBO_PSO_path = reconstruct_path2(DBO_PSO_Best_pos, start_point, end_point, num_points);
    DBO_PSO_distances(exp_idx) = calculate_path_distance(DBO_PSO_path);
    DBO_PSO_smoothnesses(exp_idx) = calculate_smoothness(DBO_PSO_path);
    [~, DBO_PSO_len_cost(exp_idx), DBO_PSO_obs_cost(exp_idx), DBO_PSO_alt_cost(exp_idx), DBO_PSO_smooth_cost(exp_idx)] = fobj(DBO_PSO_Best_pos);
    
    % PSO
    tic;
    [PSO_Best_score, PSO_Best_pos, ~] = PSO(popsize, maxIter, lb, ub, dim, fobj);
    PSO_times(exp_idx) = toc;
    PSO_scores(exp_idx) = PSO_Best_score;
    PSO_path = reconstruct_path2(PSO_Best_pos, start_point, end_point, num_points);
    PSO_distances(exp_idx) = calculate_path_distance(PSO_path);
    PSO_smoothnesses(exp_idx) = calculate_smoothness(PSO_path);
    [~, PSO_len_cost(exp_idx), PSO_obs_cost(exp_idx), PSO_alt_cost(exp_idx), PSO_smooth_cost(exp_idx)] = fobj(PSO_Best_pos);
    
    % IDBO
    tic;
    [IDBO_Best_score, IDBO_Best_pos, ~] = IDBO(popsize, maxIter, lb, ub, dim, fobj);
    IDBO_times(exp_idx) = toc;
    IDBO_scores(exp_idx) = IDBO_Best_score;
    IDBO_path = reconstruct_path2(IDBO_Best_pos, start_point, end_point, num_points);
    IDBO_distances(exp_idx) = calculate_path_distance(IDBO_path);
    IDBO_smoothnesses(exp_idx) = calculate_smoothness(IDBO_path);
    [~, IDBO_len_cost(exp_idx), IDBO_obs_cost(exp_idx), IDBO_alt_cost(exp_idx), IDBO_smooth_cost(exp_idx)] = fobj(IDBO_Best_pos);
    
    % ECFDBO
    tic;
    [ECFDBO_Best_score, ECFDBO_Best_pos, ~] = ECFDBO(popsize, maxIter, lb, ub, dim, fobj);
    ECFDBO_times(exp_idx) = toc;
    ECFDBO_scores(exp_idx) = ECFDBO_Best_score;
    ECFDBO_path = reconstruct_path2(ECFDBO_Best_pos, start_point, end_point, num_points);
    ECFDBO_distances(exp_idx) = calculate_path_distance(ECFDBO_path);
    ECFDBO_smoothnesses(exp_idx) = calculate_smoothness(ECFDBO_path);
    [~, ECFDBO_len_cost(exp_idx), ECFDBO_obs_cost(exp_idx), ECFDBO_alt_cost(exp_idx), ECFDBO_smooth_cost(exp_idx)] = fobj(ECFDBO_Best_pos);
end

% 7. 显示统计结果
fprintf('\n===== %d次实验统计结果 =====\n', nRuns);
fprintf('\n%-12s %-10s %-10s %-10s %-10s %-10s %-10s %-10s\n', '算法', '总成本', '距离成本', '碰撞成本', '高度成本', '平滑成本', '路径长度', '平滑度');
fprintf('%s\n', repmat('-', 1, 110));

for i = 1:length(algorithms)
    alg = algorithms{i};
    fprintf('%-12s %-10.2f %-10.2f %-10.2f %-10.2f %-10.2f %-10.2f %-10.2f\n', ...
        alg, ...
        mean(eval([alg, '_scores'])), ...
        mean(eval([alg, '_len_cost'])), ...
        mean(eval([alg, '_obs_cost'])), ...
        mean(eval([alg, '_alt_cost'])), ...
        mean(eval([alg, '_smooth_cost'])), ...
        mean(eval([alg, '_distances'])), ...
        mean(eval([alg, '_smoothnesses'])));
end

fprintf('\n运行时间统计:\n');
fprintf('%-12s %-20s %-20s\n', '算法', '总运行时间(秒)', '平均运行时间(秒)');
for i = 1:length(algorithms)
    alg = algorithms{i};
    times = eval([alg, '_times']);
    fprintf('%-12s %-20.2f %-20.2f\n', alg, sum(times), mean(times));
end

% 8. 运行最后一次实验获取收敛曲线
[DBO_Best_score, DBO_Best_pos, DBO_cg] = DBO(popsize, maxIter, lb, ub, dim, fobj);
[DBO_PSO_Best_score, DBO_PSO_Best_pos, DBO_PSO_cg] = DBOPSO(popsize, maxIter, lb, ub, dim, fobj);
[PSO_Best_score, PSO_Best_pos, PSO_cg] = PSO(popsize, maxIter, lb, ub, dim, fobj);
[IDBO_Best_score, IDBO_Best_pos, IDBO_cg] = IDBO(popsize, maxIter, lb, ub, dim, fobj);
[ECFDBO_Best_score, ECFDBO_Best_pos, ECFDBO_cg] = ECFDBO(popsize, maxIter, lb, ub, dim, fobj);

% 解析路径
DBO_path = reconstruct_path2(DBO_Best_pos, start_point, end_point, num_points);
DBO_PSO_path = reconstruct_path2(DBO_PSO_Best_pos, start_point, end_point, num_points);
PSO_path = reconstruct_path2(PSO_Best_pos, start_point, end_point, num_points);
IDBO_path = reconstruct_path2(IDBO_Best_pos, start_point, end_point, num_points);
ECFDBO_path = reconstruct_path2(ECFDBO_Best_pos, start_point, end_point, num_points);

% 9. 绘制收敛性对比图
figure('Name', 'Convergence Comparision', 'Position', [100, 100, 1200, 600]);
colors = {'b-', 'r-', 'g-.', 'm-', 'c-'};
cg_data = {DBO_cg, DBO_PSO_cg, PSO_cg, IDBO_cg, ECFDBO_cg};

hold on;
for i = 1:length(algorithms)
    plot(1:maxIter, cg_data{i}, colors{i}, 'LineWidth', 2);
end
xlabel('Number of iterations', 'FontSize', 12);
ylabel('Optimal Combined Path Cost Value', 'FontSize', 12);
title('Convergence Comparision', 'FontSize', 14, 'FontWeight', 'bold');
legend_names = {'DBO', 'DBO-PSO', 'PSO', 'IDBO', 'ECFDBO'};
legend(legend_names, 'Location', 'best', 'FontSize', 10, 'Interpreter', 'none');
grid on;
box on;
hold off;

% 10. 绘制路径三维对比图
figure('Name', '3D Visualization of Pathing Planning', 'Position', [100, 100, 1200, 800]);
hold on; grid on; box on;

% 绘制地形
[X, Y] = meshgrid(1:size(city_map,2), 1:size(city_map,1));
terrain_z = zeros(size(city_map));
terrain_z(~obstacle_mask) = 0.3;
surf(X, Y, terrain_z, 'FaceColor', [0.95, 0.95, 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'HandleVisibility', 'off');

% 绘制障碍物
[rows, cols] = find(obstacle_mask);
for k = 1:length(rows)
    x = cols(k);
    y = rows(k);
    height = city_map(y, x);
    
    x_coords = [x, x+1, x+1, x, x, x+1, x+1, x];
    y_coords = [y, y, y+1, y+1, y, y, y+1, y+1];
    z_coords = [0, 0, 0, 0, height, height, height, height];
    
    if height > 20
        color = [0.2, 0.2, 0.2];
    elseif height > 10
        color = [0.4, 0.4, 0.4];
    elseif height > 5
        color = [0.6, 0.6, 0.6];
    else
        color = [0.7, 0.7, 0.5];
    end
    
    patch(x_coords, y_coords, z_coords, color, 'FaceAlpha', 0.8, ...
        'EdgeColor', [0.1, 0.1, 0.1], 'LineWidth', 0.5, 'HandleVisibility', 'off');
end

% 绘制所有路径
path_colors = {'b-', 'r-', 'g-.', 'm-', 'c-'};
paths = {DBO_path, DBO_PSO_path, PSO_path, IDBO_path, ECFDBO_path};
path_handles = [];

for i = 1:length(algorithms)
    %[curve, t] = space_spline_interp(paths{i}, 100, 'pchip');
    %h = plot3(curve(:,1),curve(:,2), curve(:,3), path_colors{i}, 'LineWidth', 2.5);
    h = plot3(paths{i}(:,1), paths{i}(:,2), paths{i}(:,3), path_colors{i}, 'LineWidth', 2.5);
    path_handles = [path_handles, h];
end

% 标记起点终点
start_marker = scatter3(start_point(1), start_point(2), start_point(3), 200, 'g', 'filled', 'Marker', 'p');
end_marker = scatter3(end_point(1), end_point(2), end_point(3), 200, 'm', 'filled', 'Marker', 's');
text(start_point(1)+1, start_point(2)+1, start_point(3)+2, 'startpoint', 'Color', 'g', 'FontSize', 10);
text(end_point(1)+1, end_point(2)+1, end_point(3)+2, 'endpoint', 'Color', 'm', 'FontSize', 10);

xlabel('X (m)', 'FontSize', 12);
ylabel('Y (m)', 'FontSize', 12);
zlabel('height (m)', 'FontSize', 12);
title('3D Visualization of Pathing Planning', 'FontSize', 14, 'FontWeight', 'bold');
legend_names = {'DBO', 'DBO-PSO', 'PSO', 'IDBO', 'ECFDBO'};
legend([path_handles, start_marker, end_marker], [legend_names, 'startpoint', 'endpoint'], 'Location', 'best', 'FontSize', 10);
view(-30, 30);
axis tight;
xlim([1, size(city_map,2)]);
ylim([1, size(city_map,1)]);
zlim([0, 60]);

% 11. 显示最后一次实验详细结果
[DBO_total, DBO_len, DBO_obs, DBO_alt, DBO_sm] = fobj(DBO_Best_pos);
[DBO_PSO_total, DBO_PSO_len, DBO_PSO_obs, DBO_PSO_alt, DBO_PSO_sm] = fobj(DBO_PSO_Best_pos);
[PSO_total, PSO_len, PSO_obs, PSO_alt, PSO_sm] = fobj(PSO_Best_pos);
[IDBO_total, IDBO_len, IDBO_obs, IDBO_alt, IDBO_sm] = fobj(IDBO_Best_pos);
[ECFDBO_total, ECFDBO_len, ECFDBO_obs, ECFDBO_alt, ECFDBO_sm] = fobj(ECFDBO_Best_pos);

fprintf('\n===== 最后一次实验详细结果 =====\n');
fprintf('\n%-12s %-10s %-10s %-10s %-10s %-10s %-10s %-10s\n', '算法', '总成本', '距离成本', '碰撞成本', '高度成本', '平滑成本', '路径长度', '平滑度');
fprintf('%s\n', repmat('-', 1, 110));
fprintf('%-12s %-10.2f %-10.2f %-10.2f %-10.2f %-10.2f %-10.2f %-10.2f\n', 'DBO', DBO_total, DBO_len, DBO_obs, DBO_alt, DBO_sm, calculate_path_distance(DBO_path), calculate_smoothness(DBO_path));
fprintf('%-12s %-10.2f %-10.2f %-10.2f %-10.2f %-10.2f %-10.2f %-10.2f\n', 'DBO_PSO', DBO_PSO_total, DBO_PSO_len, DBO_PSO_obs, DBO_PSO_alt, DBO_PSO_sm, calculate_path_distance(DBO_PSO_path), calculate_smoothness(DBO_PSO_path));
fprintf('%-12s %-10.2f %-10.2f %-10.2f %-10.2f %-10.2f %-10.2f %-10.2f\n', 'PSO', PSO_total, PSO_len, PSO_obs, PSO_alt, PSO_sm, calculate_path_distance(PSO_path), calculate_smoothness(PSO_path));
fprintf('%-12s %-10.2f %-10.2f %-10.2f %-10.2f %-10.2f %-10.2f %-10.2f\n', 'IDBO', IDBO_total, IDBO_len, IDBO_obs, IDBO_alt, IDBO_sm, calculate_path_distance(IDBO_path), calculate_smoothness(IDBO_path));
fprintf('%-12s %-10.2f %-10.2f %-10.2f %-10.2f %-10.2f %-10.2f %-10.2f\n', 'ECFDBO', ECFDBO_total, ECFDBO_len, ECFDBO_obs, ECFDBO_alt, ECFDBO_sm, calculate_path_distance(ECFDBO_path), calculate_smoothness(ECFDBO_path));

% 12. 单独绘制城市地形图
%% === 单独绘制城市地形图（仅地形+障碍物，无路径） ===
figure('Name', 'city map', 'Position', [300, 100, 900, 700]);
hold on; grid on; axis equal; box on;

[X, Y] = meshgrid(1:size(city_map,2), 1:size(city_map,1));
surf(X, Y, city_map, ...
    'EdgeColor', 'none', ...
    'FaceColor', 'interp', ...
    'FaceAlpha', 0.9);
% 创建现代感颜色映射 - 从深绿到红的渐变
color_levels = 256;
terrain_colors = [
    % 深绿到中绿
    linspace(0.1, 0.4, color_levels/3)' linspace(0.5, 0.8, color_levels/3)' linspace(0.1, 0.4, color_levels/3)';
    % 中绿到黄
    linspace(0.4, 1, color_levels/3)' linspace(0.8, 1, color_levels/3)' linspace(0.4, 0, color_levels/3)';
    % 黄到红
    linspace(1, 0.8, color_levels/3)' linspace(1, 0.2, color_levels/3)' linspace(0, 0.1, color_levels/3)'
    ];
colormap(terrain_colors);

% 简洁颜色条
c = colorbar;
c.Ticks = linspace(0, max(city_map(:)), 6);
c.TickLabels = arrayfun(@(x) sprintf('%.1f', x), linspace(0, max(city_map(:)), 6), 'UniformOutput', false);
c.Label.String = 'Height (m)';
c.Label.FontSize = 11;
c.Label.FontWeight = 'bold';
c.Color = [0.3 0.3 0.3];

% 清晰坐标轴标签
xlabel('X ', 'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.2 0.2 0.2]);
ylabel('Y ', 'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.2 0.2 0.2]);
zlabel('Height (m)', 'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.2 0.2 0.2]);

% 简洁标题
title('3D city map', ...
    'FontSize', 14, ...
    'FontWeight', 'bold', ...
    'Color', [0.1 0.3 0.2]);

% 最佳3D视角
view(38, 28);

% 高级光照
lighting gouraud;
material([0.4 0.7 0.2 10 0.4]);

% 主光源
h1 = light('Position', [0.8 0.6 0.7], 'Style', 'infinite');
h1.Color = [1.0 1.0 0.95];

% 补光
h2 = light('Position', [-0.5 -0.5 0.3], 'Style', 'infinite');
h2.Color = [0.9 0.95 1.0];

% 纯白背景
set(gca, 'Color', [1 1 1]);
set(gcf, 'Color', [1 1 1]);

% 显示坐标轴和网格
box on;
grid on;

% 美化坐标轴样式
set(gca, ...
    'FontSize', 10, ...
    'FontWeight', 'normal', ...
    'XColor', [0.4 0.4 0.4], ...
    'YColor', [0.4 0.4 0.4], ...
    'ZColor', [0.4 0.4 0.4], ...
    'GridColor', [0.85 0.85 0.85], ...
    'GridAlpha', 0.6, ...
    'LineWidth', 1);

% 设置合适的显示范围
axis tight;
zlim([min(city_map(:)) * 0.98, max(city_map(:)) * 1.02]);

% 优化比例
daspect([1 1 0.35]);

% 高质量渲染
shading interp;

% 添加底座增强立体感
hold on;
[xx, yy] = meshgrid(1:size(city_map,2), 1:size(city_map,1));
base_level = min(city_map(:)) * 0.99;
surf(xx, yy, base_level * ones(size(city_map)), ...
    'FaceColor', [0.96 0.96 0.98], ...
    'EdgeColor', [0.9 0.9 0.92], ...
    'FaceAlpha', 0.9, ...
    'EdgeAlpha', 0.2);

% 确保地形在最上层
uistack(findobj(gca, 'Type', 'surface', 'FaceAlpha', 1), 'top');

% 刷新显示
drawnow;