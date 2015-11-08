%% ��飺ϵͳ���ڲ���ͨ��ԭ����һ������׷��ϵͳ��
%  �볡������
%    ROC����0�Ҽ۸�ͻ�Ʋ��ִ��Ϲ�Ϳ���֣�
%    ROCС��0�Ҽ۸���Ʋ��ִ��¹�Ϳ��ղ֣�
%  �ؼ�������
%	 �����������Slip
%	 ���ִ���������BollLength��
%    ���ִ���׼��ı���Offset;
%    ROC��������ROCLength��
%    ����ֹ���㷨��������ExitLength;


%% --��ȡ����--

% user=input('���������ݿ��û�����','s');
% password=input('���������ݿ����룺','s');
% commodity=input('��������Ʒ(��RB888)��','s');
% Freq=input('����������(��M5)��','s');
% conna=database('Futures_matlab',user,password);
% cursor=exec(conna,strcat('select * from ',32,commodity,'_',Freq));%32��ָ�ո��ASCLL��
% cursor=fetch(cursor);
% data=cursor.Data;

commodity = 'RB888';
Freq = 'M15';
%load data.mat;
data =load('rb000_day.csv');
data_1min = load('rb000_dayfivemin.csv');

Date=x2mdate(data(:,1),0);    %����ʱ��
Open=data(:,2);               %���̼�
High=data(:,3);               %��߼�
Low=data(:,4);                %��ͼ�
Close=data(:,5);              %���̼�
Volume=data(:,6);             %�ɽ���
OpenInterest=data(:,7);       %�ֲ���
Date_1min = x2mdate(data_1min(:,1),0);
%Date_1min=datenum(data_1min(:,1),'yyyymmddHHMM'); 
High_1min = data_1min(:,3);
Low_1min = data_1min(:,4);
Close_1min = data_1min(:,5);
%% --���������������--

%���Բ���
Slip=2;                                      %����
%BollLength=50;                               %�����߳���
%Offset=1.25;                                 %�����߱�׼���
%ROCLength=30;                                %ROC��������
ShortLen = 10;
LongLen = 20;

%Ʒ�ֲ���
MinMove=1;                                    %��Ʒ����С�䶯��
PriceScale=1;                                 %��Ʒ�ļ�����λ
TradingUnits=10;                              %���׵�λ
Lots=1;                                       %��������
MarginRatio=0.07;                             %��֤����
TradingCost=0.0003;                           %���׷�����Ϊ�ɽ��������֮��
RiskLess=0.035;                               %�޷���������(�������ձ���ʱ��Ҫ)

%% --�������--

%���Ա���
%UpperLine=zeros(length(data),1);               %�Ϲ�
%LowerLine=zeros(length(data),1);               %�¹�
%MidLine=zeros(length(data),1);                 %�м���
%Std=zeros(length(data),1);                     %��׼������
%RocValue=zeros(length(data),1);                %ROCֵ


%���׼�¼����
MyEntryPrice=zeros(length(data_1min),1);            %�����۸�
MarketPosition=0;                              %��λ״̬��-1��ʾ���п�ͷ��0��ʾ�޳ֲ֣�1��ʾ���ж�ͷ
pos=zeros(length(data_1min),1);                     %��¼��λ�����-1��ʾ���п�ͷ��0��ʾ�޳ֲ֣�1��ʾ���ж�ͷ
Type=zeros(length(data_1min),1);                    %�������ͣ�1��ʾ��ͷ��-1��ʾ��ͷ
OpenPosPrice=zeros(length(data_1min),1);            %��¼���ּ۸�
ClosePosPrice=zeros(length(data_1min),1);           %��¼ƽ�ּ۸�
OpenPosNum=0;                                  %���ּ۸����
ClosePosNum=0;                                 %ƽ�ּ۸����
OpenDate=zeros(length(data_1min),1);            %����ʱ��
CloseDate=zeros(length(data_1min),1);           %ƽ��ʱ��
NetMargin=zeros(length(data_1min),1);               %����
CumNetMargin=zeros(length(data_1min),1);            %�ۼƾ���
RateOfReturn=zeros(length(data_1min),1);            %������
CumRateOfReturn=zeros(length(data_1min),1);         %�ۼ�������
CostSeries=zeros(length(data_1min),1);              %��¼���׳ɱ�
BackRatio=zeros(length(data_1min),1);               %��¼�ز����

CloseLowerDate = zeros(length(data_1min),1);

%��¼�ʲ��仯����
LongMargin=zeros(length(data_1min),1);              %��ͷ��֤��
ShortMargin=zeros(length(data_1min),1);             %��ͷ��֤��
Cash=repmat(1e4,length(data_1min),1);               %�����ʽ�,��ʼ�ʽ�Ϊ10W
DynamicEquity=repmat(1e4,length(data_1min),1);      %��̬Ȩ��,��ʼ�ʽ�Ϊ10W
StaticEquity=repmat(1e4,length(data_1min),1);       %��̬Ȩ��,��ʼ�ʽ�Ϊ10W

UpLineAll = zeros(length(data),1);
DownLineAll = zeros(length(data),1);
%% --���㲼�ִ���ROC--
%[UpperLine MidLine LowerLine]=BOLL(Close,BollLength,Offset,0);
%RocValue=ROC(Close,ROCLength);

[MAShort, MALong] = movavg(Close, ShortLen, LongLen);
MAShort(1:ShortLen-1) = Close(1:ShortLen-1);
MALong(1:LongLen-1) = Close(1:LongLen-1);

CurrentMinBarIndex = 818;

QuitPrice = 0;

%% --���Է���--

