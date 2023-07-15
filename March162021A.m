%clc;clear all;

load dataoutcome15March2021;
load datafeatures08Feb2021;

data=datafeatures08Feb2021;
dataoutcomes=dataoutcomes15March2021;
% add outcome data now
data.outcome_3months=dataoutcomes.outcome_3months;
data.outcome_6months=dataoutcomes.outcome_6months;
data.outcome_9months=dataoutcomes.outcome_9months;
data.outcome_12months=dataoutcomes.outcome_12months;
data.outcome_15months=dataoutcomes.outcome_15months;
data.outcome_18months=dataoutcomes.outcome_18months;
data.outcome_21months=dataoutcomes.outcome_21months;
data.outcome_24months=dataoutcomes.outcome_24months;

%% data cleaning
% remove unwanted variable
data.VarName1=[];
% Sex
IR=find(ismissing(data.sex));
data(IR,:)=[];

% For age, remove those with negative age (WTH)
IR=find(data.age<0);
data(IR,:)=[];

% for BMI, remove anyone below 15, or above 50
IR=find(data.BMI<15 | data.BMI>50);
data(IR,:)=[];
% keep any BMI that is missing as NaN


% for smoking, anyone with no record, consider them non-smoker
IC=find(data.smokingStatus=='NA');
data.smokingStatus(IC)='never';

% for PEF, re-assign those with no data as a new category
ID=find(data.PEFStatus=='NA');
data.PEFStatus(ID)='not recorded';

% Eosinophil count, re-assign the unknown as unknown
ID=find(data.EosinophilLevel=='NA');
data.EosinophilLevel(ID)='unknown';

