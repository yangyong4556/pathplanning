% 测试函数 (Sphere函数)
fobj = @(x) sum(x.^2);

% 参数设置
popsize = 50;       % 种群数量
MaxIter = 1000;        % 最大迭代次数
dim = 10;       % 维度
lb=-100*ones(1,dim);
ub=100*ones(1,dim);

% 运行算法  DBOPSO, IDBO, ECFDBO, DBO, PSO,DE, SSA,WOA,GA 
 %[fit, best_pos, curve] = alg(popsize, maxIter, lb, ub, dim_now, fobj);
[fit, best_pos, curve] = ECFDBO(popsize, MaxIter, lb, ub, dim, fobj);

% 显示结果
disp('最优解:');
disp(best_pos);
disp(['最优适应度值: ', num2str(fit)]);

% 绘制收敛曲线
figure;
plot(curve, 'LineWidth', 2);
xlabel('迭代次数');
ylabel('适应度值');
title('DBO算法收敛曲线');
grid on;