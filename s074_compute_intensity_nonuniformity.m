clear;

addpath('/home/ckronlage/epi/epi_SBM_scripts');
s019_set_variables;

% load cortex label and adjust for matlab 1-based indexing
cortex = read_label('','fsaverage_sym/label/lh.cortex');
cortex = cortex(:,1)+1;

% measure = "nu_intensity.projfrac_0.50"; % "nu_intensity.projdist_-1"
measure = "nu_intensity.projdist_-2"


figure
hold on

for suffix = {"_hrT1", "_MP2"}

    intensitydata = [];
    for subject = listofcontrolsubjects
        lhmap_path = strcat(subject,suffix{1},"/surf/rh_on_lh.",measure,".fsaverage_sym.mgh");
        lhmap = MRIread(convertStringsToChars(lhmap_path));

        rhmap_path = strcat(subject,suffix{1},"/surf/lh.",measure,".fsaverage_sym.mgh");
        rhmap = MRIread(convertStringsToChars(rhmap_path));

        intensitydata(end+1,:) = [lhmap.vol(cortex) rhmap.vol(cortex) ];


    end 

    histogram(intensitydata,[-0.5125:0.025:1.7125],'Normalization','pdf','FaceAlpha',0.5,'EdgeColor','none');
    
    mean(intensitydata,'all')
    std(intensitydata,0,'all')

end

hold off

legend('hrT1','MP2')
legend('boxoff')
yticks([]);
set(gca,'YColor','none')
