clear; clc; close all;

%% 文件路径设置
rootDir = "D:\CafucCodes\appDev\PapersCodesToGitHub";
wordingFolder = fullfile(rootDir, "BenchmarkFuncs");

save_dir = fullfile(wordingFolder, ...
    'CEC2022_自定义_F1_F2_F3_F4_F5_F6_F7_F8_F9_F10_F11_F12');

dataSave_dir = fullfile(save_dir, "多次运行结果数据统计");

% 与主程序保持一致的实验参数
dim     = 20;       % 维度
popsize = 50;      % 种群规模
maxIter = 1000;      % 最大迭代次数
runs    = 30;       % 每个函数独立运行次数

currentDataName = sprintf('%d%s_%d%s_%d%s_%d%s', ...
    dim, 'dim', popsize, 'pop', maxIter, 'maxIter', runs, 'runs');

result_dir = fullfile(dataSave_dir, currentDataName);
filename   = fullfile(result_dir, 'all_fit_results_CEC2022.xlsx');

if ~exist(filename, 'file')
    error('未找到文件：%s', filename);
end

%% 算法
% 顺序与主程序生成 all_fit_results_CEC2022.xlsx 时保持一致
alg_names = {'DBOPSO','IDBO','ECFDBO','DBO','PSO','DE','SSA','WOA','GA'};

%--------- 这里为主算法 -----%
target_alg = 'ECFDBO';

num_alg = length(alg_names);

%% 读取数据
raw = readcell(filename);

headers   = raw(1, 2:end);       % 第一行：算法_Run编号
func_names = raw(2:end, 1);      % 第一列：函数名称
data_cell = raw(2:end, 2:end);   % 数值区域

% 转换为数值矩阵
data = cell2mat(data_cell);

num_func = size(data, 1);

%% 按算法提取 30 次运行数据
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

%% 秩和检验
if ~isfield(alg_data, target_alg)
    error('target_alg = %s 不在算法列表中。', target_alg);
end

fprintf('\n========================================================\n');
fprintf('Wilcoxon Rank-Sum Test\n');
fprintf('Target Algorithm: %s\n', target_alg);
fprintf('说明：+ 表示 %s 显著优于对比算法；- 表示显著差于对比算法；= 表示无显著差异\n', target_alg);
fprintf('显著性：** p < 0.01, * p < 0.05\n');
fprintf('========================================================\n\n');

target_data = alg_data.(target_alg);

compare_algs = alg_names(~strcmp(alg_names, target_alg));
num_compare = length(compare_algs);

%% 构造输出表格
% 每个对比算法输出两列：p值 + 结果标记
result_table = cell(num_func + 1, 1 + 2 * num_compare);
result_table{1, 1} = 'Function';

col = 2;
for a = 1:num_compare
    result_table{1, col}     = [target_alg, '_vs_', compare_algs{a}, '_p'];
    result_table{1, col + 1} = [target_alg, '_vs_', compare_algs{a}, '_Result'];
    col = col + 2;
end

%% 胜平负统计
summary_table = cell(num_compare + 1, 6);
summary_table{1, 1} = 'Comparison';
summary_table{1, 2} = 'Win';
summary_table{1, 3} = 'Tie';
summary_table{1, 4} = 'Loss';
summary_table{1, 5} = 'Win/Tie/Loss';
summary_table{1, 6} = 'Description';

for a = 1:num_compare

    comp_alg  = compare_algs{a};
    comp_data = alg_data.(comp_alg);

    win  = 0;
    tie  = 0;
    loss = 0;

    fprintf('================ %s vs %s ================\n', target_alg, comp_alg);

    for i = 1:num_func

        x = target_data(i, :);
        y = comp_data(i, :);

        % Wilcoxon rank-sum test
        [p, ~] = ranksum(x, y);

        mean_x = mean(x);
        mean_y = mean(y);

        % 判断显著性与方向（值越小越好）
        if p < 0.05
            if mean_x < mean_y
                result_mark = ['+ ', get_sig_mark(p)];
                win = win + 1;
            elseif mean_x > mean_y
                result_mark = ['- ', get_sig_mark(p)];
                loss = loss + 1;
            else
                result_mark = ['= ', get_sig_mark(p)];
                tie = tie + 1;
            end
        else
            result_mark = '=';
            tie = tie + 1;
        end

        fprintf('%s: p = %.4e, Mean(%s)=%.4e, Mean(%s)=%.4e, Result=%s\n', ...
            string(func_names{i}), p, target_alg, mean_x, comp_alg, mean_y, result_mark);

        % 保存到表格
        result_table{i + 1, 1} = func_names{i};
        col = 2 + 2 * (a - 1);
        result_table{i + 1, col}     = p;
        result_table{i + 1, col + 1} = result_mark;
    end

    fprintf('Summary: Win/Tie/Loss = %d/%d/%d\n\n', win, tie, loss);

    summary_table{a + 1, 1} = [target_alg, ' vs ', comp_alg];
    summary_table{a + 1, 2} = win;
    summary_table{a + 1, 3} = tie;
    summary_table{a + 1, 4} = loss;
    summary_table{a + 1, 5} = sprintf('%d/%d/%d', win, tie, loss);
    summary_table{a + 1, 6} = '+ means target algorithm is significantly better';
end

%% 保存结果
% output_file = fullfile(result_dir, 'Wilcoxon_test_results_CEC2022.xlsx');
% 
% if exist(output_file, 'file')
%     delete(output_file);
% end
% 
% writecell(result_table, output_file, 'Sheet', 'Wilcoxon_p_values');
% writecell(summary_table, output_file, 'Sheet', 'Win_Tie_Loss');
% 
% fprintf('\n========================================================\n');
% fprintf('Wilcoxon 检验完成\n');
% fprintf('结果已保存至：%s\n', output_file);
% fprintf('========================================================\n');

% 1) Wilcoxon符号结果表（逐函数 p值 + 符号）
symbol_file = fullfile(result_dir, 'Wilcoxon符号结果表.xlsx');
if exist(symbol_file, 'file')
    delete(symbol_file);
end
writecell(result_table, symbol_file);

% 2) Wilcoxon秩结果表（Win/Tie/Loss 汇总）
rank_file = fullfile(result_dir, 'Wilcoxon秩结果表.xlsx');
if exist(rank_file, 'file')
    delete(rank_file);
end
writecell(summary_table, rank_file);

fprintf('\n========================================================\n');
fprintf('Wilcoxon 检验完成\n');
fprintf('Wilcoxon符号结果表已保存至：%s\n', symbol_file);
fprintf('Wilcoxon秩结果表已保存至：%s\n', rank_file);
fprintf('========================================================\n');

%% 显著性标记函数
function mark = get_sig_mark(p)
    if p < 0.01
        mark = '**';
    elseif p < 0.05
        mark = '*';
    else
        mark = '';
    end
end