% BTS Step (if none recorded, it means that they are at step 0
IC=find(ismissing(data.BTS_step));
data.BTS_step(IC)=0;

% ICS measures
IC=find(ismissing(data.average_daily_dose_ICS));
data.average_daily_dose_ICS(IC)=0;

IC=find(ismissing(data.prescribed_daily_dose_ICS));
data.prescribed_daily_dose_ICS(IC)=0;

IC=find(ismissing(data.ICS_medication_possesion_ratio));
data.ICS_medication_possesion_ratio(IC)=0;

IC=find((data.DeviceType=='NA'));
data.DeviceType(IC)='unknown';

% Spacer needs to be looked at !!!!
IC=find(ismissing(data.Spacer));
data.Spacer(IC)=0;

% numOCS
IC=find(ismissing(data.numOCS));
data.numOCS(IC)=0;

% numPCS
IC=find(ismissing(data.numPCS));
data.numPCS(IC)=0;

% numAntibioticsEvents
IC=find(ismissing(data.numAntibioticsEvents));
data.numAntibioticsEvents(IC)=0;

% numAntibioticswithLRTI
IC=find(ismissing(data.numAntibioticswithLRTI));
data.numAntibioticswithLRTI(IC)=0;

% numOCSEvents
IC=find(ismissing(data.numOCSEvents));
data.numOCSEvents(IC)=0;

% numOCSwithLRTI
IC=find(ismissing(data.numOCSwithLRTI));
data.numOCSwithLRTI(IC)=0;

% numAsthmaAttacks
IC=find(ismissing(data.numAsthmaAttacks));
data.numAsthmaAttacks(IC)=0;

% numAcuteRespEvents
IC=find(ismissing(data.numAcuteRespEvents));
data.numAcuteRespEvents(IC)=0;

% Prior Education (if missing, assume none)
IC=find(ismissing(data.PriorEducation));
data.PriorEducation(IC)=0;

% numPCSAsthma
IC=find(ismissing(data.numPCSAsthma));
data.numPCSAsthma(IC)=0;

% CharlsonScore
IC=find(ismissing(data.CharlsonScore));
data.CharlsonScore(IC)=0;

%%% convert categorical variables to numeric

% numHospEvents
IC=find(data.numHospEvents=='NA');
data.numHospEvents(IC)='0';
data.numHospEvents=str2num(char(data.numHospEvents));


%% Let us now try to process the data predictors to make them fit for 
data_raw=data;




%% process data now



% before one-hot encoding, relabel the categories for easy identificaiton

data.smokingStatus=removecats(data.smokingStatus);
categories(data.smokingStatus);
data.smokingStatus=renamecats(data.smokingStatus,{'smoking_current','smoking_former','smoking_never'});    


data.PEFStatus=removecats(data.PEFStatus);
categories(data.PEFStatus);
data.PEFStatus=renamecats(data.PEFStatus,{'PEF_60_80','PEF_less_than_60','PEF_more_than_80','not_recorded'});    


data.EosinophilLevel=removecats(data.EosinophilLevel);
categories(data.EosinophilLevel);
data.EosinophilLevel=renamecats(data.EosinophilLevel,{'Eosinophil_high','Eosinophil_normal','Eosinophil_unknown'});    



data.DeviceType=removecats(data.DeviceType);
categories(data.DeviceType);
data.DeviceType=renamecats(data.DeviceType,{'DeviceType_BAI','DeviceType_DPI','DeviceType_NEB','DeviceType_pMDI','DeviceType_unknown'});    


% let us now discretize BMI into bins
edges=[0 18.5 25 30 51];
data.BMI_categories=discretize(data.BMI,edges,'categorical');
data.BMI_categories=removecats(data.BMI_categories);
categories(data.BMI_categories);
data.BMI_categories=renamecats(data.BMI_categories,{'underweight','normalweight','overweight','obese'});    

data.BMI_categories=addcats(data.BMI_categories,{'BMInotrecorded'},'Before','underweight');
IC=find(ismissing(data.BMI_categories));
data.BMI_categories(IC)='BMInotrecorded';

data_priortoHotEncode=data(:,[3,4,6:26,37]);


% one-hot encode now
%encData = table();
for i=[6,8,9,37]
 data = [data onehotencode(data(:,i))]; 
end

% remove the columns that have been hot-encoded
data.smokingStatus=[];
data.PEFStatus=[];
data.EosinophilLevel=[];
data.DeviceType=[];
data.BMI=[];
data.BMI_categories=[];

% let us now normalize average_daily_dose_ICS, prescribed_daily_dose_ICS, 
data.average_daily_dose_ICS=data.average_daily_dose_ICS./median(data.average_daily_dose_ICS);
data.prescribed_daily_dose_ICS=data.prescribed_daily_dose_ICS./median(data.prescribed_daily_dose_ICS);



%% create new outcome variables

%outcome that counts total number of events
data.outcome_combined=data.outcome_3months+data.outcome_6months+data.outcome_9months+...
    data.outcome_12months+data.outcome_15months+data.outcome_18months+...
    data.outcome_21months+data.outcome_24months;

%outcome: 0 vs 1 or more
I1M=find(data.outcome_combined>=1);
I0=find(data.outcome_combined<1);
data.outcome_0vsAny=-1*ones(size(data.outcome_combined,1),1);
data.outcome_0vsAny(I1M)=1;
data.outcome_0vsAny(I0)=0;

%outcome: 0-1 vs 2 or more
I2M=find(data.outcome_combined>=2);
I01=find(data.outcome_combined<2);
data.outcome_01vs2=-1*ones(size(data.outcome_combined,1),1);
data.outcome_01vs2(I2M)=1;
data.outcome_01vs2(I01)=0;

%outcome: 0-2 vs 3 or more
I3M=find(data.outcome_combined>=3);
I012=find(data.outcome_combined<3);
data.outcome_012vs3=-1*ones(size(data.outcome_combined,1),1);
data.outcome_012vs3(I3M)=1;
data.outcome_012vs3(I012)=0;

%outcome: 0-3 vs 4 or more
I4M=find(data.outcome_combined>=4);
I0123=find(data.outcome_combined<4);
data.outcome_0123vs4=-1*ones(size(data.outcome_combined,1),1);
data.outcome_0123vs4(I4M)=1;
data.outcome_0123vs4(I0123)=0;

%%
% % remove columns not required
% data.patid=[];
% data.practice_id=[];
% data.Spacer=[];
% data.outcome_3months=[];
% data.outcome_6months=[];
% data.outcome_12months=[];
% data.outcome_18months=[];
% data.outcome_24months=[];


%% plot the distribution of combined outcome
I4=find(data.outcome_combined>=4);


length(find(data.outcome_3months==1))+length(find(data.outcome_6months==1))+...
    +length(find(data.outcome_9months==1))+length(find(data.outcome_12months==1))...
    +length(find(data.outcome_15months==1))+length(find(data.outcome_18months==1))...
    +length(find(data.outcome_21months==1))+length(find(data.outcome_24months==1));

%% let us plot the percentage of patients with outcomes
figure,histogram(data.outcome_combined,'Normalization','probability')
yticklabels(yticks*100)
xlabel('number of asthma attacks in 2 years of follow-up')
ylabel('proportion of patients (%)')
set(gca(),'FontSize',18)

%% let us now start with a quick classification test

% remove unwanted columns
data.patid=[];
data.practice_id=[];
data.Spacer=[];
data.outcome_3months=[];
data.outcome_6months=[];
data.outcome_9months=[];
data.outcome_12months=[];
data.outcome_15months=[];
data.outcome_18months=[];
data.outcome_21months=[];
data.outcome_24months=[];
%data.outcome_01vs2=[];
%data.outcome_0123vs4=[];
%data.outcome_0vsAny=[];
data.outcome_combined=[];

