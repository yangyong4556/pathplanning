%  ref paper: Whale Optimization Algorithm (WOA)        
% lb is the lower bound: lb=[lb_1,lb_2,...,lb_d]
% up is the uppper bound: ub=[ub_1,ub_2,...,ub_d]
% dim is the number of variables (dimension of the problem)

function [lb,ub,dim,fobj] = Get_Classical_23_Functions(F)
switch F
    case 'F1'
        fobj = @F1;
        lb=-100;
        ub=100;
        dim=30;
    case 'F2'
        fobj = @F2;
        lb=-10;
        ub=10;
        dim=30;
    case 'F3'
        fobj = @F3;
        lb=-100;
        ub=100;
        dim=30;
    case 'F4'
        fobj = @F4;
        lb=-100;
        ub=100;
        dim=30;
    case 'F5'
        fobj = @F5;
        lb=-30;
        ub=30;
        dim=30;
    case 'F6'
        fobj = @F6;
        lb=-100;
        ub=100;
        dim=30;
    case 'F7'
        fobj = @F7;
        lb=-1.28;
        ub=1.28;
        dim=30;
    case 'F8'
        fobj = @F8;
        lb=-500;
        ub=500;
        dim=30;
    case 'F9'
        fobj = @F9;
        lb=-5.12;
        ub=5.12;
        dim=30;
    case 'F10'
        fobj = @F10;
        lb=-32;
        ub=32;
        dim=30;
    case 'F11'
        fobj = @F11;
        lb=-600;
        ub=600;
        dim=30;
    case 'F12'
        fobj = @F12;
        lb=-50;
        ub=50;
        dim=30;
    case 'F13'
        fobj = @F13;
        lb=-50;
        ub=50;
        dim=30;
    case 'F14'
        fobj = @F14;
        lb=-65.536;
        ub=65.536;
        dim=2;
    case 'F15'
        fobj = @F15;
        lb=-5;
        ub=5;
        dim=4;
    case 'F16'
        fobj = @F16;
        lb=-5;
        ub=5;
        dim=2;
    case 'F17'
        fobj = @F17;
        lb=[-5,0];
        ub=[10,15];
        dim=2;
    case 'F18'
        fobj = @F18;
        lb=-2;
        ub=2;
        dim=2;
    case 'F19'
        fobj = @F19;
        lb=0;
        ub=1;
        dim=3;
        
    case 'F20'
        fobj = @F20;
        lb=0;
        ub=1;
        dim=6;     
    case 'F21'
        fobj = @F21;
        lb=0;
        ub=10;
        dim=4;    
    case 'F22'
        fobj = @F22;
        lb=0;
        ub=10;
        dim=4;    
    case 'F23'
        fobj = @F23;
        lb=0;
        ub=10;
        dim=4; 
    case 'tcSpringDesign'  
        fobj = @tcSpringDesign;
        dim = 3;
        lb = [0.05 0.25 2.0];
        ub = [2.0 1.30 15.0];
    case 'wBeamDesign' 
        fobj = @wBeamDesign;
        dim = 4;
        lb = [0.1 0.1 0.1 0.1];
        ub = [2 10 10 2];
    case 'pVesselDesign' 
        fobj = @pVesselDesign;
        dim = 4;
        lb =[0 0 10 10];    
        %lb =[1 1 10 10];  % ref80
        ub =[99 99 200 200];
end

end

% F1, minValue=0
function o = F1(x)
o=sum(x.^2);
end

% F2, minValue=0
function o = F2(x)
o=sum(abs(x))+prod(abs(x));
end

% F3, minValue=0
function o = F3(x)
dim=size(x,2);
o=0;
for i=1:dim
    o=o+sum(x(1:i))^2;
end
end

% F4, minValue=0
function o = F4(x)
o=max(abs(x));
end

% F5, minValue=0
function o = F5(x)
dim=size(x,2);
o=sum(100*(x(2:dim)-(x(1:dim-1).^2)).^2+(x(1:dim-1)-1).^2);
end

% F6, minValue=0
function o = F6(x)
o=sum(abs((x+.5)).^2);
end

% F7, minValue=0
function o = F7(x)
dim=size(x,2);
o=sum([1:dim].*(x.^4))+rand;
end

% F8，, minValue=-12569.5
function o = F8(x)
o=sum(-x.*sin(sqrt(abs(x))));
end

% F9, minValue=0
function o = F9(x)
dim=size(x,2);
o=sum(x.^2-10*cos(2*pi.*x))+10*dim;
end

% F10, minValue=0
function o = F10(x)
dim=size(x,2);
o=-20*exp(-.2*sqrt(sum(x.^2)/dim))-exp(sum(cos(2*pi.*x))/dim)+20+exp(1);
end

% F11, minValue=0
function o = F11(x)
dim=size(x,2);
o=sum(x.^2)/4000-prod(cos(x./sqrt([1:dim])))+1;
end

