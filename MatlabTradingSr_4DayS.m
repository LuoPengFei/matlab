function MatlabTradingDemo
% MATLAB�������ײ��Է�����һ���򵥾��߽���ϵͳ
% by LiYang 2014/05/01 farutliyang@foxmail.com

%% ��չ����ռ䡢�����
clc;clear;
close all;
format compact;
%% ����������� : ��ָ����IF888 2011��ȫ������
rb000 =load('sr000_day.csv');
date = rb000(200:300, 1);
IFdata = rb000(200:300, 5);
Opendata = rb000(200:300, 2);
Highdata = rb000(200:300, 3);

%% ѡ�����5�վ��ߡ�����20�վ���
ShortLen = 5;
LongLen = 20;
[MA5, MA20] = movavg(IFdata, ShortLen, LongLen);
MA5(1:ShortLen-1) = IFdata(1:ShortLen-1);
MA20(1:LongLen-1) = IFdata(1:LongLen-1);

Count = 4;


scrsz = get(0,'ScreenSize');
figure('Position',[scrsz(3)*1/4 scrsz(4)*1/6 scrsz(3)*4/5 scrsz(4)]*3/4);
plot(IFdata,'b','LineStyle','-','LineWidth',1.5);
hold on;
plot(MA5,'r','LineStyle','--','LineWidth',1.5);
plot(MA20,'k','LineStyle','-.','LineWidth',1.5);
grid on;
legend('IF888','MA5','MA20','Location','Best');
title(num2str(IFdata(1)),'FontWeight', 'Bold');
hold on;
%% ���׹��̷���

% ��λ Pos = 1 ��ͷ1��; Pos = 0 �ղ�; Pos = -1 ��ͷһ��
Pos = zeros(length(IFdata),1);
% ��ʼ�ʽ�
InitialE = 1e4;
% �������¼
ReturnD = zeros(length(IFdata),1);
% ��ָ����
scale = 10;%300;


PreviousPos = zeros(Count,1);

lastPrice = 0;
for t = Count+1:length(IFdata)
    
    PreviousPos = Opendata(t-Count:t-1);
    OpenHighest = max(PreviousPos);
    PreviousPos = Highdata(t-Count:t-1);
    HighLowest = min(PreviousPos);
    
    if Pos(t-1) == 0
        if Opendata(t)>OpenHighest
            Pos(t) = 1;
            text(t,OpenHighest,' \leftarrow����1��','FontSize',8);
            plot(t,OpenHighest,'ro','markersize',8);
            %ReturnD(t) = (IFdata(t)-IFdata(t-1))*scale;
            fprintf(1,'%d ����1�� %d\n' ,t,Opendata(t));
            lastPrice = Opendata(t);
            continue;
        end
        
        if Highdata(t)<HighLowest
            Pos(t) = -1;
            text(t,HighLowest,' \leftarrow����1��','FontSize',8);
            plot(t,HighLowest,'rd','markersize',8);
            %ReturnD(t) = (IFdata(t-1)-IFdata(t))*scale;
            fprintf(1,'%d ����1�� %\n' ,t,Highdata(t));
            lastPrice = Highdata(t);
            continue;
        end
    end
    
    if Pos(t-1) == 1
        if Highdata(t)<HighLowest
            Pos(t) = -1;
            ReturnD(t) = (IFdata(t-1)-IFdata(t))*scale;
            text(t,Highdata(t),' \leftarrowƽ�࿪��1��','FontSize',8);
            plot(t,Highdata(t),'rd','markersize',8);
            %fprintf(1,'%d ƽ�࿪�� %d %d\n' ,t,Lowest,Lowest - lastPrice);
            fprintf(1,'%d\n' ,Highdata(t) - lastPrice);
            lastPrice = Highdata(t);
            continue;
        end
    end
    
     if Pos(t-1) == -1
        if Opendata(t)>OpenHighest
            Pos(t) = 1;
            ReturnD(t) = (IFdata(t)-IFdata(t-1))*scale;
            text(t,Opendata(t),' \leftarrowƽ�տ���1��','FontSize',8);
            plot(t,Opendata(t),'ro','markersize',8);    
            %fprintf(1,'%d ƽ�տ��� %d %d\n' ,t,Highest,lastPrice - Highest);
            fprintf(1,'%d\n' ,lastPrice - Opendata(t));
            lastPrice = Opendata(t);

            continue;
        end
    end
    
