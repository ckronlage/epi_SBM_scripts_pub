function [ROCstats, lesionlabel_thresh_FPFs, hypothesislabel_thresh_FPFs, AUC_AFROC_lesional, AUC_AFROC_hypothesis] = ...
    s050_analyse_clusters (varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load and set variables
addpath('/home/ckronlage/epi/epi_SBM_scripts');
s019_set_variables;

% intialize pseudorandom generator
rng('shuffle');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% load sphere surface, needed for cluster centroid estimation
[sphere, f] = read_surf('fsaverage_sym/surf/lh.sphere');

% construct graph representation of fsaverage_sym lh surface mesh
% for clustering
edges = uint32([ f(:,1) f(:,2) ; f(:,2) f(:,3) ])+1;
edges = sort(edges,2);
edges = unique(edges,"rows");
surfgraph = graph(edges(:,1),edges(:,2));
surfgraph.Nodes.VertexNo = [1:height(surfgraph.Nodes)]';


% load cortex label and adjust for matlab 1-based indexing
cortex = read_label('','fsaverage_sym/label/lh.cortex');
cortex = cortex(:,1)+1;
noncortex = setdiff(1:length(sphere),cortex);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% parse arguments

OPTION = {};

suffix='';
measure='';
class_pred_map='';

switch nargin
    case 0
        error("no arguments");
    case 1
        if strcmp(varargin{1},'rand_sim')
            OPTION = "RAND_SIM";
            disp("performing random cluster simulation")
            
        else
            error("wrong arguments")
        end
    case 3
        switch varargin{1}
            case 'classifier_pred_map'
                OPTION = "CLASSIFIER_PRED_MAP";
                disp("performing classifier prediction map analysis")
                
                suffix = varargin{2};
                class_pred_map = varargin{3};
                
            case 'glm_z_map'
                OPTION = "GLM_Z_MAP";
                disp("performing GLM z map analysis")
                
                suffix = varargin{2};
                measure = varargin{3};

                if ~any(matches(listofmeasures,measure))
                    error(strcat("wrong measure: ",measure));
                end
            otherwise
                error("wrong arguments")
        end
        if ~any(matches(listofsuffixes,suffix))
            error(strcat("wrong suffix: ",suffix));
        end
    otherwise
        error("wrong arguments")
end
%}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% perform ROC analysis, loop over all thresholds and subjects

ROCstats = table('Size',[0 7],...
    'VariableTypes',{'double','double','double',...
    'double','double','cell','cell'},...
    'VariableNames',{'threshold','TPF_hypothesislabels','TPF_lesionlabels',...
    'FPF_controlsubjects','FPR_clusters','detected_hypothesislabels','detected_lesionlabels'});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load ground truth labels (in memory for speed)

groundtruthlabels = s049_load_groundtruthlabels();
% for stats analysis, we use the wide/dilated versions of the lesion labels
groundtruthlabels = groundtruthlabels(strcmp({groundtruthlabels.version},'wide'));

% lists for stats calculations
listoflesionlabels = unique({groundtruthlabels(strcmp({groundtruthlabels.type},'lesion')).identifier});
listofhypothesislabels = unique({groundtruthlabels(strcmp({groundtruthlabels.type},'hypothesis')).identifier});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


switch OPTION
    case "RAND_SIM"
        % generate random data
        statmaps = rand(length(listofsubjects),2,length(sphere));

        thresholds = sort(reshape(statmaps,1,[]));
        thresholds = thresholds(unique(round(logspace(0,3,100))));
       % startthreshold = min(statmaps,[],'all');
       % thresh_multiplier = 1.3;


    case {"CLASSIFIER_PRED_MAP", "GLM_Z_MAP"}
        statmaps = zeros(length(listofsubjects),2,length(sphere));

        for i_subject = 1:length(listofsubjects)
            subject = listofsubjects{i_subject};
            disp(strcat("reading data for ",subject,suffix," ",measure,class_pred_map))
        
            for i_hemi = 1:length(hemis)
                hemi = hemis{i_hemi};
         
                % different paths to files
                if strcmp(OPTION,"GLM_Z_MAP")  
                    pathtostatmap = strcat(subject,suffix,"/0GLM/",...
                    hemi,".",measure,".fsaverage_sym_glmdir/",...
                    "groupdiff/",...
                    "z.mgh");
        
                else % CLASSIFIER_PRED_MAP
                    pathtostatmap = strcat(subject,suffix,"/0CLASS/",...
                        hemi,".",class_pred_map,".fsaverage_sym.mgh");
                end
        
                map = MRIread(convertStringsToChars(pathtostatmap));
                statmaps(i_subject,i_hemi,:) = map.vol;

            end
        end

        % for GLM z-maps: two-tailed tests
        if strcmp(OPTION,"GLM_Z_MAP")  
            statmaps = abs(statmaps);
        end

        %startthreshold = max(statmaps,[],'all'); 
        %thresh_multiplier = 0.98;

        thresholds = sort(reshape(statmaps,1,[]),'descend');
        thresholds = thresholds(unique(round(logspace(3,6,100)))-1000+1);
