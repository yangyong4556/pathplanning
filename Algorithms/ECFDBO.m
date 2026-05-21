%% ECFDBO： Enviroment-aware Chaotic Force-field Dung Beetle Optimizer
% ref Paper: A Novel Improved Dung Beetle Optimization Algorithm for Collaborative 3D Path Planning of UAVs[J]. Biomimetics, 2025, 10(7): 420.
function [Best_score, Best_pos,  Convergence_curve] = ECFDBO(popsize, maxIter, lb, ub, dim, fobj)
% ECFDBO: Environment-aware Chaotic Force-field Dung Beetle Optimizer
% 所有功能集成在一个文件中
% Input:
%   N       - Population size
%   T_max   - Maximum number of iterations
%   lb      - Lower bound (scalar or vector)
%   ub      - Upper bound (scalar or vector)
%   dim     - Problem dimension
%   fobj    - Objective function handle
% Output:
%   Best_pos        - Best position found
%   Best_score      - Best fitness value
%   Convergence_curve - Convergence curve

    % 参数初始化
    p = 0.2;                % Proportion of rolling beetles
    eta0 = 0.02;            % Initial rebound factor
    w0 = 0.5;               % Initial attractive weight
    pm = 0.07;              % Mutation probability
    gamma = 1.25;           % Shrinkage strength parameter
    lambda = 1.25;          % Attenuation factor
    epsilon = 1e-8;         % Small perturbation for gradient calculation
    
    % 边界处理：将标量转换为向量
    if numel(lb) == 1
        lb = lb * ones(1, dim);
        ub = ub * ones(1, dim);
    end
    
    % 种群初始化
    X = initialization(popsize, dim, ub, lb);
    
    % 评估初始种群
    fitness = zeros(popsize, 1);
    for i = 1:popsize
        fitness(i) = fobj(X(i, :));
    end
    
    % 初始化最优和最差
    [Best_score, best_idx] = min(fitness);
    Best_pos = X(best_idx, :);
    [Worst_score, worst_idx] = max(fitness);
    Worst_pos = X(worst_idx, :);
    
    % 收敛曲线
    Convergence_curve = zeros(1, maxIter);
    
    % 主循环
    for t = 1:maxIter
        % 计算R值
        R = 1 - t / maxIter;
        
        % 各阶段蜣螂数量
        pNum = round(p * popsize);
        sNum = round(pNum / 2);
        
        % 构建次优解集（前10%）
        [sorted_fitness, sorted_idx] = sort(fitness);
        K = max(3, floor(0.1 * popsize));
        suboptimal_set = X(sorted_idx(1:K), :);
        
        % 更新每个个体
        for i = 1:popsize
            % 计算力场
            Fi = computeForceField(X(i, :), Best_pos, suboptimal_set, w0, t, maxIter);
            
            % 决定使用吸引-斥力变异还是混沌更新
            if rand() < pm
                % 吸引-斥力变异
                eta_guided = 1 - exp(-norm(Fi));
                Xnew = X(i, :) + Fi * eta_guided;
            else
                % 混沌扰动非线性收缩更新
                Xnew = chaoticNonlinearUpdate(X(i, :), Best_pos, X(max(i-1,1), :), gamma, lambda);
            end
            
            % 环境感知边界处理
            Xnew = smartReflect(Xnew, lb, ub, fobj, epsilon);
            
            X(i, :) = Xnew;
        end
        
        % DBO各阶段更新
        X = DBO_Stages(X, popsize, dim, lb, ub, Best_pos, Worst_pos, t, maxIter);
        
        % 边界检查
        for i = 1:popsize
            X(i, :) = smartReflect(X(i, :), lb, ub, fobj, epsilon);
        end
        
        % 评估种群
        for i = 1:popsize
            fitness(i) = fobj(X(i, :));
        end
        
        % 更新最优和最差
        [current_best, best_idx] = min(fitness);
        if current_best < Best_score
            Best_score = current_best;
            Best_pos = X(best_idx, :);
        end
        
        [current_worst, worst_idx] = max(fitness);
        if current_worst > Worst_score
            Worst_score = current_worst;
            Worst_pos = X(worst_idx, :);
        end
        
        % 记录收敛曲线
        Convergence_curve(t) = Best_score;
    end
end

% ==================== 子函数1：种群初始化 ====================
function X = initialization(N, dim, ub, lb)
% 种群初始化
    X = zeros(N, dim);
    for i = 1:dim
        X(:, i) = lb(i) + (ub(i) - lb(i)) * rand(N, 1);
    end
end

% ==================== 子函数2：混沌扰动非线性收缩更新 ====================
function Xnew = chaoticNonlinearUpdate(Xi, Xbest, Xprev, gamma, lambda)
% 混沌扰动非线性收缩机制 - 论文式(9)(10)(11)
    r1 = rand();
    r2 = rand();
    
    % 非线性收缩因子 Psi(r2) - 式(10)
    Psi = tanh(gamma * r2) * exp(-lambda * r2^2);
    
    % 混沌扰动因子 Phi(r1) - 式(11)
    Phi = (1 - cos(2 * pi * r1)) / (1 + log(1 + r1));
    
    % 更新规则 - 式(9)
    Xnew = Xbest + Phi * (Xbest - Xi) + Psi * (Xbest - Xprev);