for i=LongLen+1:length(data)
    HH20 = max(High(i-LongLen:i-1));
    HH10 = max(High(i-LongLen+10:i-1));
    LL20 = max(Low(i-LongLen:i-1));
    LL10 = max(Low(i-LongLen+10:i-1));
    ATRValue = ATR(High(i-LongLen:i-1),Low(i-LongLen:i-1),Close(i-LongLen:i-1),LongLen,0);

    curDay = data(i);
    curMinBarDay = data_1min(CurrentMinBarIndex);     
    
    isSameDay = 0;
    
    if (curDay - floor(curMinBarDay + 0.125)) >=0
        isSameDay = 1;
    end
    
    while (isSameDay ==1) && (CurrentMinBarIndex~=length(data_1min)) 
        if MarketPosition==0
            LongMargin(CurrentMinBarIndex)=0;                            %��ͷ��֤��
            ShortMargin(CurrentMinBarIndex)=0;                           %��ͷ��֤��
            StaticEquity(CurrentMinBarIndex)=StaticEquity(CurrentMinBarIndex-1);          %��̬Ȩ��
            DynamicEquity(CurrentMinBarIndex)=StaticEquity(CurrentMinBarIndex);           %��̬Ȩ��
            Cash(CurrentMinBarIndex)=DynamicEquity(CurrentMinBarIndex);                   %�����ʽ�
        end
        if MarketPosition==1
            LongMargin(CurrentMinBarIndex)=Close_1min(CurrentMinBarIndex)*Lots*TradingUnits*MarginRatio;
            StaticEquity(CurrentMinBarIndex)=StaticEquity(CurrentMinBarIndex-1);
            EarnPoint = 0;
            for j=1:Lots
                 EarnPoint = EarnPoint + Close_1min(CurrentMinBarIndex) - OpenPosPrice(OpenPosNum - j + 1);
            end
            DynamicEquity(CurrentMinBarIndex)=StaticEquity(CurrentMinBarIndex)+EarnPoint*TradingUnits;
            Cash(CurrentMinBarIndex)=DynamicEquity(CurrentMinBarIndex)-LongMargin(CurrentMinBarIndex);
        end
        if MarketPosition==-1
            ShortMargin(CurrentMinBarIndex)=Close_1min(CurrentMinBarIndex)*Lots*TradingUnits*MarginRatio;
            StaticEquity(CurrentMinBarIndex)=StaticEquity(CurrentMinBarIndex-1);
            EarnPoint = 0;
            for j=1:Lots
                 EarnPoint = EarnPoint + OpenPosPrice(OpenPosNum - j + 1)-Close_1min(CurrentMinBarIndex);
            end
            DynamicEquity(CurrentMinBarIndex)=StaticEquity(CurrentMinBarIndex)+EarnPoint*TradingUnits;
            Cash(CurrentMinBarIndex)=DynamicEquity(CurrentMinBarIndex)-ShortMargin(CurrentMinBarIndex);
        end

        if MarketPosition==0 
            if High_1min(CurrentMinBarIndex) > HH20
                %Open Long
                MarketPosition = 1;
                MyEntryPrice(CurrentMinBarIndex)= HH20 + Slip*MinMove*PriceScale;
                if Open(CurrentMinBarIndex)>MyEntryPrice(CurrentMinBarIndex)    %�����Ƿ�����
                    MyEntryPrice(CurrentMinBarIndex)=Open(CurrentMinBarIndex)+Slip*MinMove*PriceScale;
                end
                OpenPosNum=OpenPosNum+1;
                OpenPosPrice(OpenPosNum)=MyEntryPrice(CurrentMinBarIndex);%��¼���ּ۸�
                OpenDate(OpenPosNum)=Date_1min(CurrentMinBarIndex);%��¼����ʱ��
                Type(OpenPosNum)=1;   %����Ϊ��ͷ
                QuitPrice = OpenPosPrice(OpenPosNum) - 2*ATRValue;
                Lots = 1;
                StaticEquity(CurrentMinBarIndex)=StaticEquity(CurrentMinBarIndex-1);
                DynamicEquity(CurrentMinBarIndex)=StaticEquity(CurrentMinBarIndex)+(Close_1min(CurrentMinBarIndex)-OpenPosPrice(OpenPosNum))*TradingUnits*Lots;
            elseif Low_1min(CurrentMinBarIndex) < LL20
                %Open Short
                MarketPosition = -1;
                MyEntryPrice(CurrentMinBarIndex)= LL20 - Slip*MinMove*PriceScale;
                if Open(CurrentMinBarIndex)< MyEntryPrice(CurrentMinBarIndex)    %�����Ƿ�����
                    MyEntryPrice(CurrentMinBarIndex)=Open(CurrentMinBarIndex) - Slip*MinMove*PriceScale;
                end
                OpenPosNum=OpenPosNum+1;
                OpenPosPrice(OpenPosNum)=MyEntryPrice(CurrentMinBarIndex);%��¼���ּ۸�
                OpenDate(OpenPosNum)=Date_1min(CurrentMinBarIndex);%��¼����ʱ��
                QuitPrice = OpenPosPrice(OpenPosNum) + 2*ATRValue;
                Type(OpenPosNum)=-1;   %����Ϊ��ͷ
                Lots = 1;
                StaticEquity(CurrentMinBarIndex)=StaticEquity(CurrentMinBarIndex-1);
                EarnPoint = 0;
                DynamicEquity(CurrentMinBarIndex)=StaticEquity(CurrentMinBarIndex)+(OpenPosPrice(OpenPosNum)-Close_1min(CurrentMinBarIndex))*TradingUnits*Lots;
            end
        elseif MarketPosition==-1
            if  Lots < 4 && Low_1min(CurrentMinBarIndex) < OpenPosPrice(OpenPosNum) - ATRValue*0.5
                MyEntryPrice(CurrentMinBarIndex) = OpenPosPrice(OpenPosNum) - ATRValue*0.5  - Slip*MinMove*PriceScale; 
                if Open(CurrentMinBarIndex)<MyEntryPrice(CurrentMinBarIndex)    %�����Ƿ�����
                    MyEntryPrice(CurrentMinBarIndex)=Open(CurrentMinBarIndex) - Slip*MinMove*PriceScale;
                end
                OpenPosNum=OpenPosNum+1;
                OpenPosPrice(OpenPosNum)=MyEntryPrice(CurrentMinBarIndex);%��¼���ּ۸�
                OpenDate(OpenPosNum)=Date_1min(CurrentMinBarIndex);%��¼����ʱ��
                Type(OpenPosNum)=-1;   %����Ϊ��ͷ
                Lots = Lots + 1;
                StaticEquity(CurrentMinBarIndex)=StaticEquity(CurrentMinBarIndex-1);
                
                EarnPoint = 0;
                for j=1:Lots
                    EarnPoint = EarnPoint + OpenPosPrice(OpenPosNum - j + 1)-Close_1min(CurrentMinBarIndex);
                end
                DynamicEquity(CurrentMinBarIndex)=StaticEquity(CurrentMinBarIndex)+EarnPoint*TradingUnits;
                QuitPrice = QuitPrice - 0.5*ATRValue;
            end
              
            if Low_1min(CurrentMinBarIndex)< min(HH10,  QuitPrice)
                MarketPosition=0;
                ShortMargin(CurrentMinBarIndex)=0;     %ƽ����ͷ��֤��Ϊ0��
                ClosePosNum=ClosePosNum+1;
                ClosePosPrice(ClosePosNum)=min(HH10,  QuitPrice) - Slip*MinMove*PriceScale;%��¼ƽ�ּ۸�
                if Open(CurrentMinBarIndex)< ClosePosPrice(ClosePosNum)    %�����Ƿ�����
                   ClosePosPrice(ClosePosNum)=Open(CurrentMinBarIndex) - Slip*MinMove*PriceScale;
                end
                CloseDate(ClosePosNum)=Date_1min(CurrentMinBarIndex);%��¼ƽ��ʱ��
                
                EarnPoint = 0;
                for j=1:Lots
                    EarnPoint = EarnPoint + OpenPosPrice(OpenPosNum - j + 1) - ClosePosPrice(ClosePosNum);
                end
                
                TotalTradingCost = 0;
                for j=1:Lots
                    TotalTradingCost = TotalTradingCost + OpenPosPrice(OpenPosNum - j + 1)*TradingUnits*TradingCost;
                end
                
                TotalTradingCost = TotalTradingCost + ClosePosPrice(ClosePosNum)*TradingUnits*Lots*TradingCost;
                
                StaticEquity(CurrentMinBarIndex)=StaticEquity(CurrentMinBarIndex-1)+EarnPoint*TradingUnits-TotalTradingCost;%ƽ���ʱ�ľ�̬Ȩ�棬�㷨�ο�TB
                DynamicEquity(CurrentMinBarIndex)=StaticEquity(CurrentMinBarIndex);%�ղ�ʱ��̬Ȩ��;�̬Ȩ�����
                Cash(CurrentMinBarIndex)=DynamicEquity(CurrentMinBarIndex); %�ղ�ʱ�����ʽ���ڶ�̬Ȩ��
                
                QuitPrice = 0 ;
                Lots = O;
            end
        elseif MarketPosition==1
            if Lots < 4 && High_1min(CurrentMinBarIndex) > OpenPosPrice(OpenPosNum) + ATRValue*0.5
                
                MyEntryPrice(CurrentMinBarIndex) = OpenPosPrice(OpenPosNum) + ATRValue*0.5 +Slip*MinMove*PriceScale; 
                if Open(CurrentMinBarIndex)>MyEntryPrice(CurrentMinBarIndex)    %�����Ƿ�����
                    MyEntryPrice(CurrentMinBarIndex)=Open(CurrentMinBarIndex)+Slip*MinMove*PriceScale;
                end
                OpenPosNum=OpenPosNum+1;
                OpenPosPrice(OpenPosNum)=MyEntryPrice(CurrentMinBarIndex);%��¼���ּ۸�
                OpenDate(OpenPosNum)=Date_1min(CurrentMinBarIndex);%��¼����ʱ��
                Type(OpenPosNum)=1;   %����Ϊ��ͷ
                Lots = Lots + 1;
                StaticEquity(CurrentMinBarIndex)=StaticEquity(CurrentMinBarIndex-1);
                for j=1:Lots
                	EarnPoint = EarnPoint + Close_1min(CurrentMinBarIndex) - OpenPosPrice(OpenPosNum - j + 1);
                end               
                DynamicEquity(CurrentMinBarIndex)=StaticEquity(CurrentMinBarIndex)+EarnPoint*TradingUnits;
                QuitPrice = QuitPrice + 0.5*ATRValue;
            end
            
            if Low_1min(CurrentMinBarIndex)< max(LL10,  QuitPrice)
                MarketPosition=0;
                LongMargin(CurrentMinBarIndex)=0;     %ƽ����ͷ��֤��Ϊ0��
                ClosePosNum=ClosePosNum+1;
                ClosePosPrice(ClosePosNum)=max(LL10,  QuitPrice)- Slip*MinMove*PriceScale;%��¼ƽ�ּ۸�
                if Open(CurrentMinBarIndex)< ClosePosPrice(ClosePosNum)    %�����Ƿ�����
                   ClosePosPrice(ClosePosNum)=Open(CurrentMinBarIndex) - Slip*MinMove*PriceScale;
                end
                CloseDate(ClosePosNum)=Date_1min(CurrentMinBarIndex);%��¼ƽ��ʱ��
                
                EarnPoint = 0;
                for j=1:Lots
                    EarnPoint = EarnPoint + ClosePosPrice(ClosePosNum)-OpenPosPrice(OpenPosNum - j + 1);
                end
                
                TotalTradingCost = 0;
                for j=1:Lots
                    TotalTradingCost = TotalTradingCost + OpenPosPrice(OpenPosNum - j + 1)*TradingUnits*TradingCost;
                end
                
                TotalTradingCost = TotalTradingCost + ClosePosPrice(ClosePosNum)*TradingUnits*Lots*TradingCost;
                
                StaticEquity(CurrentMinBarIndex)=StaticEquity(CurrentMinBarIndex-1)+EarnPoint*TradingUnits - TotalTradingCost;%ƽ���ʱ�ľ�̬Ȩ�棬�㷨�ο�TB
                DynamicEquity(CurrentMinBarIndex)=StaticEquity(CurrentMinBarIndex);%�ղ�ʱ��̬Ȩ��;�̬Ȩ�����
                Cash(CurrentMinBarIndex)=DynamicEquity(CurrentMinBarIndex); %�ղ�ʱ�����ʽ���ڶ�̬Ȩ��
                QuitPrice = 0 ;
                Lots = O;
            end
        
        end
       

        %������һ��Bar�гֲ֣��������̼�ƽ��
        if CurrentMinBarIndex==length(data_1min)
            %ƽ��
            if MarketPosition==1
                MarketPosition=0;
                LongMargin(CurrentMinBarIndex)=0; 
                ClosePosNum=ClosePosNum+1;           
                ClosePosPrice(ClosePosNum)=Close_1min(CurrentMinBarIndex);%��¼ƽ�ּ۸�
                CloseDate(ClosePosNum)=Date_1min(CurrentMinBarIndex);%��¼ƽ��ʱ��
                EarnPoint = 0;
                for j=1:Lots
                    EarnPoint = EarnPoint + ClosePosPrice(ClosePosNum)-OpenPosPrice(OpenPosNum - j + 1);
                end
                
                TotalTradingCost = 0;
                for j=1:Lots
                    TotalTradingCost = TotalTradingCost + OpenPosPrice(OpenPosNum - j + 1)*TradingUnits*TradingCost;
                end
                
                TotalTradingCost = TotalTradingCost + ClosePosPrice(ClosePosNum)*TradingUnits*Lots*TradingCost;
                
                StaticEquity(CurrentMinBarIndex)=StaticEquity(CurrentMinBarIndex-1)+EarnPoint*TradingUnits - TotalTradingCost;%ƽ���ʱ�ľ�̬Ȩ�棬�㷨�ο�TB
                DynamicEquity(CurrentMinBarIndex)=StaticEquity(CurrentMinBarIndex);%�ղ�ʱ��̬Ȩ��;�̬Ȩ�����
                Cash(CurrentMinBarIndex)=DynamicEquity(CurrentMinBarIndex); %�ղ�ʱ�����ʽ���ڶ�̬Ȩ��
            end
            %ƽ��
            if MarketPosition==-1
                MarketPosition=0;
                ShortMargin(CurrentMinBarIndex)=0;
                ClosePosNum=ClosePosNum+1;
                ClosePosPrice(ClosePosNum)=Close_1min(CurrentMinBarIndex);
                CloseDate(ClosePosNum)=Date_1min(CurrentMinBarIndex);
                EarnPoint = 0;
                for j=1:Lots
                    EarnPoint = EarnPoint + OpenPosPrice(OpenPosNum - j + 1) - ClosePosPrice(ClosePosNum);
                end
                
                TotalTradingCost = 0;
                for j=1:Lots
                    TotalTradingCost = TotalTradingCost + OpenPosPrice(OpenPosNum - j + 1)*TradingUnits*TradingCost;
                end
                
                TotalTradingCost = TotalTradingCost + ClosePosPrice(ClosePosNum)*TradingUnits*Lots*TradingCost;
                
                StaticEquity(CurrentMinBarIndex)=StaticEquity(CurrentMinBarIndex-1)+EarnPoint*TradingUnits-TotalTradingCost;%ƽ���ʱ�ľ�̬Ȩ�棬�㷨�ο�TB
                DynamicEquity(CurrentMinBarIndex)=StaticEquity(CurrentMinBarIndex);%�ղ�ʱ��̬Ȩ��;�̬Ȩ�����
                Cash(CurrentMinBarIndex)=DynamicEquity(CurrentMinBarIndex); %�ղ�ʱ�����ʽ���ڶ�̬Ȩ��

            end
            
        end
        pos(CurrentMinBarIndex)=MarketPosition;
        
        if CurrentMinBarIndex~=length(data_1min)
            CurrentMinBarIndex = CurrentMinBarIndex+1;
            curMinBarDay = data_1min(CurrentMinBarIndex);  
            if (curDay - floor(curMinBarDay + 0.125)) >=0
                isSameDay = 1;
            else
                isSameDay = 0;
            end
        end
    end
    
