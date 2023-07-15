% this script will carry out 2-class classifier on adults only, and using
% 0,1 events (normal) vs 2 or more events (abnormal) 

%% clear and load the data
March162021A;

% remove spacer variable since there are no 1s
data_priortoHotEncode.Spacer=[];

%% Split the data and keep the testing data (Scotland/Wales) aside
I_train=(find(data.Country=='England' & data.age>=18));
I_test=(find( (data.Country=='Wales' | data.Country=='Scotland') & data.age>=18) );

I_train=(find(data.Country=='England' & data.age<18));
I_test=(find( (data.Country=='Wales' | data.Country=='Scotland') & data.age<18) );

data_train=data(I_train,:);
data_test=data(I_test,:);

data_train_nhe=data_priortoHotEncode(I_train,:);
data_test_nhe=data_priortoHotEncode(I_test,:);
%% assign X (feature matrix) and output, Y

Y_train=data_train.outcome_0vsAny;
X_train=data_train(:,[1:18,21:35]);

X_train_nhe=data_train_nhe;

Y_test=data_test.outcome_012vs3;
X_test=data_test(:,[1:18,21:35]);

%% Let us now train using no resampling first (and set these variables for classification learner)

Data_train=X_train;
Data_train.outcome=Y_train;

Data_train_nhe=X_train_nhe;
Data_train_nhe.outcome=Y_train;

%% Training and Testing (Internally) without any resampling
% Perform cross-validation
KFolds = 5;
%rng(1); % to ensure reproducibility
cvp = cvpartition(Y_train, 'KFold', KFolds);
% Initialize the predictions to the proper sizes
%validationPredictions = NaN(size(Y_train));
numObservations = size(X_train, 1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Logistic regression %%%%%%%%%%%%%%%%%%%%%%
validationScores = NaN(numObservations, 1);
for kfold=1:KFolds
    disp(['Procesing Fold number: ',num2str(kfold)]);
    X_train_sel=X_train(cvp.training(kfold),:);
    Y_train_sel=Y_train(cvp.training(kfold),:);
    
    X_validate_sel=X_train(cvp.test(kfold),:);
    Y_validate_sel=Y_train(cvp.test(kfold),:);
   
    % train using logistic regression
    
    % but before training, perform class balancing to ensure that the 0 and
    % 1 classes are equal
    I_neg=find(Y_train_sel==0);
    I_pos=find(Y_train_sel==1);
    num_pos=length(I_pos);
    num_neg=length(I_pos);
    I_neg_sel=randsample(I_neg,num_pos);
    X_train_subsampled=X_train_sel([I_neg_sel;I_pos],:);
    Y_train_subsampled=Y_train_sel([I_neg_sel;I_pos],:);
    
    concatenatedPredictorsAndResponse = [X_train_subsampled, table(Y_train_subsampled)];
    % Train using fitglm.
    GeneralizedLinearModel = fitglm(...
        concatenatedPredictorsAndResponse, ...
        'Distribution', 'binomial', ...
        'link', 'logit');
    % validate 
     foldScores=predict(GeneralizedLinearModel,X_validate_sel);
    % store the scores in the original order 
     validationScores(cvp.test(kfold), :) = foldScores;
end

% Compute validation accuracy
correctPredictions = ((validationScores>0.5) == Y_train);
validationAccuracy = sum(correctPredictions)/length(correctPredictions);

% Get AUC using ROC
[X_ROC,Y_ROC,~,AUC_ROC]=perfcurve(Y_train,validationScores,1);

% Get AUC using PrecisionRecall
[X_PR,Y_PR,~,AUC_PR]=perfcurve(Y_train,validationScores,1,'XCrit','reca','YCrit','prec');


% Store results
AllResults.LR.AUC_ROC=AUC_ROC;
AllResults.LR.X_ROC=X_ROC;
AllResults.LR.Y_ROC=Y_ROC;

AllResults.LR.AUC_PR=AUC_PR;
AllResults.LR.X_PR=X_PR;
AllResults.LR.Y_PR=Y_PR;
