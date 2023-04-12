clear
%close all
set(0,'DefaultFigureWindowStyle','docked');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load and set variables
addpath('/home/ckronlage/epi/epi_SBM_scripts');
s019_set_variables;

cortex = read_label('','fsaverage_sym/label/lh.cortex');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load ground truth labels (in memory for speed)

groundtruthlabels = s049_load_groundtruthlabels();
% for stats analysis, we use the wide/dilated versions of the lesion labels
groundtruthlabels = groundtruthlabels(strcmp({groundtruthlabels.version},'wide'));

% lists for stats calculations
listoflesionlabels = unique({groundtruthlabels(strcmp({groundtruthlabels.type},'lesion')).identifier});
listofhypothesislabels = unique({groundtruthlabels(strcmp({groundtruthlabels.type},'hypothesis')).identifier});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1) read simulated random AFROC data

% prepare plots
figure;
t = tiledlayout(1,2);
t.TileSpacing = 'compact';
t.Padding = 'compact';

ax_AFROC_hypothesis_figure = nexttile;
axis('square');
axis([0 1 0 1]);
set(gca,'xtick',[0 0.2 0.4 0.6 0.8 1.0])
set(gca,'ytick',[0 0.2 0.4 0.6 0.8 1.0])
hold(ax_AFROC_hypothesis_figure,'on');

ax_AFROC_lesional_figure = nexttile;
axis('square');
axis([0 1 0 1]);
set(gca,'xtick',[0 0.2 0.4 0.6 0.8 1.0])
set(gca,'ytick',[0 0.2 0.4 0.6 0.8 1.0])
hold(ax_AFROC_lesional_figure,'on');


rand_stats_filelist = dir(['0rand_stats/*.mat']);
rand_stats_filelist = {rand_stats_filelist.name};

rand_AUC_AFROC_lesional = [];
rand_AUC_AFROC_hypothesis = [];
rand_hypothesis_firstPFP = [];

all_rand_data = table();

for i_stats_filelist = 1:length(rand_stats_filelist)
    disp(i_stats_filelist/length(rand_stats_filelist))
    
    rand_data = load(strcat('0rand_stats/',rand_stats_filelist{i_stats_filelist}));
    rand_ROCtable = rand_data.ROCstats;
    rand_AUC_AFROC_lesional(i_stats_filelist) = rand_data.AUC_AFROC_lesional;
    rand_AUC_AFROC_hypothesis(i_stats_filelist) = rand_data.AUC_AFROC_hypothesis;
    rand_hypothesis_firstPFP(i_stats_filelist,:) = rand_data.hypothesislabel_thresh_FPFs(:);

    all_rand_data = [all_rand_data; rand_ROCtable(:,1:5)];   

end


% fit (and plot) an approximate model based on poisson distribution

model_rand_AFROC_TPF = @(phi,x) 1-(1-x).^phi;

model_rand_AFROC_hypothesis = fit(all_rand_data.FPF_controlsubjects,all_rand_data.TPF_hypothesislabels,model_rand_AFROC_TPF,'StartPoint',[0.2],'Lower',[0],'Upper',[1])
%plot(ax_AFROC_hypothesis_figure,[0:0.001:1],model_rand_AFROC_hypothesis([0:0.001:1]),'b--');

model_rand_AFROC_lesional = fit(all_rand_data.FPF_controlsubjects,all_rand_data.TPF_lesionlabels,model_rand_AFROC_TPF,'StartPoint',[0.2],'Lower',[0],'Upper',[1])
%plot(ax_AFROC_lesional_figure,[0:0.001:1],model_rand_AFROC_lesional([0:0.001:1]),'r--')

%%
% plot AUC histograms
figure
t = tiledlayout(1,2);
t.TileSpacing = 'compact';
t.Padding = 'compact';

nexttile
histogram(rand_AUC_AFROC_hypothesis,[0:0.01:0.4],...
    'FaceColor','blue','EdgeColor','none',...
    'Normalization','pdf')
set(gca,'ytick',[])
xlim([0 0.4])
title("rand_AUC_AFROC_hypothesis",'Interpreter','none')

