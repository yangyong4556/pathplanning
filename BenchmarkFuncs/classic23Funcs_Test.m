clear; clc; close all;

%% 路径设置
rootDir = "D:\CafucCodes\appDev\PapersCodesToGitHub";
rmpath(rootDir);
addpath(genpath(rootDir));
wordingFolder = fullfile(rootDir, "BenchmarkFuncs");
cd(wordingFolder);

%% 实验参数
dim     = 20;       % 维度
popsize = 50;      % 种群规模
maxIter = 10;      % 最大迭代次数
runs    = 3;       % 每个函数独立运行次数

%% 结果保存文件夹
save_dir = fullfile(wordingFolder, 'Classical_自定义_F1-F23');
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

imgSave_dir  = fullfile(save_dir, "多次运行结果对比图");
dataSave_dir = fullfile(save_dir, "多次运行结果数据统计");

if ~exist(imgSave_dir, 'dir')
    mkdir(imgSave_dir);
end
if ~exist(dataSave_dir, 'dir')
    mkdir(dataSave_dir);
end

currentDataName = sprintf('%d%s_%d%s_%d%s_%d%s', dim,'dim', popsize,'pop',maxIter,'maxIter',runs,'runs');
imgNdSave_dir= fullfile(imgSave_dir,currentDataName);
dataNdSave_dir=fullfile(dataSave_dir,currentDataName);

if ~exist(imgNdSave_dir, 'dir')
    mkdir(imgNdSave_dir);
end
if ~exist(dataNdSave_dir, 'dir')
    mkdir(dataNdSave_dir);
end

%% 23个经典函数测试函数
fun_names = {'F1','F2','F3','F4','F5','F6','F7','F8','F9','F10', 'F11','F12','F13','F14','F15','F16','F17','F18', 'F19','F20','F21','F22','F23'};

% 23 个经典测试函数理论最优值
fopt = [0, 0, 0, 0, 0, 0, 0, -12569.5, 0, 0, 0, 0, 0, ...
        1, 0.0003075, -1.0316285, 0.398, 3, -3.86, -3.32, -10, -10, -10];

%% 算法设置
alg_list  = {@DBOPSO, @IDBO, @ECFDBO, @DBO, @PSO, @DE, @SSA, @WOA, @GA};
alg_names = {'DBOPSO','IDBO','ECFDBO','DBO','PSO','DE','SSA','WOA','GA'};

%% 实验参数
maxgen   = maxIter;
num_func = length(fun_names);
num_alg  = length(alg_list);

% results: 测试函数 × 算法 × 独立运行次数
results = zeros(num_func, num_alg, runs);

% times: 测试函数 × 算法 × 独立运行次数
times = zeros(num_func, num_alg, runs);

% curves: 测试函数 × 算法 × 平均收敛曲线
curves = zeros(num_func, num_alg, maxgen);

% dims: 记录每个测试函数维度
% dims = zeros(num_func, 1);

%% 主循环
for i = 1:num_func
    func_name = fun_names{i};
    [lb, ub, dim, fobj] = Get_Classical_23_Functions(func_name);

    if isscalar(lb)
        lb = lb * ones(1, dim);
    else
        lb = lb(:)';
    end

    if isscalar(ub)
        ub = ub * ones(1, dim);
    else
        ub = ub(:)';
    end

    fprintf('\n====================================================\n');
    fprintf('正在测试 23 个经典函数：%s\n', func_name);
    fprintf('维度：%d | 理论最优值：%.8e\n', dim, fopt(i));
    fprintf('====================================================\n');

    for j = 1:num_alg
        alg      = alg_list{j};
        alg_name = alg_names{j};

        fprintf('\n------ Algorithm: %s ------\n', alg_name);

        all_curves = zeros(runs, maxgen);

        for k = 1:runs

            try
                tStart = tic;
                [fit, best_pos, curve] = alg(popsize, maxIter, lb, ub, dim, fobj);
                run_time = toc(tStart);
            catch ME
                fprintf('\n算法运行出错：%s | 函数：%s | 第 %d 次运行\n', alg_name, func_name, k);
                rethrow(ME);
            end

            %% 适应度结果格式检查
            if numel(fit) > 1
                fit = fit(1);
            end

            if ~isfinite(fit)
                warning('%s 在 %s 第 %d 次运行得到非有限适应度，已记录为 Inf。', alg_name, func_name, k);
                fit = Inf;
            end

            %% 收敛曲线格式统一
            curve = curve(:)';

            if isempty(curve)
                curve = repmat(fit, 1, maxgen);
            end

            if any(~isfinite(curve))
                curve(~isfinite(curve)) = fit;
            end

            if length(curve) > maxgen
                curve = curve(1:maxgen);
            elseif length(curve) < maxgen
                curve = [curve, repmat(curve(end), 1, maxgen - length(curve))];
            end

            %% 保存当前运行结果
            results(i, j, k) = fit;
            times(i, j, k)   = run_time;
            all_curves(k, :) = curve;

            fprintf('%s | %s | Run %02d | Fit: %.8e | Error: %.8e | Time: %.6f s\n', ...
                alg_name, func_name, k, fit, abs(fit - fopt(i)), run_time);
        end

        % 当前算法在当前函数上的平均收敛曲线
        curves(i, j, :) = mean(all_curves, 1);
    end
