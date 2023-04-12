function s046_run_classifier(suffix, subject, opt_usedmeasures)

% set(0,'DefaultFigureWindowStyle','docked');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load and set variables
addpath('/home/ckronlage/epi/epi_SBM_scripts');
s019_set_variables;

% rng('default');
rng('shuffle');

% check arguments
if ~any(matches(listofsuffixes,suffix))
    error("wrong arguments")
end

% load sphere surface, needed for cluster centroid estimation
sphere = read_surf('fsaverage_sym/surf/lh.sphere');

% load cortex label and adjust for matlab 1-based indexing
cortex = read_label('','fsaverage_sym/label/lh.cortex');
cortex = cortex(:,1)+1;
noncortex = setdiff(1:length(sphere),cortex);


% for classifier training analysis, we use the non-dilated versions of the
% lesion labels
lesionlabels = s049_load_groundtruthlabels();
lesionlabels = lesionlabels(strcmp({lesionlabels.type},'lesion'));
lesionlabels = lesionlabels(strcmp({lesionlabels.version},'strict'));

bestmeasures = {'nthickness' 'FLAIR_intensity.projfrac_0.50' 'FLAIR_intensity.projdist_-1' 'nu_intensity.projfrac_0.50' 'nu_intensity.projdist_-1' 'w-g.pct'};
bestmeasures = listofmeasures(contains(listofmeasures,bestmeasures));

switch opt_usedmeasures
    case 1
        usedmeasures = listofmeasures;
    case 2
        usedmeasures = listofmeasures(~contains(listofmeasures,'FLAIR'));
    case 3
        usedmeasures = listofmeasures_GLM;
    case 4
        usedmeasures = listofmeasures_GLM(~contains(listofmeasures_GLM,'FLAIR'));
    case 5
        usedmeasures = bestmeasures;
    case 6
        usedmeasures = bestmeasures(~contains(bestmeasures,'FLAIR'));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
% gather all training data

ctrldata_supsampling_factor = 0.005;
subsampling_set = randperm(length(cortex),uint64(length(cortex)*ctrldata_supsampling_factor));

train_ctrldata = [];
train_lesionaldata = [];

for i_measure = 1:length(usedmeasures)
    measure = usedmeasures(i_measure);
    disp(strcat("reading measure ",num2str(i_measure),"/",num2str(length(usedmeasures))));
    
    permeas_allctrlsubjs_data = [];

    listoftrainctrlsubjects = setdiff(listofcontrolsubjects,subject);
    for i_ctrlsubj = 1:length(listoftrainctrlsubjects)
        controlsubject = listoftrainctrlsubjects(i_ctrlsubj); 

        for i_hemi = 1:length(hemis)
            hemi = hemis(i_hemi);

            %disp(strcat(comparedsubject," ",pad(hemi,10)," ",measure))
            
            pathtodata = strcat(controlsubject,suffix,"/0surf_features/",...
                    hemi,".",measure,".fsaverage_sym.mgh");

            rawdata = MRIread(convertStringsToChars(pathtodata));
            permeas_allctrlsubjs_data(i_ctrlsubj,i_hemi,:) = rawdata.vol;


        end % hemi loop
   
    end % listofcontrolsubjects loop
    
    permeas_allctrlsubjs_data(:,:,noncortex) = NaN;

    % normalize per subject (both hemis)
    permeas_allctrlsubjs_data_norm = (permeas_allctrlsubjs_data - mean(permeas_allctrlsubjs_data,[2 3],'omitnan')) ./ std(permeas_allctrlsubjs_data,0,[2 3],'omitnan');

    % normalize per vertex
    [permeas_allctrlsubjs_data_norm, mu(i_measure,:,:), sigma(i_measure,:,:)] = ...
        normalize(permeas_allctrlsubjs_data_norm,1);
    
    % select only cortical vertices
    permeas_allctrlsubjs_data = permeas_allctrlsubjs_data(:,:,cortex);
    permeas_allctrlsubjs_data_norm = permeas_allctrlsubjs_data_norm(:,:,cortex);
    
    % optional: select random subset
    permeas_allctrlsubjs_data = permeas_allctrlsubjs_data(:,:,subsampling_set);
    permeas_allctrlsubjs_data_norm = permeas_allctrlsubjs_data_norm(:,:,subsampling_set);

