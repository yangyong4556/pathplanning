%% cec2022
function [lb,ub,dim,fobj] = CEC2022(F,dim)
    lb=-100*ones(1,dim);
    ub=100*ones(1,dim);
    switch F
        case 1
            fobj = @(x) cec22_test_func(x',1);
        case 2
            fobj = @(x) cec22_test_func(x',2);
        case 3
            fobj = @(x) cec22_test_func(x',3);
        case 4
            fobj = @(x) cec22_test_func(x',4);
        case 5
            fobj = @(x) cec22_test_func(x',5);
        case 6
            fobj = @(x) cec22_test_func(x',6);
        case 7
            fobj = @(x) cec22_test_func(x',7);
        case 8
            fobj = @(x) cec22_test_func(x',8);
        case 9
            fobj = @(x) cec22_test_func(x',9);
        case 10
            fobj = @(x) cec22_test_func(x',10);
        case 11
            fobj = @(x) cec22_test_func(x',11);
        case 12
            fobj = @(x) cec22_test_func(x',12);
    end
end
