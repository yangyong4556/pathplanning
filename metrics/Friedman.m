clear; clc; close all;

%% 文件路径设置
rootDir = "D:\CafucCodes\appDev\PapersCodesToGitHub";
wordingFolder = fullfile(rootDir, "BenchmarkFuncs");

save_dir = fullfile(wordingFolder, ...
    'CEC2022_自定义_F1_F2_F3_F4_F5_F6_F7_F8_F9_F10_F11_F12');

dataSave_dir = fullfile(save_dir, "多次运行结果数据统计");
imgSave_dir  = fullfile(save_dir, "多次运行结果对比图");

% 与主程序保持一致的实验参数
dim     = 20;       % 维度
popsize = 50;      % 种群规模
maxIter = 1000;      % 最大迭代次数
runs    = 30;       % 每个函数独立运行次数

currentDataName = sprintf('%d%s_%d%s_%d%s_%d%s', ...
    dim, 'dim', popsize, 'pop', maxIter, 'maxIter', runs, 'runs');

result_dir     = fullfile(dataSave_dir, currentDataName);   % 表格输出目录
img_result_dir = fullfile(imgSave_dir,  currentDataName);   % 图片输出目录

if ~exist(result_dir, 'dir')
    mkdir(result_dir);
end
if ~exist(img_result_dir, 'dir')
    mkdir(img_result_dir);
end

filename = fullfile(result_dir, 'all_fit_results_CEC2022.xlsx');

if ~exist(filename, 'file')
    error('未找到文件：%s，请先运行主程序生成 all_fit_results_CEC2022.xlsx', filename);
end

%% 算法设置
alg_names = {'DBOPSO','IDBO','ECFDBO','DBO','PSO','DE','SSA','WOA','GA'};
num_alg = length(alg_names);

%% 读取 Excel 数据
raw = readcell(filename);

headers    = raw(1, 2:end);
func_names = raw(2:end, 1);
data_cell  = raw(2:end, 2:end);

data = cell2mat(data_cell);
num_func = size(data, 1);

%% 提取每个算法 30 次运行结果
alg_data = struct();

for a = 1:num_alg
    alg = alg_names{a};

    idx = false(1, length(headers));

    for c = 1:length(headers)
        h = string(headers{c});
        pattern = "^" + alg + "_Run\d+$";
        idx(c) = ~isempty(regexp(h, pattern, 'once'));
    end

    if sum(idx) ~= runs
        error('算法 %s 的运行列数不是 %d，而是 %d，请检查 all_fit_results_CEC2022.xlsx 表头。', ...
            alg, runs, sum(idx));
    end

    alg_data.(alg) = data(:, idx);
end

%% 计算每个函数上每个算法的平均结果
perf_matrix = zeros(num_func, num_alg);
std_matrix  = zeros(num_func, num_alg);
best_matrix = zeros(num_func, num_alg);

for a = 1:num_alg
    alg = alg_names{a};
    temp = alg_data.(alg);

    perf_matrix(:, a) = mean(temp, 2);
    std_matrix(:, a)  = std(temp, 0, 2);
    best_matrix(:, a) = min(temp, [], 2);
end

%% 计算 Friedman 排名
rank_matrix = zeros(num_func, num_alg);

for i = 1:num_func
    rank_matrix(i, :) = tiedrank(perf_matrix(i, :));
end

avg_ranks = mean(rank_matrix, 1);

%% 手动计算 Friedman 统计量
N = num_func;   % 测试函数数量
k = num_alg;    % 算法数量

Rj = sum(rank_matrix, 1);

chi_square_F = 12 / (N * k * (k + 1)) * sum(Rj .^ 2) - 3 * N * (k + 1);

% Iman-Davenport 修正后的 F 统计量
F_F = ((N - 1) * chi_square_F) / (N * (k - 1) - chi_square_F);

p_chi_square = 1 - chi2cdf(chi_square_F, k - 1);
p_F = 1 - fcdf(F_F, k - 1, (k - 1) * (N - 1));

%% Friedman 结果输出
fprintf('\n========================================================\n');
fprintf('Friedman Test Results for CEC2022\n');
fprintf('========================================================\n');
fprintf('Number of functions N = %d\n', N);
fprintf('Number of algorithms k = %d\n', k);
fprintf('Friedman chi-square statistic = %.6f\n', chi_square_F);
fprintf('Friedman p-value = %.6e\n', p_chi_square);
fprintf('Iman-Davenport F statistic = %.6f\n', F_F);
fprintf('Iman-Davenport p-value = %.6e\n', p_F);

