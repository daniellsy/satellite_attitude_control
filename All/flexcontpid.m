clear;clc;
% load para1.mat;
% Af=A1;
% J=[3.497673e6 -2.643113e4 -3.377337e1;...
%   -2.643113e4  2.629181e4 6.409160e-1;...
%    -3.377337e1  6.409160e-1 3.509507e6];
% H=[-1301.62150569525,0.212225046089404,-27.5569504229291,0.368671833268394,145.918207589118,-0.641919973583950,42.7245503633894,0.524364201414720,-1.39500767487097,21.6867966304131;
%     -12.7526242356992,0.422369279617204,29.4409184744462,-0.107357535164868,3.62427949915890,-0.198002254505846,1.90544267540469,4.07269656445618,-0.0956009085129758,1.38352518039684;
%     0.00753944788190066,1292.11636017486,0.403471370798769,-149.835224774323,-0.0180151398925330,-41.7172649653378,0.0129386177348747,-0.0558744900290940,21.7832370541292,-0.00870719151497826];

% load para.mat;
% Af=A;
% J=[   5.419990E+03  0   0;...
%  0      7.881653E+03  0;...
%   0  0        7.881658E+03];
% H=[0,1.70761842166467e-18,3.46944695195361e-18,-2.92734586571086e-18,-1.63303375024048,3.46944695195361e-18,1.51788304147971e-18,-0.539286421712874,-0.224192584459733,-6.19876433169408e-09;
%     -34.3793365768584,34.1457185760642,7.08164069589634,5.98699727969080,-2.77555756156289e-16,-3.22777758046563,-1.98384657557733,4.50850428657112e-08,6.23626673149080e-08,-2.03985710253562;
%     34.1476723588015,34.3777642647627,-5.98982651708458,7.08003834356072,0,1.98716297085105,-3.22708804670698,1.30001029163829e-07,-3.28293805994251e-08,0.747600117226127];

load para.mat;
Af=A;
J=[  5600   0  0;...
  0    5400 0;...
  0  0   4300];
H=[-19.911 0 5.311 -0.094 2.217 0 0 0 0 0;
    0.745 0.039 -0.375 1.441 -0.197 0 0 0 0 0;
    0 -20.738 0 0 0 0 0 0 0 0];

