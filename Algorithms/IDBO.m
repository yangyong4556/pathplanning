%% 改进蜣螂优化算法 (IDBO) - Improved Dung Beetle Optimizer
% 基于论文: 基于改进蜣螂算法的无人机三维路径规划  作者: 王海群, 宋国章, 葛超
% Wang H Q, Song G, Ge Chao. 3D Path Planning of UAVs Based on Improved Dung Beetle Algorithm[J]. 
% Electronics Optics & Control, 2024, 31(11): 55–61+82. (in Chinese)

%% ==================== 改进蜣螂优化算法主函数 ====================
function [fMin, bestX, convergence_curve] = IDBO(popsize, maxIter, lb, ub, dim,fobj)
    % 初始化
    t = 0;  % 迭代次数
    convergence_curve = zeros(1, maxIter);
    
    % 参数设置
    k = 0.5;        % 偏转系数
    b = 0.3;        % 常数 (0,1)
    S = 0.3;        % 常数
    
    % 初始化种群位置
    X = PWLCM_initialization(popsize, dim, lb, ub );
    
    % 计算初始适应度
    N = length(X);
    fitness = zeros(N, 1);
    for i = 1:N
        fitness(i) = fobj(X(i, :));
    end
    
    % 初始化全局最优和最差位置
    [fMin, best_idx] = min(fitness);
    Xb = X(best_idx, :);        % 全局最优位置
    [worst_fitness, worst_idx] = max(fitness);
    Xw = X(worst_idx, :);       % 全局最差位置
    X_star = Xb;                 % 局部最优位置
    
    %% 主循环
    while t < maxIter
        % 更新滚球蜣螂权重 (自适应非线性递减模型)
        P = 0.1 * (2 - t/maxIter) * (1 - t/maxIter);  
        n_rolling = max(1, round(popsize * P));      
        n_breeding = round((popsize - n_rolling) / 3);
        n_small = round((popsize - n_rolling) / 3);
        n_thief = popsize - n_rolling - n_breeding - n_small;
        
        % 更新动态螺旋参数
        g_prime = -1 + 2 * rand();  % [-1,1]随机数
        k_const = 1;                % 螺旋形状常数
        c = exp(g_prime * k_const * cos(pi * t / maxIter));
        
        % 更新产卵区和觅食区边界
        R = 1 - t / maxIter;
        L_star = max(Xb * (1 - R), lb);
        U_star = min(Xb * (1 + R), ub);
        Lb = max(Xb * (1 - R), lb);
        Ub = min(Xb * (1 + R), ub);
        
        % 记录新位置
        new_X = X;
        new_fitness = fitness;
        
        % 1. 滚球蜣螂更新 (全局搜索)
        idx_rolling = randperm(N, n_rolling);
        for i = idx_rolling
            alpha = 2 * (rand() > 0.5) - 1;  % -1或1
            delta_x = abs(X(i, :) - Xw);
            
            if rand() < 0.9
                % 滚球模式
                X_new = X(i, :) + alpha * k * X(i, :) + b * delta_x;
            else
                % 跳舞模式
                theta = pi * rand();
                if theta ~= 0 && theta ~= pi/2 && theta ~= pi
                    X_new = X(i, :) + tan(theta) * abs(X(i, :) - X(max(1, i-1), :));
                else
                    X_new = X(i, :);
                end
            end
            
            % 边界处理
            X_new = max(min(X_new, ub), lb);
            new_fitness(i) = fobj(X_new);
            if new_fitness(i) < fitness(i)
                new_X(i, :) = X_new;
            else
                new_X(i, :) = X(i, :);
            end
        end
        
        % 2. 繁殖蜣螂更新 (融合鲸鱼螺旋搜索)
        idx_breeding = setdiff(randperm(N, n_breeding), idx_rolling);
        for i = idx_breeding
            b1 = rand(1, dim);
            b2 = rand(1, dim);
            % 融合螺旋搜索策略
            l = -1 + 2 * rand();
            X_new = X_star + exp(c * l) * cos(2 * pi * l) * b1 .* (X(i, :) - L_star) + ...
                    exp(c * l) * cos(2 * pi * l) * b2 .* (X(i, :) - U_star);
            
            X_new = max(min(X_new, Ub), Lb);
            new_fitness(i) = fobj(X_new);
            if new_fitness(i) < fitness(i)
                new_X(i, :) = X_new;
            else
                new_X(i, :) = X(i, :);
            end
        end
        
        % 3. 小蜣螂更新 (融合鲸鱼螺旋搜索)
        idx_small = setdiff(randperm(N, n_small), [idx_rolling, idx_breeding]);
        for i = idx_small
            C1 = randn(1, dim);
            C2 = rand(1, dim);
            l = -1 + 2 * rand();
            X_new = exp(c * l) * cos(2 * pi * l) * X(i, :) + ...
                    C1 .* (X(i, :) - Lb) + C2 .* (X(i, :) - Ub);
            
            X_new = max(min(X_new, ub), lb);
            new_fitness(i) = fobj(X_new);
            if new_fitness(i) < fitness(i)
                new_X(i, :) = X_new;
            else
                new_X(i, :) = X(i, :);
            end
        end
        
        % 4. 小偷蜣螂更新
        idx_thief = setdiff(1:N, [idx_rolling, idx_breeding, idx_small]);
        for i = idx_thief
            g = randn(1, dim);
            X_new = Xb + S * g .* (abs(X(i, :) - X_star) + abs(X(i, :) - Xb));
            
            X_new = max(min(X_new, ub), lb);
            new_fitness(i) = fobj(X_new);
            if new_fitness(i) < fitness(i)
                new_X(i, :) = X_new;
            else
                new_X(i, :) = X(i, :);
            end
        end
        
        % 更新种群
        X = new_X;
        fitness = new_fitness;
        
        % 更新全局最优和最差
        [current_best, best_idx] = min(fitness);
        if current_best < fMin
            fMin = current_best;
            Xb = X(best_idx, :);
        end
        [current_worst, worst_idx] = max(fitness);
        if current_worst > worst_fitness
            worst_fitness = current_worst;
            Xw = X(worst_idx, :);
        end
        X_star = Xb;
        
        % 记录收敛曲线
        convergence_curve(t + 1) = fMin;
        
        % 显示进度
        % if mod(t, 20) == 0
        %     fprintf('迭代次数: %d, 最优适应度: %.6e\n', t, fMin);
        % end
        
        t = t + 1;
    end
    
    bestX = Xb;
end

%% ==================== 分段线性混沌映射初始化 ====================
function pop = PWLCM_initialization(N, dim, lb, ub)
    % 分段线性混沌映射
    p = 0.1;  % p ∈ (0, 0.5)
    x = rand();  % 初始值 x ∈ (0,1)

    % 生成混沌序列
    chaos_seq = zeros(N, dim);
    for i = 1:N
        for j = 1:dim
            x = PWLCM_map(x, p);
            chaos_seq(i, j) = x;
        end
    end

    % 映射到搜索空间
    pop = lb + chaos_seq .* (ub - lb);
end

function x_next = PWLCM_map(x, p)
    %分段线性混沌映射函数
    if 0 <= x && x < p
        x_next = x / p;
    elseif p <= x && x < 0.5
        x_next = (x - p) / (0.5 - p);
    elseif 0.5 <= x && x < 1 - p
        x_next = (1 - p - x) / (0.5 - p);
    elseif 1 - p <= x && x < 1
        x_next = (1 - x) / p;
    else
        x_next = rand();
    end
end