end

%% -��Ч����--

RecLength=ClosePosNum;%��¼���׳���

%�������������
for i=1:RecLength

    %���׳ɱ�(����+ƽ��)
    CostSeries(i)=OpenPosPrice(i)*TradingUnits*Lots*TradingCost+ClosePosPrice(i)*TradingUnits*Lots*TradingCost;
    
    %������
    %��ͷ����ʱ
    if Type(i)==1
        NetMargin(i)=(ClosePosPrice(i)-OpenPosPrice(i))*TradingUnits*Lots-CostSeries(i);
    end
    %��ͷ����ʱ
    if Type(i)==-1
        NetMargin(i)=(OpenPosPrice(i)-ClosePosPrice(i))*TradingUnits*Lots-CostSeries(i);
    end
    %������
    RateOfReturn(i)=NetMargin(i)/(OpenPosPrice(i)*TradingUnits*Lots*MarginRatio);
end

%�ۼƾ���
CumNetMargin=cumsum(NetMargin);

%�ۼ�������
CumRateOfReturn=cumsum(RateOfReturn);

%�س�����
for i=1:length(data_1min)
    c=max(DynamicEquity(1:i));
    if c==DynamicEquity(i)
        BackRatio(i)=0;
    else
        BackRatio(i)=(DynamicEquity(i)-c)/c;
    end
