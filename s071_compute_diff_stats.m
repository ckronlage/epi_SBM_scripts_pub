addpath('/home/ckronlage/epi/epi_SBM_scripts');
s019_set_variables;

% load cortex label and adjust for matlab 1-based indexing
cortex = read_label('','fsaverage_sym/label/lh.cortex');
cortex = cortex(:,1)+1;

for measure = {"nthickness"} %"nu_intensity.projdist_-1" "nu_intensity.projfrac_0.50"}
    lhmap_path = strcat("0hrT1MP2diff/lh.",measure{1},".stack.mgh");
    lhmap = MRIread(convertStringsToChars(lhmap_path));
    lhmap = squeeze(lhmap.vol(:,cortex,:,:));

    rhmap_path = strcat("0hrT1MP2diff/rh_on_lh.",measure{1},".stack.mgh");
    rhmap = MRIread(convertStringsToChars(rhmap_path));
    rhmap = squeeze(rhmap.vol(:,cortex,:,:));

    hemimaps = [lhmap, rhmap];
    hemimaps = abs(hemimaps);
    hemiwise_mean = mean(hemimaps,1);

    overall_mean = mean(hemiwise_mean)
    overall_std = std(hemiwise_mean)

end
