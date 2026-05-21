function [fMin, bestX, Convergence_curve] = DBOPSO(popsize, maxIter, lb, ub, dim, fobj)
    % DBO-PSO混合优化算法
    % 输入参数:
    %   pop: 种群数量
    %   M: 最大迭代次数
    %   lb: 下界向量 (1×dim)
    %   ub: 上界向量 (1×dim)
    %   dim: 问题维度
    %   fobj: 目标函数句 柄（最小化）
    % 输出参数:
    %   fMin: 全局最优路径成本值
    %   bestX: 全局最优位置
    %   Convergence_curve: 收敛曲线(每代最优值)

    % -------------------------- 1. 初始化参数--------------------------
    % 1.1 DBO种群行为比例：滚球:繁殖:觅食:偷窃 = 6:6:7:11
    ratio_roll = 6/30;    % 滚球蜣螂比例
    ratio_repro = 6/30;   % 繁殖蜣螂比例
    ratio_forage = 7/30;  % 觅食蜣螂比例
    ratio_steal = 11/30;  % 偷窃蜣螂比例
    % 计算各群体数量（确保总和为pop）
    N_roll = round(popsize * ratio_roll);
    N_repro = round(popsize * ratio_repro);
    N_forage = round(popsize * ratio_forage);
    N_steal = popsize - N_roll - N_repro - N_forage;  % 最后调整，避免总数偏差

    % 1.2 PSO核心参数
    c1 = 2;          % 局部学习因子
    c2 = 2;          % 全局学习因子
    c3 = 0.5;        % DBO位置权重（混合系数）
    c4 = 0.5;        % PSO速度权重（混合系数）
    % 速度边界（与位置边界匹配，避免速度溢出）
    Vmax = ub - lb;
    Vmin = -Vmax;

    % -------------------------- 2. 种群与状态初始化（融合DBO+PSO）--------------------------
    % 2.1 使用Kent混沌映射初始化位置（替换原来的随机初始化）
    x = kent_initialization(popsize, dim, ub, lb);
    
    % 2.2 初始化速度（PSO核心变量）
    V = zeros(popsize, dim);
    for i = 1:dim
        V(:, i) = Vmin(i) + (Vmax(i) - Vmin(i)) .* rand(popsize, 1);
    end
    % 2.3 初始化个体最优（lbest，PSO）与全局最优（gbest，DBO+PSO共享）
    pX = x;                          % 个体最优位置
    fit = zeros(1, popsize);             % 预分配适应度数组
    for i = 1:popsize
        fit(i) = fobj(x(i, :));      % 计算初始适应度
    end
    pFit = fit;                      % 个体最优适应度
    [fMin, bestI] = min(fit);
    bestX = x(bestI, :);             % 全局最优位置

    % 2.4 初始化收敛曲线
    Convergence_curve = zeros(1, maxIter);

    % -------------------------- 3. 主迭代循环--------------------------
    for t = 1:maxIter
        % 迭代衰减系数R（R=1-t/M，控制繁殖/觅食区域大小）
        R = 1 - t / maxIter;

        % -------------------------- 3.1 种群划分（按6:6:7:11比例，随机分配索引）--------------------------
        idx_all = randperm(popsize);
        idx_roll = idx_all(1:N_roll);        % 滚球群体索引
        idx_repro = idx_all(N_roll+1:N_roll+N_repro);  % 繁殖群体索引
        idx_forage = idx_all(N_roll+N_repro+1:N_roll+N_repro+N_forage);  % 觅食群体索引
        idx_steal = idx_all(N_roll+N_repro+N_forage+1:end);  % 偷窃群体索引
        % 提取各群体位置与速度
        x_roll = x(idx_roll, :);    V_roll = V(idx_roll, :);    pX_roll = pX(idx_roll, :);
        x_repro = x(idx_repro, :);  V_repro = V(idx_repro, :);  pX_repro = pX(idx_repro, :);
        x_forage = x(idx_forage, :);V_forage = V(idx_forage, :);pX_forage = pX(idx_forage, :);
        x_steal = x(idx_steal, :);  V_steal = V(idx_steal, :);  pX_steal = pX(idx_steal, :);

        % -------------------------- 3.2 滚球行为更新（无障碍+有障碍）--------------------------
        if N_roll > 0
            for i = 1:N_roll
                % PSO速度更新（PSO速度公式：v = v + c1r1(lbest-x) + c2r2(gbest-x)）
                r1 = rand(1, dim);
                r2 = rand(1, dim);
                V_roll(i, :) = V_roll(i, :) + c1*r1.*(pX_roll(i, :) - x_roll(i, :)) ...
                            + c2*r2.*(bestX - x_roll(i, :));
                V_roll(i, :) = Bounds(V_roll(i, :), Vmin, Vmax);  % 速度边界检查

                % 随机选择滚球模式（无障碍/有障碍）
                if rand() < 0.5
                    % （1）无障碍模式（太阳导航）
                    k = 0.01 + 0.19*rand();  % 偏转系数k∈(0,0.2]
                    a = 2*round(rand()) - 1;  % 方向系数（±1，10%概率偏离，文档隐含）
                    x_dbo = x_roll(i, :) + k*abs(x_roll(i, :) - bestX) + a*0.1*x_roll(i, :);
                else
                    % （2）有障碍模式（文档2.2.1.2节：切线跳舞）
                    theta = pi*rand();  % 角度θ∈[0,π]
                    if theta == 0 || theta == pi  % 特殊角度不移动
                        x_dbo = x_roll(i, :);
                    else
                        x_dbo = x_roll(i, :) + tan(theta)*abs(x_roll(i, :) - pX_roll(i, :));
                    end
                end

                % DBO-PSO混合位置更新（x = c3*x_dbo + c4*V）
                x_roll(i, :) = c3*x_dbo + c4*V_roll(i, :);
                x_roll(i, :) = Bounds(x_roll(i, :), lb, ub);  % 位置边界检查
                % 更新适应度
                fit(idx_roll(i)) = fobj(x_roll(i, :));
            end
            % 回写滚球群体数据
            x(idx_roll, :) = x_roll;
            V(idx_roll, :) = V_roll;
        end

        % -------------------------- 3.3 繁殖行为更新--------------------------
        if N_repro > 0
            for i = 1:N_repro
                % PSO速度更新
                r1 = rand(1, dim);
                r2 = rand(1, dim);
                V_repro(i, :) = V_repro(i, :) + c1*r1.*(pX_repro(i, :) - x_repro(i, :)) ...
                              + c2*r2.*(bestX - x_repro(i, :));
                V_repro(i, :) = Bounds(V_repro(i, :), Vmin, Vmax);

                % 繁殖产卵区域计算（b1=max(gbest*(1-R),lb), bu=min(gbest*(1+R),ub)）
                b1 = max(bestX.*(1 - R), lb);
                bu = min(bestX.*(1 + R), ub);
                % DBO繁殖位置更新（x = gbest + b1*(x-b1) + b2*(x-bu)）
                b1_rand = rand(1, dim);  % 1×D随机向量
                b2_rand = rand(1, dim);
                x_dbo = bestX + b1_rand.*(x_repro(i, :) - b1) + b2_rand.*(x_repro(i, :) - bu);

                % 混合位置更新
                x_repro(i, :) = c3*x_dbo + c4*V_repro(i, :);
                x_repro(i, :) = Bounds(x_repro(i, :), lb, ub);
                fit(idx_repro(i)) = fobj(x_repro(i, :));
            end
            x(idx_repro, :) = x_repro;
            V(idx_repro, :) = V_repro;
        end

        % -------------------------- 3.4 觅食行为更新--------------------------
        if N_forage > 0
            for i = 1:N_forage
                % PSO速度更新
                r1 = rand(1, dim);
                r2 = rand(1, dim);
                V_forage(i, :) = V_forage(i, :) + c1*r1.*(pX_forage(i, :) - x_forage(i, :)) ...
                              + c2*r2.*(bestX - x_forage(i, :));
                V_forage(i, :) = Bounds(V_forage(i, :), Vmin, Vmax);

                % 觅食区域计算（b1=max(lbest*(1-R),lb), bu=min(lbest*(1+R),ub)）
                b1 = max(pX_forage(i, :).*(1 - R), lb);
                bu = min(pX_forage(i, :).*(1 + R), ub);
                % DBO觅食位置更新（x = x + C1*(x-b1) + C2*(x-bu)）
                C1 = randn(1, dim);  % 正态分布N(0,1)
                C2 = rand(1, dim);   % [0,1]随机向量
                x_dbo = x_forage(i, :) + C1.*(x_forage(i, :) - b1) + C2.*(x_forage(i, :) - bu);

                % 混合位置更新
                x_forage(i, :) = c3*x_dbo + c4*V_forage(i, :);
                x_forage(i, :) = Bounds(x_forage(i, :), lb, ub);
                fit(idx_forage(i)) = fobj(x_forage(i, :));
            end
            x(idx_forage, :) = x_forage;
            V(idx_forage, :) = V_forage;
        end

        % -------------------------- 3.5 偷窃行为更新--------------------------
        if N_steal > 0
            for i = 1:N_steal
                % PSO速度更新
                r1 = rand(1, dim);
                r2 = rand(1, dim);
                V_steal(i, :) = V_steal(i, :) + c1*r1.*(pX_steal(i, :) - x_steal(i, :)) ...
                              + c2*r2.*(bestX - x_steal(i, :));
                V_steal(i, :) = Bounds(V_steal(i, :), Vmin, Vmax);

                % DBO偷窃位置更新（文档2.2.4节：x = lbest + S*g*(|x-gbest| + |x-lbest|)）
                S = 2*round(rand()) - 1;    % 符号函数
                g = rand(1, dim);            % [0,1]随机向量
                abs_term = abs(x_steal(i, :) - bestX) + abs(x_steal(i, :) - pX_steal(i, :));
                x_dbo = pX_steal(i, :) + S*g.*abs_term;

                % 混合位置更新
                x_steal(i, :) = c3*x_dbo + c4*V_steal(i, :);
                x_steal(i, :) = Bounds(x_steal(i, :), lb, ub);
                fit(idx_steal(i)) = fobj(x_steal(i, :));
            end
            x(idx_steal, :) = x_steal;
            V(idx_steal, :) = V_steal;
        end

        % -------------------------- 3.6 最优解更新（个体最优+全局最优）--------------------------
        for i = 1:popsize
            % 更新个体最优（PSO lbest）
            if fit(i) < pFit(i)
                pFit(i) = fit(i);
                pX(i, :) = x(i, :);
            end
            % 更新全局最优（DBO+PSO gbest）
            if pFit(i) < fMin
                fMin = pFit(i);
                bestX = pX(i, :);
            end
        end

        % -------------------------- 3.7 记录收敛曲线--------------------------
        Convergence_curve(t) = fMin;
        
        % 显示迭代信息
        % if mod(t, 50) == 0 || t == 1
        %     fprintf('迭代次数 %d, 最优综合路径成本 ： %.6f\n', t, fMin);
        % end
    end
end

% Kent混沌初始化函数
function Positions = kent_initialization(SearchAgents_no, dim, ub, lb)
    Positions = zeros(SearchAgents_no, dim);
    % 改进：使用多个初始值生成混沌序列，增强多样性
    init_values = [0.2, 0.4, 0.6, 0.8];  % 多初始值
    x = init_values(randi(length(init_values)));  % 随机选择初始值

    for i = 1:SearchAgents_no
        % 改进Kent混沌映射公式，扩大扰动范围
        if x <= 0.4
             x = 3 * x ;  % 更陡峭的上升段
        else
           x = 2 * (1 - x);  % 更陡峭的下降段
        end
        % 增强混沌序列的随机性（原代码扰动太小）
        chaos = rand(1, dim) + 0.1 * x;  % 扰动系数从0.01增至0.1
        [~, order] = sort(chaos);
        % 边界映射保持，但确保覆盖整个搜索空间
        Positions(i,:) = lb + (ub - lb) .* (order - 1) / (dim - 1);
    end
end

% 边界处理函数（截断法，与原函数兼容）
function x = Bounds(x, lb, ub)
    x = max(x, lb);
    x = min(x, ub);
end