function [gtlabels ] = s049_load_groundtruthlabels()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load and set variables
addpath('/home/ckronlage/epi/epi_SBM_scripts');
s019_set_variables;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

labellist = dir(['0groundtruthlabels/*.label']);
labellist = {labellist.name};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load ground truth labels from disk into struct array
% requires the naming scheme $GROUP.$SUBJECT.$INDEX.$HEMI.label
% e.g. P.ANWE02I.01.rh_on_lh.label

for i_label=1:length(labellist)
    gtlabels(i_label).filename = labellist{i_label};
    gtlabels(i_label).data = read_label('',strcat("0groundtruthlabels/",gtlabels(i_label).filename));

    % extract indices and convert to matlab (1-based)
    % indexing
    gtlabels(i_label).data = gtlabels(i_label).data(:,1)+1;

    tmp_filenamesplit = strsplit(gtlabels(i_label).filename,'.');
    gtlabels(i_label).subject = strjoin(tmp_filenamesplit(1:2),'.');
    gtlabels(i_label).index = str2num(tmp_filenamesplit{3});
    gtlabels(i_label).hemi = tmp_filenamesplit{4};
    gtlabels(i_label).identifier = strjoin(tmp_filenamesplit(1:3),'.');

    if any(matches(listoflesionalsubjects,gtlabels(i_label).subject))
        gtlabels(i_label).type = 'lesion';
    else
        gtlabels(i_label).type = 'hypothesis';
    end

    gtlabels(i_label).version = tmp_filenamesplit{5};

end % labels loop

end