nexttile
histogram(rand_AUC_AFROC_lesional,[0:0.01:0.4],...
    'FaceColor','red','EdgeColor','none',...
    'Normalization','pdf')
set(gca,'ytick',[])
xlim([0 0.4])
title("rand_AUC_AFROC_lesional",'Interpreter','none')


hold off

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2) read AFROC data from GLM and classifier maps
%    and computer p-values etc.

stats_filelist = dir(['0stats/ROC*.mat']);
stats_filelist = {stats_filelist.name};

stats = table('Size',[0 8],...
    'VariableTypes',...
    {'string','string','double','double','double','double','cell','cell'},...
    'VariableNames',...
    {'measure','suffix','AUC_AFROC_lesional','AUC_AFROC_hypothesis',...
    'p_AUC_AFROC_lesional','p_AUC_AFROC_hypothesis',...
    'p_lesion','p_hypothesis'});

for i_stats_filelist = 1:length(stats_filelist)        
    data = load(strcat('0stats/',stats_filelist{i_stats_filelist}));
    
    ROCstats = data.ROCstats;
    AUC_AFROC_lesional = data.AUC_AFROC_lesional;
    AUC_AFROC_hypothesis = data.AUC_AFROC_hypothesis;
    hypothesislabel_thresh_FPFs = data.hypothesislabel_thresh_FPFs;
    lesionlabel_thresh_FPFs = data.lesionlabel_thresh_FPFs;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % compute p-values using the empirical null distributions

    p_AUC_AFROC_lesional = ...
        (nnz( rand_AUC_AFROC_lesional >= AUC_AFROC_lesional ) + 1) ...
        / ...
        (length(rand_AUC_AFROC_lesional) + 1);
    
    p_AUC_AFROC_hypothesis = ...
        (nnz( rand_AUC_AFROC_hypothesis >= AUC_AFROC_hypothesis ) + 1) ...
        / ...
        (length(rand_AUC_AFROC_hypothesis) + 1);


    p_AUC_AFROC_lesional = -log10(p_AUC_AFROC_lesional);
    p_AUC_AFROC_hypothesis = -log10(p_AUC_AFROC_hypothesis);
    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % compute per-subject lowest detection FPF

    p_lesion = [];
    for i_lesion = 1:length(listoflesionlabels)
        % calculate phi (ratio of label size to whole cortex)
        lesionlabel = listoflesionlabels(i_lesion);
        labelsize = 0;
        for g = groundtruthlabels(strcmp({groundtruthlabels.identifier},lesionlabel))
            labelsize = labelsize + length(g.data);
        end
        phi = labelsize/(2*length(cortex));
        
        detection_FPF = lesionlabel_thresh_FPFs(i_lesion);
        if detection_FPF == Inf
            detection_FPF = 1;
        end
        p_lesion(i_lesion) = 1-(1-detection_FPF).^(phi);
    end

    p_hypothesis = [];
    for i_hypothesis = 1:length(listofhypothesislabels)
        % calculate phi (ratio of label size to whole cortex)
        hypothesislabel = listofhypothesislabels(i_hypothesis);
        labelsize = 0;
        for g = groundtruthlabels(strcmp({groundtruthlabels.identifier},hypothesislabel))
            labelsize = labelsize + length(g.data);
        end
        phi = labelsize/(2*length(cortex));
        
        detection_FPF = hypothesislabel_thresh_FPFs(i_hypothesis);
        if detection_FPF == Inf
            detection_FPF = 1;
        end
        p_hypothesis(i_hypothesis) = 1-(1-detection_FPF).^(phi);
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % save stats in a table for comparison and visualization later on
    
    stats_attributes = strsplit(stats_filelist{i_stats_filelist},'.');
    measure = strjoin({stats_attributes{2:end-1}},'.');
    suffix = strsplit(stats_attributes{1},'_');
    suffix = suffix{2};
    
    stats(end+1,:) = {...
        measure,suffix,...
        AUC_AFROC_lesional,AUC_AFROC_hypothesis,...
        p_AUC_AFROC_lesional,p_AUC_AFROC_hypothesis...
        {p_lesion},{p_hypothesis}};
    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % plot individual AFROC curves if needed
    % (e.g. 'IFST.usedmeasures5' in this case)

   %{
    if contains(measure,'IFST.usedmeasures5')
        figure
        t = tiledlayout(1,2);
        t.TileSpacing = 'compact';
        t.Padding = 'compact';
        nexttile
        hold on;
        axis('square');
        axis([0 1 0 1]);

        plot(ROCstats{:,4},ROCstats{:,3},'Marker','.','Color','b');
        xlabel("FPF",'Interpreter', 'none');
        ylabel("TPF",'Interpreter', 'none');
        %text(0.99,0.99,...
        %    {strcat("AUC_AFROC_lesional = ",num2str(AUC_AFROC_lesional,'%.3f'))
        %    strcat("-log10(p) = ",num2str(p_AUC_AFROC_lesional,'%.5f'))},...
        %    'Color','r','HorizontalAlignment','right','VerticalAlignment','top','Interpreter','none')

        plot([0:0.01:1],model_rand_AFROC_lesional([0:0.01:1]),'Color',[1.0, 0.9, 0.9])

        nexttile
        hold on;
        axis('square');
        axis([0 1 0 1]);

        plot(ROCstats{:,4},ROCstats{:,2},'Marker','.','Color','b');
        xlabel("FPF_controlsubjects",'Interpreter', 'none');
        ylabel("TPF_labels",'Interpreter', 'none');
        text(0.99,0.99,...
            {strcat("AUC_AFROC_hypothesis = ",num2str(AUC_AFROC_hypothesis,'%.3f'))
            strcat("-log10(p) = ",num2str(p_AUC_AFROC_hypothesis,'%.5f'))},...
            'Color','b','HorizontalAlignment','right','VerticalAlignment','top','Interpreter','none')

        plot([0:0.01:1],model_rand_AFROC_hypothesis([0:0.01:1]),'Color',[0.9, 0.9, 1.0])
        legend off

        hold off

        title(t,strcat(suffix," ",measure),'Interpreter','none')
    end
    %}
    % end plot individual AFROC curves
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3) make bar charts for comparison of different
%    detection approaches