end


% FPR_clusters_max = 10; % optional, for FROC analysis

%threshold = startthreshold;
FPF_controlsubjects = 0;
FPR_clusters = 0;

lastthreshold_detectedlesionlabels = {};
lastthreshold_detectedhypothesislabels = {};

tic %timing


%while (FPF_controlsubjects < 1) % || (FPR_clusters < FPR_clusters_max) % optional, for FROC analysis
for threshold = thresholds
    listofFPcontrolsubjects = {};
    numberofFPclustersincontrols = 0;
    listofdetectedhypothesislabels = {};
    listofdetectedlesionlabels = {};

    for i_subject = 1:length(listofsubjects)
        subject = listofsubjects{i_subject};


        % threshold and cluster z-map

        for i_hemi = 1:length(hemis)
            hemi = hemis{i_hemi};
        
            % select relevant ground truth labels (subject and hemi)
            labelstocheck = groundtruthlabels(strcmp({groundtruthlabels.subject},subject));
            labelstocheck = labelstocheck(strcmp({labelstocheck.hemi},hemi));

            switch OPTION
                case "RAND_SIM"
                    rand_subjhemi_data = squeeze(statmaps(i_subject,i_hemi,:));
                    clusterindices = intersect(find(rand_subjhemi_data < threshold),cortex);
               
               case {"CLASSIFIER_PRED_MAP", "GLM_Z_MAP"}
                    statmap_subjhemi_data = squeeze(statmaps(i_subject,i_hemi,:));
        
                    nodes_to_strip = find(statmap_subjhemi_data < threshold);
                    nodes_to_strip = union(nodes_to_strip,noncortex);
                    clustergraph = rmnode(surfgraph,nodes_to_strip);
                    bins = conncomp(clustergraph);
                    clusterindices = unique(bins);

            end
            
            % loop over clusters
            for i_clust = 1:length(clusterindices)
                clusterid = clusterindices(i_clust);

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % score centroid match with respect to subject group and
                % ground truth labels

                if subject(1:1) == 'C'
                    if ~any(matches(listofFPcontrolsubjects,subject))
                        listofFPcontrolsubjects = [listofFPcontrolsubjects subject];
                    end
                    numberofFPclustersincontrols = numberofFPclustersincontrols +1;
                else
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % determine cluster centroid
                    switch OPTION
                        case "RAND_SIM"
                            centroid_vertex_index = clusterid;
                            
                        case {"CLASSIFIER_PRED_MAP", "GLM_Z_MAP"}
                            clust_vertexindices = clustergraph.Nodes.VertexNo(bins==clusterid);
    
                            % raw centroid vector is mean of all vectors in label
                            raw_centroid = mean(sphere(clust_vertexindices,:),1);
    
                            % scale to length 100
                            centroid = raw_centroid.*(100/norm(raw_centroid));
    
                            % find cluster vertex that is closest to centroid
                            diff = sphere(clust_vertexindices,:)-centroid;
                            dist = sqrt(sum(diff.^2,2));
                            [~,centroid_vertex_index] = min(dist);
                            centroid_vertex_index = clust_vertexindices(centroid_vertex_index);
                           
                            % reminder: centroid_vertex_index is in matlab indexing
                            % (1 greater than freesurfer index)
                    end    
                
                    for label = labelstocheck
                        if (~isempty(fieldnames(label))) && ismember(centroid_vertex_index,label.data)
                            % cluster centroid "matches" ground truth label
                            if any(matches(listofhypothesissubjects,subject)) && ~any(matches(listofdetectedhypothesislabels,label.identifier))
                                listofdetectedhypothesislabels = [listofdetectedhypothesislabels label.identifier];
                            end
                            if any(matches(listoflesionalsubjects,subject)) && ~any(matches(listofdetectedlesionlabels,label.identifier))
                                listofdetectedlesionlabels = [listofdetectedlesionlabels label.identifier];
                            end
                        end % if cluster match
                        
                        
                    end % ground truth labels loops
                end % if/else control subject


            end % clusters loop
        end % hemis loop
    end % listofsubjects loop


    TPF_hypothesislabels = length(listofdetectedhypothesislabels)/length(listofhypothesislabels);
    TPF_lesionlabels = length(listofdetectedlesionlabels)/length(listoflesionlabels);
    FPF_controlsubjects = length(listofFPcontrolsubjects) / length(listofcontrolsubjects);
    FPR_clusters = numberofFPclustersincontrols / length(listofcontrolsubjects);

    new_detectedhypothesislabels = setdiff(listofdetectedhypothesislabels,lastthreshold_detectedhypothesislabels);
    new_detectedlesionlabels = setdiff(listofdetectedlesionlabels,lastthreshold_detectedlesionlabels);

    lastthreshold_detectedhypothesislabels = listofdetectedhypothesislabels;
    lastthreshold_detectedlesionlabels = listofdetectedlesionlabels;

    ROCstats(end+1,:) = {threshold,TPF_hypothesislabels,TPF_lesionlabels,FPF_controlsubjects,FPR_clusters,...
        {new_detectedhypothesislabels},{new_detectedlesionlabels}};

    disp(strcat("threshold: ",num2str(threshold),...
    " | FPF_controlsubjects: ",num2str(FPF_controlsubjects),...
    " | FPR_clusters: ",num2str(FPR_clusters)));

    %threshold = threshold * thresh_multiplier;
    %threshold = threshold*thresh_multiplier;

    if FPF_controlsubjects >= 1
        break;
    end