end

%��������
Daily=Date_1min(hour(Date_1min)==9  & minute(Date_1min)==0 & second(Date_1min)==0);
DailyEquity=DynamicEquity(hour(Date_1min)==9  & minute(Date_1min)==0 & second(Date_1min)==0);
DailyRet=tick2ret(DailyEquity);

%��������
WeeklyNum=weeknum(Daily);    %weeknum������һ��ĵڼ���
Weekly=[Daily((WeeklyNum(1:end-1)-WeeklyNum(2:end))~=0);Daily(end)];
WeeklyEquity=[DailyEquity((WeeklyNum(1:end-1)-WeeklyNum(2:end))~=0);DailyEquity(end)];
WeeklyRet=tick2ret(WeeklyEquity);

%��������
MonthNum=month(Daily);
Monthly=[Daily((MonthNum(1:end-1)-MonthNum(2:end))~=0);Daily(end)];
MonthlyEquity=[DailyEquity((MonthNum(1:end-1)-MonthNum(2:end))~=0);DailyEquity(end)];
MonthlyRet=tick2ret(MonthlyEquity);

%��������
YearNum=year(Daily);
Yearly=[Daily((YearNum(1:end-1)-YearNum(2:end))~=0);Daily(end)];
YearlyEquity=[DailyEquity((YearNum(1:end-1)-YearNum(2:end))~=0);DailyEquity(end)];
YearlyRet=tick2ret(YearlyEquity);

%% �Զ��������Ա���(�����excel)
%% ������׻���
Lots = 1;
TradeSum = cell(25,7);

RowNum = 1;
ColNum = 1;
TradeSum{RowNum,1} = 'ͳ��ָ��';
TradeSum{RowNum,2} = 'ȫ������';
TradeSum{RowNum,3} = '��ͷ';
TradeSum{RowNum,4} = '��ͷ';

%������
ProfitTotal=sum(NetMargin);
ProfitLong=sum(NetMargin(Type==1));
ProfitShort=sum(NetMargin(Type==-1));

RowNum = 2;
ColNum = 1;
TradeSum{RowNum,1} = '������';
TradeSum{RowNum,2} = ProfitTotal;
TradeSum{RowNum,3} = ProfitLong;
TradeSum{RowNum,4} = ProfitShort;

%��ӯ��
WinTotal=sum(NetMargin(NetMargin>0));
ans=NetMargin(Type==1);
WinLong=sum(ans(ans>0));
ans=NetMargin(Type==-1);
WinShort=sum(ans(ans>0));

RowNum = 3;
ColNum = 1;
TradeSum{RowNum,1} = '��ӯ��';
TradeSum{RowNum,2} = WinTotal;
TradeSum{RowNum,3} = WinLong;
TradeSum{RowNum,4} = WinShort;

%�ܿ���
LoseTotal=sum(NetMargin(NetMargin<0));
ans=NetMargin(Type==1);
LoseLong=sum(ans(ans<0));
ans=NetMargin(Type==-1);
LoseShort=sum(ans(ans<0));

RowNum = 4;
ColNum = 1;
TradeSum{RowNum,1} = '�ܿ���';
TradeSum{RowNum,2} = LoseTotal;
TradeSum{RowNum,3} = LoseLong;
TradeSum{RowNum,4} = LoseShort;

%��ӯ��/�ܿ���
WinTotalDLoseTotal=abs(WinTotal/LoseTotal);
WinLongDLoseLong=abs(WinLong/LoseLong);
WinShortDLoseShort=abs(WinShort/LoseShort);