end

% ==================== 子函数3：计算吸引力-斥力场 ====================
function Fi = computeForceField(Xi, Xbest, suboptimal_set, w0, t, T_max)
% 动态吸引-斥力场变异策略 - 论文式(14)
    
    % 时变权重
    wg = w0 * (1 - t / T_max);   % 吸引力权重
    wr = (t / T_max) * w0;        % 斥力权重
    
    % 对全局最优的吸引力
    dist_to_best = norm(Xbest - Xi);
    if dist_to_best > 1e-12
        F_attract = wg * (Xbest - Xi) / (dist_to_best^3);
    else
        F_attract = zeros(size(Xi));
    end
    
    % 来自次优解的斥力
    F_repel = zeros(size(Xi));
    K = size(suboptimal_set, 1);
    
    for j = 1:K
        Xj = suboptimal_set(j, :);
        dist_to_subopt = norm(Xj - Xi);
        if dist_to_subopt > 1e-12 && dist_to_subopt < 10
            F_repel = F_repel + wr * (Xj - Xi) / (dist_to_subopt^3);
        end
    end
    
    % 总力
    Fi = F_attract - F_repel;
end

% ==================== 子函数4：环境感知边界处理 ====================
function Xnew = smartReflect(X, lb, ub, fobj, epsilon)
% 环境感知边界处理策略 - 论文式(12)(13)
    
    Xnew = X;
    dim = length(X);
    eta = 0.02;  % 反弹因子
    
    for d = 1:dim
        if X(d) > ub(d)
            % 上界越界
            grad_f = approximateGradient(X, d, fobj, epsilon, ub, lb);
            Xnew(d) = ub(d) - eta * abs(X(d) - ub(d)) * sign(grad_f);
            Xnew(d) = max(lb(d), min(ub(d), Xnew(d)));
            
        elseif X(d) < lb(d)
            % 下界越界
            grad_f = approximateGradient(X, d, fobj, epsilon, ub, lb);
            Xnew(d) = lb(d) + eta * abs(lb(d) - X(d)) * sign(grad_f);
            Xnew(d) = max(lb(d), min(ub(d), Xnew(d)));
        end
    end
end

function grad = approximateGradient(X, dim_idx, fobj, epsilon, ub, lb)
% 中心差分法近似梯度 - 论文式(13)
    
    X_plus = X;
    X_minus = X;
    
    X_plus(dim_idx) = min(ub(dim_idx), X(dim_idx) + epsilon);
    X_minus(dim_idx) = max(lb(dim_idx), X(dim_idx) - epsilon);
    
    f_plus = fobj(X_plus);
    f_minus = fobj(X_minus);
    
    grad = (f_plus - f_minus) / (2 * epsilon);
end

% ==================== 子函数5：DBO各阶段更新 ====================
function X = DBO_Stages(X, N, dim, lb, ub, Best_pos, Worst_pos, t, T_max)
% 原始DBO算法的各阶段更新（滚球、繁殖、觅食、偷窃）
    
    p = 0.2;
    pNum = round(p * N);
    sNum = round(pNum / 2);
    R = 1 - t / T_max;
    
    % 滚球阶段（无障碍模式 + 障碍模式）
    for i = 1:pNum
        if rand() < 0.9
            % 无障碍模式 - 式(2)
            phi = 2 * rand() - 1;
            k = 0.1 + 0.9 * rand();
            b = 0.3;
            delta_x = abs(X(i, :) - Worst_pos);
            X(i, :) = X(i, :) + phi * k * X(max(i-1,1), :) + b * delta_x;
        else
            % 障碍模式（跳舞）- 式(3)
            theta = rand() * pi;
            tan_theta = tan(theta);
            X(i, :) = X(i, :) + tan_theta * abs(X(i, :) - X(max(i-1,1), :));
        end
    end
    
    % 繁殖阶段 - 式(4)(5)
    Lb_star = max(Best_pos * (1 - R), lb);
    Ub_star = min(Best_pos * (1 + R), ub);
    
    for i = pNum+1:pNum+sNum
        b1 = rand(1, dim);
        b2 = rand(1, dim);
        X(i, :) = Best_pos + b1 .* (X(i, :) - Lb_star) + b2 .* (X(i, :) - Ub_star);
        X(i, :) = max(min(X(i, :), Ub_star), Lb_star);
    end
    
    % 觅食阶段 - 式(6)(7)
    Lb_best = max(Best_pos * (1 - R), lb);
    Ub_best = min(Best_pos * (1 + R), ub);
    
    qNum = round((N - pNum - sNum) / 2);
    for i = pNum+sNum+1:pNum+sNum+qNum
        C1 = randn(1, dim);
        C2 = rand(1, dim);
        X(i, :) = X(i, :) + C1 .* (X(i, :) - Lb_best) + C2 .* (X(i, :) - Ub_best);
    end
    
    % 偷窃阶段 - 式(8)
    S = 0.5;
    for i = pNum+sNum+qNum+1:N
        g = randn(1, dim);
        X(i, :) = Best_pos + S * g .* (abs(X(i, :) - Best_pos) + abs(X(i, :) - Best_pos));
    end
end