end

%% 保存 MAT 结果
save(fullfile(dataNdSave_dir, 'results_Classical23.mat'), 'results', 'times', 'curves', 'fun_names', 'alg_names', 'fopt');

%% 生成“六种指标统计结果.xlsx”
% 行：测试函数 + 指标
% 列：算法名称
metric_names = {'min', 'std', 'avg', 'median', 'worse', 'avg_time'};

excel_data = cell(num_func * length(metric_names) + 1, num_alg + 2);
excel_data(1, :) = [{'Function', 'Metric'}, alg_names];

row = 2;
for i = 1:num_func
    for m = 1:length(metric_names)
        excel_data{row, 1} = fun_names{i};
        excel_data{row, 2} = metric_names{m};

        for j = 1:num_alg
            data  = squeeze(results(i, j, :));
            tdata = squeeze(times(i, j, :));

            switch metric_names{m}
                case 'min'
                    val = min(data);
                case 'std'
                    val = std(data);
                case 'avg'
                    val = mean(data);
                case 'median'
                    val = median(data);
                case 'worse'
                    val = max(data);
                case 'avg_time'
                    val = mean(tdata);
            end

            excel_data{row, j + 2} = val;
        end

        row = row + 1;
    end
end

% file_metrics = fullfile(save_dir, '六种指标统计结果.xlsx');
file_metrics = fullfile(dataNdSave_dir, '六种指标统计结果.xlsx');

if exist(file_metrics, 'file')
    delete(file_metrics);
end
writecell(excel_data, file_metrics);

%% 保存每次独立运行结果
excel_raw = {};
excel_raw{1, 1} = 'Function';

col = 2;
for j = 1:num_alg
    for k = 1:runs
        excel_raw{1, col} = [alg_names{j}, '_Run', num2str(k)];
        col = col + 1;
    end
end

for i = 1:num_func
    excel_raw{i + 1, 1} = fun_names{i};
    col = 2;
    for j = 1:num_alg
        for k = 1:runs
            excel_raw{i + 1, col} = results(i, j, k);
            col = col + 1;
        end
    end
end

file_raw = fullfile(dataNdSave_dir, 'all_fit_results_Classical23.xlsx');

if exist(file_raw, 'file')
    delete(file_raw);
end
writecell(excel_raw, file_raw);

%% 生成误差统计表
error_data = {};
error_data{1, 1} = 'Function/Algorithm';

for j = 1:num_alg
    error_data{1, j + 1} = alg_names{j};
end

for i = 1:num_func
    error_data{i + 1, 1} = fun_names{i};

    for j = 1:num_alg
        data = squeeze(results(i, j, :));
        best_found = min(data);
        error_data{i + 1, j + 1} = abs(best_found - fopt(i));
    end
end

file_error = fullfile(dataNdSave_dir, 'error_to_optimum_Classical23.xlsx');

if exist(file_error, 'file')
    delete(file_error);
end
writecell(error_data, file_error);

%% 绘制并保存收敛曲线
for i = 1:num_func

    figure('Visible', 'off');
    hold on;

    for j = 1:num_alg
        plot(squeeze(curves(i, j, :)), 'LineWidth', 1.6);
    end

    title(['Convergence curve - Classical ', fun_names{i}]);
    xlabel('Iterations');
    ylabel('Fitness');
    legend(alg_names, 'Location', 'northeast');
    grid on;

   saveas(gcf, fullfile(imgNdSave_dir, ['curve_Classical23_', fun_names{i}, '.fig']));
   print(gcf, fullfile(imgNdSave_dir, ['curve_Classical23_', fun_names{i}, '.tif']), '-dtiff', '-r600');

    close;
end

%% 完成提示
fprintf('\n====================================================\n');
fprintf('结果已保存至文件夹：%s\n', save_dir);
fprintf('1）results_Classical23.mat\n');
fprintf('2）六种指标统计结果.xlsx\n');
fprintf('3）all_fit_results_Classical23.xlsx\n');
fprintf('4）error_to_optimum_Classical23.xlsx\n');
fprintf('5）function_info_Classical23.xlsx\n');
fprintf('6）各测试函数收敛曲线 .fig 和 .tif\n');
fprintf('====================================================\n');