RowNum = 5;
ColNum = 1;
TradeSum{RowNum,1} = '��ӯ��/�ܿ���';
TradeSum{RowNum,2} = WinTotalDLoseTotal;
TradeSum{RowNum,3} = WinLongDLoseLong;
TradeSum{RowNum,4} = WinShortDLoseShort;

%��������
LotsTotal=length(Type(Type~=0))*Lots;
LotsLong=length(Type(Type==1))*Lots;
LotsShort=length(Type(Type==-1))*Lots;

RowNum = 7;
ColNum = 1;
TradeSum{RowNum,1} = '��������';
TradeSum{RowNum,2} = LotsTotal;
TradeSum{RowNum,3} = LotsLong;
TradeSum{RowNum,4} = LotsShort;

%ӯ������
LotsWinTotal=length(NetMargin(NetMargin>0))*Lots;
ans=NetMargin(Type==1);
LotsWinLong=length(ans(ans>0))*Lots;
ans=NetMargin(Type==-1);
LotsWinShort=length(ans(ans>0))*Lots;

RowNum = 8;
ColNum = 1;
TradeSum{RowNum,1} = 'ӯ������';
TradeSum{RowNum,2} = LotsWinTotal;
TradeSum{RowNum,3} = LotsWinLong;
TradeSum{RowNum,4} = LotsWinShort;

%��������
LotsLoseTotal=length(NetMargin(NetMargin<0))*Lots;
ans=NetMargin(Type==1);
LotsLoseLong=length(ans(ans<0))*Lots;
ans=NetMargin(Type==-1);
LotsLoseShort=length(ans(ans<0))*Lots;

RowNum = 9;
ColNum = 1;
TradeSum{RowNum,1} = '��������';
TradeSum{RowNum,2} = LotsLoseTotal;
TradeSum{RowNum,3} = LotsLoseLong;
TradeSum{RowNum,4} = LotsLoseShort;

%��ƽ����
ans=NetMargin(Type==1);
LotsDrawLong=length(ans(ans==0))*Lots;
ans=NetMargin(Type==-1);
LotsDrawShort=length(ans(ans==0))*Lots;
LotsDrawTotal=LotsDrawLong+LotsDrawShort;

RowNum = 10;
ColNum = 1;
TradeSum{RowNum,1} = '��ƽ����';
TradeSum{RowNum,2} = LotsDrawTotal;
TradeSum{RowNum,3} = LotsDrawLong;
TradeSum{RowNum,4} = LotsDrawShort;

%ӯ������
LotsWinTotalDLotsTotal=LotsWinTotal/LotsTotal;
LotsWinLongDLotsLong=LotsWinLong/LotsLong;
LotsWinShortDLotsShort=LotsWinShort/LotsShort;

RowNum = 11;
ColNum = 1;
TradeSum{RowNum,1} = 'ӯ������';
TradeSum{RowNum,2} = LotsWinTotalDLotsTotal;
TradeSum{RowNum,3} = LotsWinLongDLotsLong;
TradeSum{RowNum,4} = LotsWinShortDLotsShort;

%ƽ������
RowNum = 13;
ColNum = 1;
TradeSum{RowNum,1} = 'ƽ������(������/��������)';
TradeSum{RowNum,2} = ProfitTotal/LotsTotal;
TradeSum{RowNum,3} = ProfitLong/LotsLong;
TradeSum{RowNum,4} = ProfitShort/LotsShort;

%ƽ��ӯ��
RowNum = 14;
ColNum = 1;
TradeSum{RowNum,1} = 'ƽ��ӯ��(��ӯ�����/ӯ����������)';
TradeSum{RowNum,2} = WinTotal/LotsWinTotal;
TradeSum{RowNum,3} = WinLong/LotsWinLong;
TradeSum{RowNum,4} = WinShort/LotsWinShort;

%ƽ������
RowNum = 15;
ColNum = 1;
TradeSum{RowNum,1} = 'ƽ������(�ܿ�����/����������)';
TradeSum{RowNum,2} = LoseTotal/LotsLoseTotal;
TradeSum{RowNum,3} = LoseLong/LotsLoseLong;
TradeSum{RowNum,4} = LoseShort/LotsLoseShort;

%ƽ��ӯ��/ƽ������
RowNum = 16;
ColNum = 1;
TradeSum{RowNum,1} = 'ƽ��ӯ��/ƽ������';
TradeSum{RowNum,2} = abs((WinTotal/LotsWinTotal)/(LoseTotal/LotsLoseTotal));
TradeSum{RowNum,3} = abs((WinLong/LotsWinLong)/(LoseLong/LotsLoseLong));
TradeSum{RowNum,4} = abs((WinShort/LotsWinShort)/(LoseShort/LotsLoseShort));

%���ӯ��
MaxWinTotal=max(NetMargin(NetMargin>0));
ans=NetMargin(Type==1);
MaxWinLong=max(ans(ans>0));
ans=NetMargin(Type==-1);
MaxWinShort=max(ans(ans>0));
RowNum = 18;
ColNum = 1;
TradeSum{RowNum,1} = '���ӯ��';
TradeSum{RowNum,2} = MaxWinTotal;
TradeSum{RowNum,3} = MaxWinLong;
TradeSum{RowNum,4} = MaxWinShort;

%������
MaxLoseTotal=min(NetMargin(NetMargin<0));
ans=NetMargin(Type==1);
MaxLoseLong=min(ans(ans<0));
ans=NetMargin(Type==-1);
MaxLoseShort=min(ans(ans<0));
RowNum = 19;
ColNum = 1;
TradeSum{RowNum,1} = '������';
TradeSum{RowNum,2} = MaxLoseTotal;
TradeSum{RowNum,3} = MaxLoseLong;
TradeSum{RowNum,4} = MaxLoseShort;

%���ӯ��/��ӯ��
RowNum = 20;
ColNum = 1;
TradeSum{RowNum,1} = '���ӯ��/��ӯ��';
TradeSum{RowNum,2} = MaxWinTotal/WinTotal;
TradeSum{RowNum,3} = MaxWinLong/WinLong;
TradeSum{RowNum,4} = MaxWinShort/WinShort;

%������/�ܿ���
RowNum = 21;
ColNum = 1;
TradeSum{RowNum,1} = '������/�ܿ���';
TradeSum{RowNum,2} = MaxLoseTotal/LoseTotal;
TradeSum{RowNum,3} = MaxLoseLong/LoseLong;
TradeSum{RowNum,4} = MaxLoseShort/LoseShort;

%������/������
RowNum = 22;
ColNum = 1;
TradeSum{RowNum,1} = '������/������';
TradeSum{RowNum,2} = ProfitTotal/MaxLoseTotal;
TradeSum{RowNum,3} = ProfitLong/MaxLoseLong;
TradeSum{RowNum,4} = ProfitShort/MaxLoseShort;

