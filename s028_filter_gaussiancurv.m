clear;
close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load and set variables
addpath('/home/ckronlage/epi/epi_SBM_scripts');
s019_set_variables;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% parameters:
wm_erode_radius = 2;
cortex_erode_radius = 1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for suffix = {'_hrT1' '_MP2'} %listofsuffixes
    for subject = listofsubjects
        for hemi = {'lh' 'rh'}
            cmd = strcat("mris_curvature -mgh -w ",subject,suffix,"/surf/",hemi,".pial")
            status = system(cmd);
            
            pathtoinfile = strcat(subject,suffix,"/surf/",hemi,".pial.K.mgz");
            pathotooutfile = strcat(subject,suffix,"/surf/",hemi,".AICI.mgh");

            raw_gcurv = MRIread(convertStringsToChars(pathtoinfile));
        
            % outliers
            raw_gcurv.vol(abs(raw_gcurv.vol)>2) = NaN;

            % absolute (for absolute intrinstic curvature index AICI)
            raw_gcurv.vol = abs(raw_gcurv.vol);

            MRIwrite(raw_gcurv,convertStringsToChars(pathotooutfile));
 
        end % hemi loop
    end
end