if p_chi_square < 0.05
    fprintf('结论：p < 0.05，不同算法之间存在显著性差异。\n');
else
    fprintf('结论：p >= 0.05，不同算法之间不存在显著性差异。\n');
end

fprintf('\n========================================================\n');
fprintf('Average Rank of Algorithms\n');
fprintf('========================================================\n');

[sorted_rank, sort_idx] = sort(avg_ranks);

for i = 1:num_alg
    idx = sort_idx(i);
    fprintf('%2d. %-10s  Average Rank = %.4f\n', i, alg_names{idx}, avg_ranks(idx));
end

%% 保存排名结果表格
ranking_table = table();
ranking_table.Algorithm = alg_names';
ranking_table.Average_Rank = avg_ranks';
ranking_table.Mean_Over_Functions = mean(perf_matrix, 1)';
ranking_table.Std_Over_Functions  = mean(std_matrix, 1)';
ranking_table.Best_Over_Functions = mean(best_matrix, 1)';
ranking_table = sortrows(ranking_table, 'Average_Rank');

summary_table = table();
summary_table.N_Functions = N;
summary_table.K_Algorithms = k;
summary_table.Friedman_ChiSquare = chi_square_F;
summary_table.Friedman_p_value = p_chi_square;
summary_table.Iman_Davenport_F = F_F;
summary_table.Iman_Davenport_p_value = p_F;

%% 保存逐函数排名矩阵
rank_cell = cell(num_func + 1, num_alg + 1);
rank_cell{1, 1} = 'Function';

for a = 1:num_alg
    rank_cell{1, a + 1} = alg_names{a};
end

for i = 1:num_func
    rank_cell{i + 1, 1} = func_names{i};

    for a = 1:num_alg
        rank_cell{i + 1, a + 1} = rank_matrix(i, a);
    end
end

%% 保存 Excel 到“多次运行结果数据统计”
output_file = fullfile(result_dir, 'Friedman_CEC2022检验结果.xlsx');

if exist(output_file, 'file')
    delete(output_file);
end

writetable(ranking_table, output_file, 'Sheet', 'Average_Ranking');
writetable(summary_table, output_file, 'Sheet', 'Friedman_Summary');
writecell(rank_cell, output_file, 'Sheet', 'Rank_Matrix');

fprintf('\n==============================\n');
fprintf('Friedman 检验完成\n');
fprintf('表格结果已保存至：%s\n', output_file);
fprintf('================================\n');

%% 绘制平均排名图
figure('Position', [100, 100, 900, 500]);

b = bar(avg_ranks, 'FaceColor', 'flat');

bar_colors = [
    0.1216, 0.4667, 0.7059;   % DBOPSO
    1.0000, 0.4980, 0.0549;   % IDBO
    0.1725, 0.6275, 0.1725;   % ECFDBO
    0.8392, 0.1529, 0.1569;   % DBO
    0.5804, 0.4039, 0.7412;   % PSO
    0.5490, 0.3373, 0.2941;   % DE
    0.8902, 0.4667, 0.7608;   % SSA
    0.4980, 0.4980, 0.4980;   % WOA
    0.7373, 0.7412, 0.1333    % GA
];

if num_alg <= size(bar_colors, 1)
    b.CData = bar_colors(1:num_alg, :);
else
    b.CData = repmat(bar_colors, ceil(num_alg / size(bar_colors, 1)), 1);
    b.CData = b.CData(1:num_alg, :);
end

set(gca, ...
    'XTick', 1:num_alg, ...
    'XTickLabel', alg_names, ...
    'XTickLabelRotation', 45, ...
    'FontName', 'Times New Roman', ...
    'FontSize', 11);

ylabel('Average Rank', 'FontName', 'Times New Roman', 'FontSize', 12);
title('Friedman Average Ranking on CEC2022', ...
    'FontName', 'Times New Roman', 'FontSize', 13);

grid on;
box on;

for i = 1:num_alg
    text(i, avg_ranks(i) + 0.05, sprintf('%.2f', avg_ranks(i)), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontName', 'Times New Roman', ...
        'FontSize', 10);
end

%% 保存图片到“多次运行结果对比图”
saveas(gcf, fullfile(img_result_dir, 'Friedman_average_rank_CEC2022.fig'));
print(gcf, fullfile(img_result_dir, 'Friedman_average_rank_CEC2022.tif'), '-dtiff', '-r600');

fprintf('图片结果已保存至：%s\n', img_result_dir);