%���ʹ���ʽ�
RowNum = 24;
ColNum = 1;
TradeSum{RowNum,1} = '���ʹ���ʽ�';
TradeSum{RowNum,2} = max(max(LongMargin),max(ShortMargin));
TradeSum{RowNum,3} = max(LongMargin);
TradeSum{RowNum,4} = max(ShortMargin);

%���׳ɱ��ϼ�
CostTotal=sum(CostSeries);
ans=CostSeries(Type==1);
CostLong=sum(ans);
ans=CostSeries(Type==-1);
CostShort=sum(ans);

RowNum = 25;
ColNum = 1;
TradeSum{RowNum,1} = '���׳ɱ��ϼ�';
TradeSum{RowNum,2} = CostTotal;
TradeSum{RowNum,3} = CostLong;
TradeSum{RowNum,4} = CostShort;

%����ʱ�䷶Χ
RowNum = 2;
ColNum = 6;
TradeSum{RowNum,6} = '����ʱ�䷶Χ';
TradeSum{RowNum,7} = ['[',datestr(Date(1),'yyyy-mm-dd HH:MM:SS'),']'];
TradeSum{RowNum,8} = '--';
TradeSum{RowNum,9} = ['[',datestr(Date(end),'yyyy-mm-dd HH:MM:SS'),']'];

%�ܽ���ʱ��
RowNum = 3;
ColNum = 1;
TradeSum{RowNum,6} = '��������';
TradeSum{RowNum,7} = round(Date(end)-Date(1));

%�ֲ�ʱ�����
RowNum = 4;
ColNum = 1;
TradeSum{RowNum,6} = '�ֲ�ʱ�����';
TradeSum{RowNum,7} = length(pos(pos~=0))/length(data);

%�ֲ�ʱ��
HoldingDays=round(round(Date(end)-Date(1))*(length(pos(pos~=0))/length(data)));%�ֲ�ʱ��
RowNum = 5;
ColNum = 1;
TradeSum{RowNum,6} = '�ֲ�ʱ��(��)';
TradeSum{RowNum,7} = HoldingDays;

%������
RowNum = 7;
ColNum = 1;
TradeSum{RowNum,6} = '������(%)';
TradeSum{RowNum,7} = (DynamicEquity(end)-DynamicEquity(1))/DynamicEquity(1)*100;

%��Ч������
TrueRatOfRet=(DynamicEquity(end)-DynamicEquity(1))/max(max(LongMargin),max(ShortMargin));
RowNum = 8;
ColNum = 1;
TradeSum{RowNum,6} = '��Ч������(%)';
TradeSum{RowNum,7} = TrueRatOfRet*100;

%���������(��365����)
RowNum = 9;
ColNum = 1;
TradeSum{RowNum,6} = '�껯������(��365����,%)';
TradeSum{RowNum,7} = (1+TrueRatOfRet)^(1/(HoldingDays/365))*100;

%���������(��240����)
RowNum = 10;
ColNum = 1;
TradeSum{RowNum,6} = '���������(��240����,%)';
TradeSum{RowNum,7} = (1+TrueRatOfRet)^(1/(HoldingDays/240))*100;

% ���������(������)
RowNum = 11;
ColNum = 1;
TradeSum{RowNum,6} = '���������(������,%)';
TradeSum{RowNum,7} = mean(DailyRet)*365*100;

%���������(������)
RowNum = 12;
ColNum = 1;
TradeSum{RowNum,6} = '���������(������,%)';
TradeSum{RowNum,7} = mean(WeeklyRet)*52*100;

%���������(������)
RowNum = 13;
ColNum = 1;
TradeSum{RowNum,6} = '���������(������,%)';
TradeSum{RowNum,7} = mean(MonthlyRet)*12*100;

%���ձ���(������)
RowNum = 14;
ColNum = 1;
TradeSum{RowNum,6} = '���ձ���(������,%)';
TradeSum{RowNum,7} = (mean(DailyRet)*365-RiskLess)/(std(DailyRet)*sqrt(365));

%���ձ���(������)
RowNum = 15;
ColNum = 1;
TradeSum{RowNum,6} = '���ձ���(������,%)';
TradeSum{RowNum,7} = (mean(WeeklyRet)*52-RiskLess)/(std(WeeklyRet)*sqrt(52));

%���ձ���(������)
RowNum = 16;
ColNum = 1;
TradeSum{RowNum,6} = '���ձ���(������,%)';
TradeSum{RowNum,7} = (mean(MonthlyRet)*12-RiskLess)/(std(MonthlyRet)*sqrt(12));

%���س�����
RowNum = 17;
ColNum = 1;
TradeSum{RowNum,6} = '���س�����(%)';
TradeSum{RowNum,7} = abs(min(BackRatio))*100;