%     % �����ź� : 5�վ����ϴ�20�վ���
%     %SignalBuy = MA5(t)>MA5(t-1) && MA5(t)>MA20(t) && MA5(t-1)>MA20(t-1) && MA5(t-2)<=MA20(t-2);
%     %SignalBuy = IFdata(t) > MA20(t);
%     SignalBuy = Highdata
%     % �����ź� : 5�վ�������20�վ���
%     %SignalSell = MA5(t)<MA5(t-1) && MA5(t)<MA20(t) && MA5(t-1)<MA20(t-1) && MA5(t-2)>=MA20(t-2);
%     %SignalSell = MA20(t) > IFdata(t);
%     % ��������
%     if SignalBuy == 1
%         % �ղֿ���ͷ1��
%         if Pos(t-1) == 0
%             Pos(t) = 1;
%             text(t,IFdata(t),' \leftarrow����1��','FontSize',8);
%             plot(t,IFdata(t),'ro','markersize',8);
%             continue;
%         end
%         % ƽ��ͷ����ͷ1��
%         if Pos(t-1) == -1
%             Pos(t) = 1;
%             ReturnD(t) = (IFdata(t-1)-IFdata(t))*scale;
%             text(t,IFdata(t),' \leftarrowƽ�տ���1��','FontSize',8);
%             plot(t,IFdata(t),'ro','markersize',8);           
%             continue;
%         end
%     end
%     
%     % ��������
%     if SignalSell == 1
%         % �ղֿ���ͷ1��
%         if Pos(t-1) == 0
%             Pos(t) = -1;
%             text(t,IFdata(t),' \leftarrow����1��','FontSize',8);
%             plot(t,IFdata(t),'rd','markersize',8);
%             continue;
%         end
%         % ƽ��ͷ����ͷ1��
%         if Pos(t-1) == 1
%             Pos(t) = -1;
%             ReturnD(t) = (IFdata(t)-IFdata(t-1))*scale;
%             text(t,IFdata(t),' \leftarrowƽ�࿪��1��','FontSize',8);
%             plot(t,IFdata(t),'rd','markersize',8);
%             continue;
%         end
%     end
    
    % ÿ��ӯ������
    if Pos(t-1) == 1
        Pos(t) = 1;
        ReturnD(t) = (IFdata(t)-IFdata(t-1))*scale;
    end
    if Pos(t-1) == -1
        Pos(t) = -1;
        ReturnD(t) = (IFdata(t-1)-IFdata(t))*scale;
    end
    if Pos(t-1) == 0
        Pos(t) = 0;
        ReturnD(t) = 0;
    end    
    
    % ���һ��������������гֲ֣�����ƽ��
    if t == length(IFdata) && Pos(t-1) ~= 0
        if Pos(t-1) == 1
            Pos(t) = 0;
            ReturnD(t) = (IFdata(t)-IFdata(t-1))*scale;
            text(t,IFdata(t),' \leftarrowƽ��1��','FontSize',8);
            plot(t,IFdata(t),'rd','markersize',8);
        end
        if Pos(t-1) == -1
            Pos(t) = 0;
            ReturnD(t) = (IFdata(t-1)-IFdata(t))*scale;
            text(t,IFdata(t),' \leftarrowƽ��1��','FontSize',8);
            plot(t,IFdata(t),'ro','markersize',8);
        end
    end
    
end
%% �ۼ�����
ReturnCum = cumsum(ReturnD);
ReturnCum = ReturnCum + InitialE;
%% �������س�
MaxDrawD = zeros(length(IFdata),1);
for t = LongLen:length(IFdata)
    C = max( ReturnCum(1:t) );
    if C == ReturnCum(t)
        MaxDrawD(t) = 0;
    else
        MaxDrawD(t) = (ReturnCum(t)-C)/C;
    end
end
MaxDrawD = abs(MaxDrawD);
%% ͼ��չʾ
scrsz = get(0,'ScreenSize');
figure('Position',[scrsz(3)*1/4 scrsz(4)*1/6 scrsz(3)*4/5 scrsz(4)]*3/4);
subplot(3,1,1);
plot(ReturnCum);
grid on;
axis tight;
title('��������','FontWeight', 'Bold');

subplot(3,1,2);
plot(Pos,'LineWidth',1.8);
grid on;
axis tight;
title('��λ','FontWeight', 'Bold');

subplot(3,1,3);
plot(MaxDrawD);
grid on;
axis tight;
title(['���س�����ʼ�ʽ�',num2str(InitialE/1e4),'��'],'FontWeight', 'Bold');