% delta=inv(J)*H*H';save delta.mat delta;
% J=(H*H')*inv(delta);
Jn=J-H*H';
Jnn=inv(Jn);
A=zeros(23,23);
mc=mat2cell(A,[3 20],[3 20]);
mc{2,2}=[zeros(10) eye(10);-Kg -Cg];
mc{2,1}=[-H';Cg*H'];
mc{1,1}=Jn\(-H*Cg*H');
mc{1,2}=[Jn\(H*Kg) Jn\(H*Cg)];
A=cell2mat(mc);
kesi=1;tn=80;
%计算固有频率
wn=10/(kesi*tn);
%%%%%%%%%%%%%%控制率设计
%参数选取与计算
k=wn^2*2;
d=2*kesi*wn;
D=d*J;
K=k*J;
% D=500*eye(3);K=30*eye(3);
base_qd=zeros(4,1);
theta=8;fii=10;psi=-6;
a1=sin(theta/2/180*pi);b1=cos(theta/2/180*pi);%theta
a2=sin(fii/2/180*pi);b2=cos(fii/2/180*pi);%fi
a3=sin(psi/2/180*pi);b3=cos(psi/2/180*pi);%psi
q0=b1*b2*b3-a1*a2*a3;
q1=b1*a2*b3-a1*b2*a3;
q2=a1*b2*b3+b1*a2*a3;
q3=a1*a2*b3+b1*b2*a3;
wbd=[0;0;0];%期望本体角速度
wb(:,1)=[0;0;0];%初始本体角速度
w(:,1)=[0;0;0];%本体相对于惯性系速度
q=[q0;q1;q2;q3];%初始四元数
qd=[1;0;0;0];%初始四元数
% innum=5676;%施加外力节点编号
% inn=3;%施加力或力矩的自由度
outnum=100;%输出节点
outn=3;%输出节点自由度
outnum4=163;%输出节点
outn4=2;%输出节点自由度
nksi=length(Af)/2;
y(:,1)=zeros(23,1);
y(1:3,1)=w(:,1);
h=0.01;i=1;
 for j=0:h:100
t(i)=j;
we=wb(:,i)-wbd;
%构造角速度叉乘矩阵
W=[0 -w(3,i) w(2,i);w(3,i) 0 -w(1,i);-w(2,i) w(1,i) 0];
%四元数误差
qe=[qd(1),qd(2),qd(3),qd(4);
    -qd(2),qd(1),qd(4),-qd(3);
    -qd(3),-qd(4),qd(1),qd(2);
    -qd(4),qd(3),-qd(2),qd(1)]*q;
%取矢量部分
qe1=qe(2:4);
fii=asin(2*(q(3)*q(4)+q(1)*q(2)));
theta=atan(2*(q(1)*q(3)-q(4)*q(2))/(q(4)^2+q(1)^2-q(2)^2-q(3)^2));
psi=atan(2*(q(1)*q(4)-q(3)*q(2))/(q(3)^2+q(1)^2-q(2)^2-q(4)^2));
sita_ctrl_eff(:,i)=[fii;theta;psi]*180/pi;

M(:,i)=W*J*w(:,i)-K*qe1-D*we;
f=Jn\M(:,i);%等效外力
% f=zeros(3,1);
F=[f;zeros(20,1)];
K1=A*y(:,i)+F;
K2=A*(y(:,i)+h*K1/2)+F;
K3=A*(y(:,i)+h*K2/2)+F;
K4=A*(y(:,i)+h*K3)+F;
y(:,i+1)=y(:,i)+h/6*(K1+2*K2+2*K3+K4);
w(:,i+1)=y(1:3,i+1);
qv=0.5*[-q(2),-q(3),-q(4);
         q(1),q(4),-q(3);
         -q(4),q(1),q(2);
         q(3),-q(2),q(1)]*w(:,i+1);
%计算星体角速度（在本体系下）
wb(:,i+1)=2*[-q(2),q(1),q(4),-q(3);
             -q(3),-q(4),q(1),q(2);
             -q(4),q(3),-q(2),q(1)]*qv;
q=q+qv*h;

qdsave(:,i)=qd;qsave(:,i)=q;
qplus(:,i)=q(1)^2+q(2)^2+q(3)^2+q(4)^2;
% eff(:,i)=H*r(11:20,:);
i=i+1;
 end
wb(:,i)=[];
y(:,i)=[];
z=fi(6*(outnum-1)+outn,:)*y(4:13,:);
plot(t,wb(1,:),'k',t,wb(2,:),'--',t,wb(3,:),'-.','LineWidth',1.2);
xlabel('t/s');ylabel('rad/s');title('本体角速度');
legend('wx','wy','wz');
% x(i)=coord(6*(outnum-1)+outn,:);
% y1(i)=coord(6*(outnum-1)+2,:);
figure(2)
plot(t,M(1,:),'k',t,M(2,:),'--',t,M(3,:),'-.','LineWidth',1.2);
xlabel('t/s');ylabel('Nm');title('姿态控制力矩');
legend('Mx','My','Mz');
figure(3)
plot(t,sita_ctrl_eff(1,:),'k',t,sita_ctrl_eff(2,:),'--',t,sita_ctrl_eff(3,:),'-.','LineWidth',1.2);
xlabel('t/s');ylabel('°');title('欧拉角变化曲线');
legend('偏航角','滚转角','俯仰角');
figure(4)
plot(t,z);
xlabel('t/s');ylabel('z/m');title('桁架末端z向位移');
% plot(t,eff);
% plot(t,qdsave);
% hold on;plot(t,qsave);