hrT1_stats = stats(stats.suffix=='hrT1',:);
MP2_stats = stats(stats.suffix=='MP2',:);

unmatched_measures = setxor(hrT1_stats.measure,MP2_stats.measure);

if ~isempty(unmatched_measures)
    disp("unmatched measures for suffixes:")
    disp(unmatched_measures)
    error("available stat maps for suffixes not equivalent")
end

stats = join(hrT1_stats,MP2_stats,'Keys',[1]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sort table manually for prettier plots

% option 1: GLM
%{
stats = stats(~contains(stats.measure,'RFC'),:);
stats = stats(~contains(stats.measure,'MAH'),:);
stats = stats(~contains(stats.measure,'IFST'),:);

stats = stats([1 9 17 10 8 18 19 12 11 13 14 15 16 3 2 4 5 6 7],:);
%}

% option 2: classifiers
stats = stats(contains(stats.measure,'RFC') | contains(stats.measure,'MAH') | contains(stats.measure,'IFST'),:);

% sort according to feature set
% stats = stats([4 10 16 3 9 15 2 8 14 1 7 13 6 12 18 5 11 17],:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% replace GLM feature labels with more legible versions
% (this plots are finalized manually in a graphics programme)

old = {...
    '.8'
    'nthickness'
    'nu_intensity'
    'FLAIR_intensity'
    '.projdist_'
    '.projfrac_'
    '-1'
    '-2'
    '0.00'
    '0.25'
    '0.50'
    '0.75'
    'w-g.pct'
    };

new = {...
    ''
    'thickness'
    ''
    'F     '
    ''
    ''
    '-1 mm'
    '-2 mm'
    'GM/WM'
    '25%'
    '50%'
    '75%'
    'T1 w/g contrast'
    };

stats.measure = replace(stats.measure,old,new);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot bar charts

barx = categorical(stats.measure);
barx = reordercats(barx,stats.measure);

cmap_hrT1 = [repelem(0.5661,256,1), linspace(0,1,256)', repelem(0.7410,256,1)];
cmap_hrT1 = hsv2rgb(cmap_hrT1);
cmap_MP2 = [repelem(0.0503,256,1), linspace(0,1,256)', repelem(0.8500,256,1)];
cmap_MP2 = hsv2rgb(cmap_MP2);

figure
colormap(cmap_hrT1);
b1 = bar(barx,...
    [stats.AUC_AFROC_lesional_hrT1_stats, stats.AUC_AFROC_lesional_MP2_stats],...
    'LineStyle','none','FaceColor','flat');
ylim([0 0.6])
b1(1).CData = squeeze(ind2rgb(uint8(rescale(stats.p_AUC_AFROC_lesional_hrT1_stats,1,256,'InputMin',0.0,'InputMax',5.0029)),cmap_hrT1));
b1(2).CData = squeeze(ind2rgb(uint8(rescale(stats.p_AUC_AFROC_lesional_MP2_stats,1,256,'InputMin',0.0,'InputMax',5.0029)),cmap_MP2));

% bonferroni correction for multiple comparisons
p_bonferroni = 0.05/(2*length(stats.measure));
AUC_sig = prctile(rand_AUC_AFROC_lesional,100-100*p_bonferroni);
yline(AUC_sig,'--');
xtickangle(60);

title("MRI-positive subjects (n=5)")
set(gca,'TickLabelInterpreter','none')
ylabel("AFROC AUC");


figure
b2 = bar(barx,...
    [stats.AUC_AFROC_hypothesis_hrT1_stats, stats.AUC_AFROC_hypothesis_MP2_stats],...
    'LineStyle','none','FaceColor','flat');
ylim([0 0.6])
b2(1).CData = squeeze(ind2rgb(uint8(rescale(stats.p_AUC_AFROC_hypothesis_hrT1_stats,1,256,'InputMin',0.0,'InputMax',5.0029)),cmap_hrT1));
b2(2).CData = squeeze(ind2rgb(uint8(rescale(stats.p_AUC_AFROC_hypothesis_MP2_stats,1,256,'InputMin',0.0,'InputMax',5.0029)),cmap_MP2));

% bonferroni correction for multiple comparisons
p_bonferroni = 0.05/(2*length(stats.measure));
AUC_sig = prctile(rand_AUC_AFROC_hypothesis,100-100*p_bonferroni);
yline(AUC_sig,'--');
xtickangle(60);

title("MRI-negative subjects (n=27)")
set(gca,'TickLabelInterpreter','none')
ylabel("AFROC AUC");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4) make heat map charts for subject-level detection results

% replace internal subject IDs with numbered designations
listofalllabels = [listoflesionlabels listofhypothesislabels];
numberedlabels = {'P1', ' #1 P2', '#2 P2', 'P3', 'P4', 'P5', ...
    'N1' 'N2', 'N3', 'N4', 'N5', 'N6', 'N7', 'N8', 'N9', 'N10', ...
    'N11', 'N12', 'N13', 'N14', 'N15', 'N16', 'N17', 'N18', 'N19', 'N20', ...
    'N21', 'N22', 'N23', 'N24', 'N25', 'N26', 'N27' };
all_hrT1_p_values = -log10([cell2mat(stats.p_lesion_hrT1_stats)'; cell2mat(stats.p_hypothesis_hrT1_stats)']);
all_MP2_p_values = -log10([cell2mat(stats.p_lesion_MP2_stats)'; cell2mat(stats.p_hypothesis_MP2_stats)']);

figure
t = tiledlayout(1,2);
t.TileSpacing = 'compact';
t.Padding = 'compact';
nexttile;
h = heatmap(stats.measure,listofalllabels,all_hrT1_p_values);
h.YDisplayLabels = repmat("",length(listofalllabels),1);
h.ColorbarVisible = 'off';
h.ColorLimits = [0 5.0];
colormap('parula')

nexttile;
h = heatmap(stats.measure,listofalllabels,all_MP2_p_values);
h.YDisplayLabels = numberedlabels;
h.ColorLimits = [0 5.0];
colormap('parula')