%    train_ctrldata(end+1,:) = reshape(permeas_allctrlsubjs_data,1,[]);
    train_ctrldata(end+1,:) = reshape(permeas_allctrlsubjs_data_norm,1,[]);

    %%%%%%%%%%%%% lesional data

    permeas_alllesionsubjs_data = [];
    permeas_alllesionsubjs_data_norm = [];
    for lesionlabel = lesionlabels
        lesionsubject = lesionlabel.subject;
        if matches(lesionsubject,subject)
            continue;
        end

        i_lesionhemi = find(matches(hemis,lesionlabel.hemi));

        permeas_persubj_data = [];

        for i_hemi = 1:length(hemis)
            hemi = hemis(i_hemi);

            pathtodata = strcat(lesionsubject,suffix,"/0surf_features/",...
                    hemi,".",measure,".fsaverage_sym.mgh");

            rawdata = MRIread(convertStringsToChars(pathtodata));
            permeas_persubj_data(i_hemi,:) = rawdata.vol;

        end % hemi loop
               
        permeas_persubj_data(:,noncortex) = NaN;
                
        % normalize per subject (both hemis)
        permeas_persubj_data_norm = (permeas_persubj_data - mean(permeas_persubj_data,'all','omitnan')) ./ std(permeas_persubj_data,0,'all','omitnan');
               
        % normalize per vertex in relation to all control data
        permeas_persubj_data_norm = normalize(permeas_persubj_data_norm,...
            'center',squeeze(mu(i_measure,:,:)),...
            'scale',squeeze(sigma(i_measure,:,:)));      
        
        permeas_alllesionsubjs_data = [permeas_alllesionsubjs_data ...
            permeas_persubj_data(i_lesionhemi,lesionlabel.data)];
        permeas_alllesionsubjs_data_norm = [permeas_alllesionsubjs_data_norm ...
            permeas_persubj_data_norm(i_lesionhemi,lesionlabel.data)];

    end % lesionlabels loop

 %   train_lesionaldata(end+1,:) = permeas_alllesionsubjs_data;
    train_lesionaldata(end+1,:) = permeas_alllesionsubjs_data_norm;


end % measures loop

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% train

train_ctrldata_subset = train_ctrldata(:,randperm(length(train_ctrldata),length(train_lesionaldata)*10),:);

X = [ train_ctrldata_subset , train_lesionaldata ]';
Y = [ false(1,length(train_ctrldata_subset)) , true(1,length(train_lesionaldata)) ]';


rfc_mdl = fitcensemble(X,Y,'Method','Bag',...
    'NPrint',1,...
    'NumLearningCycles',100);

% one-class methods

ifst_mdl = iforest(train_ctrldata','NumObservationsPerLearner',2048);    

[mahsigma,mahmu] = robustcov(train_ctrldata',OutlierFraction=0);


%
% make class dir
status = system(strcat("mkdir -p ",subject,suffix,"/0CLASS"));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% predict

predict_data = [];

for i_measure = 1:length(usedmeasures)
    measure = usedmeasures(i_measure);
    
    permeas_data = [];

    for i_hemi = 1:length(hemis)
        hemi = hemis(i_hemi);

        pathtodata = strcat(subject,suffix,"/0surf_features/",...
                hemi,".",measure,".fsaverage_sym.mgh");

        rawdata = MRIread(convertStringsToChars(pathtodata));
        permeas_data(i_hemi,:) = rawdata.vol;

    end % hemi loop
           
    permeas_data(:,noncortex) = NaN;
            
    % normalize per subject (both hemis)
    permeas_data_norm = (permeas_data - mean(permeas_data,'all','omitnan')) ./ std(permeas_data,0,'all','omitnan');
           
    % normalize per vertex in relation to all control data
    permeas_data_norm = normalize(permeas_data_norm,...
        'center',squeeze(mu(i_measure,:,:)),...
        'scale',squeeze(sigma(i_measure,:,:)));      

%    predict_data(end+1,:,:) = permeas_data;
    predict_data(end+1,:,:) = permeas_data_norm;

end % measures loop



for i_hemi = 1:length(hemis)
    hemi = hemis(i_hemi);

    outdata = MRIread(convertStringsToChars(pathtodata));
    outdata.vol = zeros(size(outdata.vol));


    [~,rfc_scores] = predict(rfc_mdl,squeeze(predict_data(:,i_hemi,cortex))');
    rfc_scores = rfc_scores(:,2);


    outdata.vol(cortex) = rfc_scores;
    mapname = strcat(subject,suffix,"/0CLASS/",...
                        hemi,".RFC",...
                        ".usedmeasures",num2str(opt_usedmeasures),...
                        ".fsaverage_sym.nosmooth.mgh")
    MRIwrite(outdata,convertStringsToChars(mapname));
    % optional smoothing of output map
    system(strcat("mris_fwhm --s fsaverage_sym --hemi lh --cortex --smooth-only --fwhm 4 --i ",...
        mapname,...
        " --o ",...
        erase(mapname,".nosmooth")));

    [~,ifst_scores] = isanomaly(ifst_mdl,squeeze(predict_data(:,i_hemi,cortex))');
    outdata.vol(cortex) = ifst_scores;
    mapname = strcat(subject,suffix,"/0CLASS/",...
                        hemi,".IFST",...
                        ".usedmeasures",num2str(opt_usedmeasures),...
                        ".fsaverage_sym.nosmooth.mgh")
    MRIwrite(outdata,convertStringsToChars(mapname));
    % optional smoothing of output map
    system(strcat("mris_fwhm --s fsaverage_sym --hemi lh --cortex --smooth-only --fwhm 4 --i ",...
        mapname,...
        " --o ",...
        erase(mapname,".nosmooth")));

    mah_scores = pdist2(squeeze(predict_data(:,i_hemi,cortex))',mahmu,"mahalanobis",mahsigma);
    outdata.vol(cortex) = mah_scores;
    mapname = strcat(subject,suffix,"/0CLASS/",...
                        hemi,".MAH",...
                        ".usedmeasures",num2str(opt_usedmeasures),...
                        ".fsaverage_sym.mgh")
    MRIwrite(outdata,convertStringsToChars(mapname));


end % hemi loop
   
end