%% ���׻�������д��Excel
dirPath = [cd, '\Report\'];
if ~isdir(dirPath)
    mkdir(dirPath);
end

filename = '���Ա���.xlsx';
filePath = [cd,'\Report\',filename];
if exist(filePath,'file')
    delete(filePath);
end

sheetName = '���׻���';
[status,msg] = xlswrite(filePath,TradeSum,sheetName);
%% ������׼�¼

TradeRec = cell(1,1);

RowNum = 1;
ColNum = 1;
TradeRec{1, ColNum} = '#';
Len = length(1:RecLength);
TradeRec(2:Len+1, ColNum) = mat2cell( (1:RecLength)', ones(Len,1) );

RowNum = 1;
ColNum = 2;
TradeRec{1, ColNum} = '����';
Len = length(1:RecLength);
TradeRec(2:Len+1, ColNum) = mat2cell( Type(1:RecLength), ones(Len,1) );

RowNum = 1;
ColNum = 3;
TradeRec{1, ColNum} = '��Ʒ';
Len = length(1:RecLength);
TradeRec(2:Len+1, ColNum) = cellstr(repmat(commodity,RecLength,1));

RowNum = 1;
ColNum = 4;
TradeRec{1, ColNum} = '����';
Len = length(1:RecLength);
TradeRec(2:Len+1, ColNum) = cellstr(repmat(Freq,RecLength,1));

RowNum = 1;
ColNum = 5;
TradeRec{1, ColNum} = '����ʱ��';
Len = length(1:RecLength);
TradeRec(2:Len+1, ColNum) = cellstr(datestr(OpenDate(1:RecLength),'yyyy-mm-dd HH:MM:SS'));

RowNum = 1;
ColNum = 6;
TradeRec{1, ColNum} = '���ּ۸�';
Len = length(1:RecLength);
TradeRec(2:Len+1, ColNum) = mat2cell( OpenPosPrice(1:RecLength), ones(Len,1) );

RowNum = 1;
ColNum = 7;
TradeRec{1, ColNum} = 'ƽ��ʱ��';
Len = length(1:RecLength);
TradeRec(2:Len+1, ColNum) = cellstr(datestr(CloseDate(1:RecLength),'yyyy-mm-dd HH:MM:SS'));

RowNum = 1;
ColNum = 8;
TradeRec{1, ColNum} = 'ƽ�ּ۸�';
Len = length(1:RecLength);
TradeRec(2:Len+1, ColNum) = mat2cell( ClosePosPrice(1:RecLength), ones(Len,1) );

RowNum = 1;
ColNum = 9;
TradeRec{1, ColNum} = '����';
Len = length(1:RecLength);
TradeRec(2:Len+1, ColNum) = mat2cell( repmat(Lots,RecLength,1), ones(Len,1) );

RowNum = 1;
ColNum = 10;
TradeRec{1, ColNum} = '���׳ɱ�';
Len = length(1:RecLength);
TradeRec(2:Len+1, ColNum) = mat2cell( CostSeries(1:RecLength), ones(Len,1) );

RowNum = 1;
ColNum = 11;
TradeRec{1, ColNum} = '����';
Len = length(1:RecLength);
TradeRec(2:Len+1, ColNum) = mat2cell( NetMargin(1:RecLength), ones(Len,1) );

RowNum = 1;
ColNum = 12;
TradeRec{1, ColNum} = '�ۼƾ���';
Len = length(1:RecLength);
TradeRec(2:Len+1, ColNum) = mat2cell( CumNetMargin(1:RecLength), ones(Len,1) );

RowNum = 1;
ColNum = 13;
TradeRec{1, ColNum} = '������';
Len = length(1:RecLength);
TradeRec(2:Len+1, ColNum) = mat2cell( RateOfReturn(1:RecLength), ones(Len,1) );

RowNum = 1;
ColNum = 14;
TradeRec{1, ColNum} = '�ۼ�������';
Len = length(1:RecLength);
TradeRec(2:Len+1, ColNum) = mat2cell( CumRateOfReturn(1:RecLength), ones(Len,1) );

%% ���׼�¼����д��Excel
sheetName = '���׼�¼';
[status,msg] = xlswrite(filePath,TradeRec,sheetName);
%% ����ʲ��仯

TradeMoney = cell(1,1);
Len = length(1:length(data_1min));

RowNum = 1;
ColNum = 1;
TradeMoney{1, ColNum} = '�ʲ���Ҫ';
TradeMoney{2, ColNum} = '����ʲ�';
TradeMoney{3, ColNum} = StaticEquity(1);

RowNum = 1;
ColNum = 2;
TradeMoney{2, ColNum} = '��ĩ�ʲ�';
TradeMoney{3, ColNum} = StaticEquity(end);

RowNum = 1;
ColNum = 3;
TradeMoney{2, ColNum} = '����ӯ��';
TradeMoney{3, ColNum} = sum(NetMargin);

RowNum = 1;
ColNum = 4;
TradeMoney{2, ColNum} = '����ʲ�';
TradeMoney{3, ColNum} = max(DynamicEquity);

RowNum = 1;
ColNum = 5;
TradeMoney{2, ColNum} = '��С�ʲ�';
TradeMoney{3, ColNum} = min(DynamicEquity);

RowNum = 1;
ColNum = 6;
TradeMoney{2, ColNum} = '���׳ɱ��ϼ�';
TradeMoney{3, ColNum} = sum(CostSeries);

RowNum = 5;
ColNum = 1;
TradeMoney{5, ColNum} = '�ʲ��仯��ϸ';
TradeMoney{6, ColNum} = 'Bar#';
TradeMoney(7:Len+6, ColNum) = mat2cell( (1:length(data_1min))', ones(Len,1) );

RowNum = 5;
ColNum = 2;
TradeMoney{6, ColNum} = 'ʱ��';
TradeMoney(7:Len+6, ColNum) = cellstr(datestr(Date_1min,'yyyy-mm-dd HH:MM:SS'));

RowNum = 5;
ColNum = 3;
TradeMoney{6, ColNum} = '��ͷ��֤��';
TradeMoney(7:Len+6, ColNum) = mat2cell( LongMargin, ones(Len,1) );

RowNum = 5;
ColNum = 4;
TradeMoney{6, ColNum} = '��ͷ��֤��';
TradeMoney(7:Len+6, ColNum) = mat2cell( ShortMargin, ones(Len,1) );

RowNum = 5;
ColNum = 5;
TradeMoney{6, ColNum} = '�����ʽ�';
TradeMoney(7:Len+6, ColNum) = mat2cell( Cash, ones(Len,1) );

RowNum = 5;
ColNum = 6;
TradeMoney{6, ColNum} = '��̬Ȩ��';
TradeMoney(7:Len+6, ColNum) = mat2cell( DynamicEquity, ones(Len,1) );

RowNum = 5;
ColNum = 7;
TradeMoney{6, ColNum} = '��̬Ȩ��';
TradeMoney(7:Len+6, ColNum) = mat2cell( StaticEquity, ones(Len,1) );

%% �ʲ��仯����д��Excel
sheetName = '�ʲ��仯';
[status,msg] = xlswrite(filePath,TradeMoney,sheetName);
%% --ͼ�����--

dirPath = [cd, '\Report\'];

%�������ִ�(����)
%scrsz = get(0,'ScreenSize');
%figure('Position',[scrsz(3)*1/4 scrsz(4)*1/6 scrsz(3)*4/5 scrsz(4)]*3/4);
%candle(High(end-150:end),Low(end-150:end),Open(end-150:end),Close(end-150:end),'r');
%hold on;
%plot([MidLine(end-150:end)],'k');
%plot([UpperLine(end-150:end)],'g');
%plot([LowerLine(end-150:end)],'g');
%title('���ִ�(������)');
%saveas(gcf,[dirPath, '1���ִ�(������).png']);
% close all;

%����ӯ�����߼��ۼƳɱ�
scrsz = get(0,'ScreenSize');
figure('Position',[scrsz(3)*1/4 scrsz(4)*1/6 scrsz(3)*4/5 scrsz(4)]*3/4);
subplot(2,1,1);
area(1:RecLength,CumNetMargin(1:RecLength),'FaceColor','g');
axis([1 RecLength min(CumNetMargin(1:RecLength)) max(CumNetMargin(1:RecLength))]);
xlabel('���״���');
ylabel('����ӯ��(Ԫ)');
title('����ӯ������');

subplot(2,1,2);
plot(CumNetMargin(1:RecLength),'r','LineWidth',2);
hold on;
plot(cumsum(CostSeries(1:RecLength)),'b','LineWidth',2);
axis([1 RecLength min(CumNetMargin(1:RecLength)) max(CumNetMargin(1:RecLength))]);
xlabel('���״���');
ylabel('����ӯ�����ɱ�(Ԫ)');
legend('����ӯ��','�ۼƳɱ�','Location','NorthWest');
hold off;
saveas(gcf,[dirPath, '2����ӯ������.png']);
% close all;

%����ӯ���ֲ�ͼ
scrsz = get(0,'ScreenSize');
figure('Position',[scrsz(3)*1/4 scrsz(4)*1/6 scrsz(3)*4/5 scrsz(4)]*3/4);
subplot(2,1,1);
ans=NetMargin(1:RecLength);%������͸������ò�ͬ����ɫ��ʾ
ans(ans<0)=0;
plot(ans,'r.');
hold on;
ans=NetMargin(1:RecLength);
ans(ans>0)=0;
plot(ans,'b.');
xlabel('ӯ��(Ԫ)');
ylabel('���״���');
title('����ӯ���ֲ�ͼ');

subplot(2,1,2);
hist(NetMargin(1:RecLength),50);
h = findobj(gca,'Type','patch');
set(h,'FaceColor','r','EdgeColor','w')
xlabel('Ƶ��');
ylabel('ӯ������');
saveas(gcf, [dirPath, '3����ӯ���ֲ�ͼ.png']);
% close all;

%Ȩ������
scrsz = get(0,'ScreenSize');
figure('Position',[scrsz(3)*1/4 scrsz(4)*1/6 scrsz(3)*4/5 scrsz(4)]*3/4);
plot(Date_1min,DynamicEquity,'r','LineWidth',2);
hold on;
area(Date_1min,DynamicEquity,'FaceColor','g');
datetick('x',29);
axis([Date_1min(1) Date_1min(end) min(DynamicEquity) max(DynamicEquity)]);
xlabel('ʱ��');
ylabel('��̬Ȩ��(Ԫ)');
title('Ȩ������ͼ');
hold off;
saveas(gcf, [dirPath, '4Ȩ������ͼ.png']);
% close all;

%��λ���ز����
scrsz = get(0,'ScreenSize');
figure('Position',[scrsz(3)*1/4 scrsz(4)*1/6 scrsz(3)*4/5 scrsz(4)]*3/4);
subplot(2,1,1);
plot(Date_1min,pos,'g');
datetick('x',29);
axis([Date_1min(1) Date_1min(end) min(pos) max(pos)]);
xlabel('ʱ��');
ylabel('��λ');
title('��λ״̬(1-��ͷ 0-���ֲ� -1-��ͷ)');

subplot(2,1,2);
plot(Date_1min,BackRatio,'b');
datetick('x',29);
axis([Date_1min(1) Date_1min(end) min(BackRatio) max(BackRatio)]);
xlabel('ʱ��');
ylabel('�س�����');
title(strcat('�س���������ʼ�ʽ�Ϊ��',num2str(DynamicEquity(1)),'�����ֱ�����',num2str(max(max(LongMargin),max(ShortMargin))/DynamicEquity(1)*100),'%',...
    '����֤�������',num2str(MarginRatio*100),'%��'));
saveas(gcf, [dirPath, '5��λ���ز����.png']);
% close all;

%��նԱ�
scrsz = get(0,'ScreenSize');
figure('Position',[scrsz(3)*1/4 scrsz(4)*1/6 scrsz(3)*4/5 scrsz(4)]*3/4);
subplot(2,2,1);
pie3([LotsWinLong LotsLoseLong],[1 0],{strcat('��ͷӯ������:',num2str(LotsWinLong),'�֣�','ռ��:',num2str(LotsWinLong/(LotsWinLong+LotsLoseLong)*100),'%')...
    ,strcat('��ͷ��������:',num2str(LotsLoseLong),'�֣�','ռ��:',num2str(LotsLoseLong/(LotsWinLong+LotsLoseLong)*100),'%')});

subplot(2,2,2);
pie3([WinLong abs(LoseLong)],[1 0],{strcat('��ͷ��ӯ��:',num2str(WinLong),'Ԫ��','ռ��:',num2str(WinLong/(WinLong+abs(LoseLong))*100),'%')...
    ,strcat('��ͷ�ܿ���:',num2str(abs(LoseLong)),'Ԫ��','ռ��:',num2str(abs(LoseLong)/(WinLong+abs(LoseLong))*100),'%')});

subplot(2,2,3);
pie3([LotsWinShort LotsLoseShort],[1 0],{strcat('��ͷӯ������:',num2str(LotsWinShort),'�֣�','ռ��:',num2str(LotsWinShort/(LotsWinShort+LotsLoseShort)*100),'%')...
,strcat('��ͷ��������:',num2str(LotsLoseShort),'�֣�','ռ��:',num2str(LotsLoseShort/(LotsWinShort+LotsLoseShort)*100),'%')});

subplot(2,2,4);
pie3([WinShort abs(LoseShort)],[1 0],{strcat('��ͷ��ӯ��:',num2str(WinShort),'Ԫ��','ռ��:',num2str(WinShort/(WinShort+abs(LoseShort))*100),'%')...
    ,strcat('��ͷ�ܿ���:',num2str(abs(LoseShort)),'Ԫ��','ռ��:',num2str(abs(LoseShort)/(WinShort+abs(LoseShort))*100),'%')});
saveas(gcf, [dirPath, '6��նԱȱ�ͼ.png']);
% close all;

%% ���������ͳ��
scrsz = get(0,'ScreenSize');
figure('Position',[scrsz(3)*1/4 scrsz(4)*1/6 scrsz(3)*4/5 scrsz(4)]*3/4);
subplot(2,2,1);
bar(Daily(2:end),DailyRet,'r','EdgeColor','r');
datetick('x',29);
axis([min(Daily(2:end)) max(Daily(2:end)) min(DailyRet) max(DailyRet)]);
xlabel('ʱ��');
ylabel('��������');

subplot(2,2,2);
bar(Weekly(2:end),WeeklyRet,'r','EdgeColor','r');
datetick('x',29);
axis([min(Weekly(2:end)) max(Weekly(2:end)) min(WeeklyRet) max(WeeklyRet)]);
xlabel('ʱ��');
ylabel('��������');

subplot(2,2,3);
bar(Monthly(2:end),MonthlyRet,'r','EdgeColor','r');
datetick('x',28);
axis([min(Monthly(2:end)) max(Monthly(2:end)) min(MonthlyRet) max(MonthlyRet)]);
xlabel('ʱ��');
ylabel('��������');

subplot(2,2,4);
bar(Yearly(2:end),YearlyRet,'r','EdgeColor','r');
datetick('x',10);
axis([min(Yearly(2:end)) max(Yearly(2:end)) min(YearlyRet) max(YearlyRet)]);
xlabel('ʱ��');
ylabel('��������');
saveas(gcf, [dirPath, '7���������ͳ��.png']);
% close all;