end % threshold


if OPTION == "RAND_SIM"
    % Simulated thresholds are different from GLM z-maps and
    % classifier output maps. -log10 to make things consistent so that
    % sorting works
    ROCstats{:,1} = -log10(ROCstats{:,1});
end


%calculate AUCs
if ( ( min(ROCstats.TPF_hypothesislabels) > 0 && min(ROCstats.FPF_controlsubjects) > 0 ) ...
        || ...
     ( min(ROCstats.TPF_lesionlabels) > 0 && min(ROCstats.FPF_controlsubjects) > 0 ) )
    %error("ROC data does not contain sufficiently strict thresholds")
end

if (max(ROCstats.FPF_controlsubjects) < 1.0 )
    %error("ROC data does not contain sufficiently relaxed thresholds")
end

ROCstats = sortrows(ROCstats,1,'descend');

AUC_AFROC_lesional = abs(trapz(ROCstats.FPF_controlsubjects,ROCstats.TPF_lesionlabels));
AUC_AFROC_hypothesis = abs(trapz(ROCstats.FPF_controlsubjects,ROCstats.TPF_hypothesislabels));


%%%%%
lesionlabel_thresh_FPFs = [];

for lesionlabel = listoflesionlabels        
    lesionlabel_thresh_FPFs(find(matches(listoflesionlabels,lesionlabel))) = Inf;
    for i = 1:size(ROCstats,1)
        if matches(ROCstats.detected_lesionlabels{i},lesionlabel)
            lesionlabel_thresh_FPFs(find(matches(listoflesionlabels,lesionlabel))) = ...
              ROCstats.FPF_controlsubjects(i);
              break;
        end
    end
end


hypothesislabel_thresh_FPFs = [];

for hypothesislabel = listofhypothesislabels        
    hypothesislabel_thresh_FPFs(find(matches(listofhypothesislabels,hypothesislabel))) = Inf;
    for i = 1:size(ROCstats,1)
        if matches(ROCstats.detected_hypothesislabels{i},hypothesislabel)
            hypothesislabel_thresh_FPFs(find(matches(listofhypothesislabels,hypothesislabel))) = ...
              ROCstats.FPF_controlsubjects(i);
              break;
        end
    end
end


switch OPTION
    case "RAND_SIM"
        % random filenames for simulated data
        statsfilename = strcat(tempname('0rand_stats/'),'.mat');
    case "CLASSIFIER_PRED_MAP"
        statsfilename = strcat('0stats/','ROCstats',suffix,'.',class_pred_map,'.mat');
    case "GLM_Z_MAP"
        statsfilename = strcat('0stats/','ROCstats',suffix,'.',measure,'.mat');
end
    
% writetable(ROCstats,statsfilename);    
disp(statsfilename);
save(statsfilename,'ROCstats','AUC_AFROC_hypothesis','AUC_AFROC_lesional','lesionlabel_thresh_FPFs','hypothesislabel_thresh_FPFs');

toc

end