% F12, minValue=0
function o = F12(x)
dim=size(x,2);
o=(pi/dim)*(10*((sin(pi*(1+(x(1)+1)/4)))^2)+sum((((x(1:dim-1)+1)./4).^2).*...
(1+10.*((sin(pi.*(1+(x(2:dim)+1)./4)))).^2))+((x(dim)+1)/4)^2)+sum(Ufun(x,10,100,4));
end

% F13, minValue=0
function o = F13(x)
dim=size(x,2);
o=.1*((sin(3*pi*x(1)))^2+sum((x(1:dim-1)-1).^2.*(1+(sin(3.*pi.*x(2:dim))).^2))+...
((x(dim)-1)^2)*(1+(sin(2*pi*x(dim)))^2))+sum(Ufun(x,5,100,4));
end

% F14, minValue=1
function o = F14(x)
aS=[-32 -16 0 16 32 -32 -16 0 16 32 -32 -16 0 16 32 -32 -16 0 16 32 -32 -16 0 16 32;,...
-32 -32 -32 -32 -32 -16 -16 -16 -16 -16 0 0 0 0 0 16 16 16 16 16 32 32 32 32 32];
for j=1:25
    bS(j)=sum((x'-aS(:,j)).^6);
end
o=(1/500+sum(1./([1:25]+bS))).^(-1);
end

% F15, minValue=0.0003075
function o = F15(x)
aK=[.1957 .1947 .1735 .16 .0844 .0627 .0456 .0342 .0323 .0235 .0246];
bK=[.25 .5 1 2 4 6 8 10 12 14 16];bK=1./bK;
o=sum((aK-((x(1).*(bK.^2+x(2).*bK))./(bK.^2+x(3).*bK+x(4)))).^2);
end

% F16, minValue=-1.0316285
function o = F16(x)
o=4*(x(1)^2)-2.1*(x(1)^4)+(x(1)^6)/3+x(1)*x(2)-4*(x(2)^2)+4*(x(2)^4);
end

% F17, minValue=0.398
function o = F17(x)
o=(x(2)-(x(1)^2)*5.1/(4*(pi^2))+5/pi*x(1)-6)^2+10*(1-1/(8*pi))*cos(x(1))+10;
end

% F18, minValue=3
function o = F18(x)
o=(1+(x(1)+x(2)+1)^2*(19-14*x(1)+3*(x(1)^2)-14*x(2)+6*x(1)*x(2)+3*x(2)^2))*...
    (30+(2*x(1)-3*x(2))^2*(18-32*x(1)+12*(x(1)^2)+48*x(2)-36*x(1)*x(2)+27*(x(2)^2)));
end

% F19, minValue=-3.86
function o = F19(x)
aH=[3 10 30;.1 10 35;3 10 30;.1 10 35];cH=[1 1.2 3 3.2];
pH=[.3689 .117 .2673;.4699 .4387 .747;.1091 .8732 .5547;.03815 .5743 .8828];
o=0;
for i=1:4
    o=o-cH(i)*exp(-(sum(aH(i,:).*((x-pH(i,:)).^2))));
end
end

% F20, minValue=-3.32
function o = F20(x)
aH=[10 3 17 3.5 1.7 8;.05 10 17 .1 8 14;3 3.5 1.7 10 17 8;17 8 .05 10 .1 14];
cH=[1 1.2 3 3.2];
pH=[.1312 .1696 .5569 .0124 .8283 .5886;.2329 .4135 .8307 .3736 .1004 .9991;...
.2348 .1415 .3522 .2883 .3047 .6650;.4047 .8828 .8732 .5743 .1091 .0381];
o=0;
for i=1:4
    o=o-cH(i)*exp(-(sum(aH(i,:).*((x-pH(i,:)).^2))));
end
end

% F21, minValue=-10
function o = F21(x)
aSH=[4 4 4 4;1 1 1 1;8 8 8 8;6 6 6 6;3 7 3 7;2 9 2 9;5 5 3 3;8 1 8 1;6 2 6 2;7 3.6 7 3.6];
cSH=[.1 .2 .2 .4 .4 .6 .3 .7 .5 .5];

o=0;
for i=1:5
    o=o-((x-aSH(i,:))*(x-aSH(i,:))'+cSH(i))^(-1);
end
end

% F22, minValue=-10
function o = F22(x)
aSH=[4 4 4 4;1 1 1 1;8 8 8 8;6 6 6 6;3 7 3 7;2 9 2 9;5 5 3 3;8 1 8 1;6 2 6 2;7 3.6 7 3.6];
cSH=[.1 .2 .2 .4 .4 .6 .3 .7 .5 .5];
o=0;
for i=1:7
    o=o-((x-aSH(i,:))*(x-aSH(i,:))'+cSH(i))^(-1);
end
end

% F23, minValue=-10
function o = F23(x)
aSH=[4 4 4 4;1 1 1 1;8 8 8 8;6 6 6 6;3 7 3 7;2 9 2 9;5 5 3 3;8 1 8 1;6 2 6 2;7 3.6 7 3.6];
cSH=[.1 .2 .2 .4 .4 .6 .3 .7 .5 .5];
o=0;
for i=1:10
    o=o-((x-aSH(i,:))*(x-aSH(i,:))'+cSH(i))^(-1);
end
end

function o=Ufun(x,a,k,m)
o=k.*((x-a).^m).*(x>a)+k.*((-x-a).^m).*(x<(-a));
end

% 4.1 Tension/Compression Spring Design 
function o = tcSpringDesign(x)
o1=(x(3)+2)*x(2)*(x(1)^2);
penalty_factor = 10e20;%0.1*o1; % 按需修改,10%原值
g1 = 1 - ((x(2)^3)*x(3))/(71785*(x(1)^4));
g2 =(4*x(2)^2-x(1)*x(2))/(12566*(x(2)*x(1)^3-x(1)^4))+1/(5108*x(1)^2)-1;
%g2 =(4*x(2)^2-x(1)*x(2))/(12566*(x(2)*x(1)^3-x(1)^4))+1/(5108*x(1)^2);  % error in paper.
g3 = 1-(140.45*x(1))/((x(2)^2)*x(3));
g4 = (x(1)+x(2))/1.5-1;
penalty_1 = penalty_factor*(max(0,g1))^2; % g1的惩罚项
penalty_2 = penalty_factor*(max(0,g2))^2; % g2的惩罚项
penalty_3 = penalty_factor*(max(0,g3))^2; % g3的惩罚项
penalty_4 = penalty_factor*(max(0,g4))^2; % g4的惩罚项
o  = o1 + penalty_1+penalty_2+penalty_3+penalty_4;
end

%4.2   wBeamDesign
function O = wBeamDesign(x)
P = 6000; L = 14; E = 30 * 1e6; G = 12 * 1e6; tao_max = 13600; sigma_max = 30000; delta_max = 0.25;    
h = x(1); l = x(2); t = x(3); b = x(4);
sigma = (6 * P * L) / (h * t^2);
delta = (6 * P * L^3) / (E * t^2 * h);
%    2016: Pc = ((4.013 * E * sqrt((t^2 * h^6) / 36)) / L^2 )* (1 - (t / 2 * L) * sqrt(E / (4 * G)));
%    2007: Pc=64746.022 * (1-0.0282346 * t ) * t * b^4
Pc=64746.022 * (1-0.0282346 * t ) * t * b^4
tao = calculate_tao(x);
g7= 1.10471 * h^2 + 0.04811 * t * b * (14.0+L)

% 约束条件判断
if tao > tao_max || sigma > sigma_max || delta > delta_max || h > l || P > Pc || h < 0.125||  g7 > 5.0
    O = 1e10; % 违反约束，赋予大的成本值
else
    O = 1.10471 * h^2 * l + 0.04811 * t * b * (14 + l);
end
end

%4.2wBeamDesign辅助函数
function tao = calculate_tao(x)
P = 6000; L = 14; E = 30 * 1e6; G = 12 * 1e6;
h = x(1); l = x(2); t = x(3); b = x(4);
M = P * (L + h / 2);
J = 2 * (sqrt(2) * h * l * ((l^2 / 4) + ((h + t) / 2)^2));
R = sqrt((l^2 / 4) + ((h + t) / 2)^2);
tao_p = P / (sqrt(2) * h * l);
tao_pp = M * R / J;
tao = sqrt(tao_p^2 + 2 * tao_p * tao_pp * l / (2 * R) + tao_pp^2);
end



% 4.3 Pressure vessel design
function o = pVesselDesign(x)
o1=0.6224*x(1)*x(3)*x(4)+1.7781*x(2)*x(3)^2+3.1661*x(1)^2*x(4)+19.84*x(1)^2*x(3);
g1 = -x(1)+0.0193*x(3);
g2 =-x(2)+0.00954*x(3);  % bug in 2016 paper; not x(3)
g3 = -pi*x(3)^2*x(4)-4.0*pi*x(3)^3/3.0+1296000;
g4 = x(4)-240;
if g1<=0 && g2<=0 && g3<=0 && g4<=0
    o=o1;
else
    penalty_factor = 10e200;%0.1*o1; % 按需修改,10%原值
    penalty_1 = penalty_factor*(max(0,g1))^2; % g1的惩罚项
    penalty_2 = penalty_factor*(max(0,g2))^2; % g2的惩罚项
    penalty_3 = penalty_factor*(max(0,g3))^2; % g3的惩罚项
    penalty_4 = penalty_factor*(max(0,g4))^2; % g4的惩罚项
    %o  = o1 + penalty_1+penalty_2+penalty_3+penalty_4;
    o=inf;
end
end