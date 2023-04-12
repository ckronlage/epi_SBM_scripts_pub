function s029_normalize_intensities(subject,suffix)
%clear;
%close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load and set variables
addpath('/home/ckronlage/epi/epi_SBM_scripts');
s019_set_variables;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% parameters:
wm_erode_radius = 2;
cortex_erode_radius = 1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

aseg_raw = MRIread([subject suffix '/mri/aseg.mgz']);
aseg = aseg_raw.vol;

% make white matter  (indices 2 and 41) mask from
% aseg and erode
wmmask = aseg==2  | aseg==41;
wmmask = imerode(wmmask,strel('sphere',wm_erode_radius));

% similar for lh and rh cortex (indices 3 and 42)
cortexmask = aseg==3 | aseg==42;
cortexmask = imerode(cortexmask,strel('sphere',cortex_erode_radius));

files = {'/mri/nu.mgz'};

%if contains(suffix,'FLAIR')

	cmd = strcat("AntsN4BiasFieldCorrectionFs ", ...
		" -i ",subject,suffix,"/mri/FLAIR.prenorm.mgz",...
		" -o ",subject,suffix,"/mri/FLAIR.prenorm.nu.mgz",...
		" ");

	status = system(cmd);

	files = [files '/mri/FLAIR.prenorm.nu.mgz'];
%end

for file = files
	% read nonuniformity-corrected volume (nu.mgz)
	raw_filedata = MRIread([subject suffix file{:}]);
	raw = raw_filedata.vol;

	% normalize
	wmmean = median(raw(wmmask));
	cortexmean = median(raw(cortexmask));
	if contains(file,'FLAIR')
		normalized = (raw - wmmean) ./ (cortexmean - wmmean);
	else
		normalized = (raw - cortexmean) ./ (wmmean - cortexmean);
	end

	% save normalized
	normalized_filedata = aseg_raw;
	normalized_filedata.vol = normalized;

	MRIwrite(normalized_filedata,[subject suffix file{:} '_normalized.mgz']);
end

disp([subject suffix ' done'])

end %function