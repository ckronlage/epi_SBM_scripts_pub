function s021_skullstrip_MP2RAGE_SPM(MP2file,INV1file,INV2file)
% performs skullstripping of MP2 images by following steps:
% 
% == 1+2 using SPM, built with batch editor
% 1) coregistration of INV1 and INV2 to MP2 in SPM (because header data is
% minimally different in some cases, precluding multimodal segmentation)
% 2) multimodal segmentation using INV1 and INV2
%
% == 3-6 in matlab with freesurfer i/o functions
% 3) tresholding of the grey-matter, white-matter and csf probability maps
% 4) subsequent dilation and erosiong to obtain a skullstripping mask
% 5) masking of the MP2 volume
%
% important: paths must be _absolute_ for the file handling to work

[ workdir, ~, ~ ] = fileparts(MP2file);
cd(workdir);

% run SPM coregistration and segmentation with default settings
spm12_r7771;
spm_jobman('initcfg');
spm_get_defaults('cmdline',true);


matlabbatch{1}.cfg_basicio.file_dir.dir_ops.cfg_named_dir.name = 'workdir';
matlabbatch{1}.cfg_basicio.file_dir.dir_ops.cfg_named_dir.dirs = {{workdir}};
matlabbatch{2}.cfg_basicio.file_dir.file_ops.cfg_named_file.name = 'mp2file';
matlabbatch{2}.cfg_basicio.file_dir.file_ops.cfg_named_file.files = {{MP2file}};
matlabbatch{3}.cfg_basicio.file_dir.file_ops.cfg_named_file.name = 'inv1file';
matlabbatch{3}.cfg_basicio.file_dir.file_ops.cfg_named_file.files = {{INV1file}};
matlabbatch{4}.cfg_basicio.file_dir.file_ops.cfg_named_file.name = 'inv2file';
matlabbatch{4}.cfg_basicio.file_dir.file_ops.cfg_named_file.files = {{INV2file}};
matlabbatch{5}.spm.spatial.coreg.estwrite.ref(1) = cfg_dep('Named File Selector: mp2file(1) - Files', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files', '{}',{1}));
matlabbatch{5}.spm.spatial.coreg.estwrite.source(1) = cfg_dep('Named File Selector: inv1file(1) - Files', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files', '{}',{1}));
matlabbatch{5}.spm.spatial.coreg.estwrite.other = {''};
matlabbatch{5}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
matlabbatch{5}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];
matlabbatch{5}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{5}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
matlabbatch{5}.spm.spatial.coreg.estwrite.roptions.interp = 4;
matlabbatch{5}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
matlabbatch{5}.spm.spatial.coreg.estwrite.roptions.mask = 0;
matlabbatch{5}.spm.spatial.coreg.estwrite.roptions.prefix = 'r';
matlabbatch{6}.spm.spatial.coreg.estwrite.ref(1) = cfg_dep('Named File Selector: mp2file(1) - Files', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files', '{}',{1}));
matlabbatch{6}.spm.spatial.coreg.estwrite.source(1) = cfg_dep('Named File Selector: inv2file(1) - Files', substruct('.','val', '{}',{4}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files', '{}',{1}));
matlabbatch{6}.spm.spatial.coreg.estwrite.other = {''};
matlabbatch{6}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
matlabbatch{6}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];
matlabbatch{6}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{6}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
matlabbatch{6}.spm.spatial.coreg.estwrite.roptions.interp = 4;
matlabbatch{6}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
matlabbatch{6}.spm.spatial.coreg.estwrite.roptions.mask = 0;
matlabbatch{6}.spm.spatial.coreg.estwrite.roptions.prefix = 'r';
matlabbatch{7}.spm.spatial.preproc.channel(1).vols(1) = cfg_dep('Coregister: Estimate & Reslice: Resliced Images', substruct('.','val', '{}',{5}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','rfiles'));
matlabbatch{7}.spm.spatial.preproc.channel(1).biasreg = 0.001;
matlabbatch{7}.spm.spatial.preproc.channel(1).biasfwhm = 60;
matlabbatch{7}.spm.spatial.preproc.channel(1).write = [0 0];
matlabbatch{7}.spm.spatial.preproc.channel(2).vols(1) = cfg_dep('Coregister: Estimate & Reslice: Resliced Images', substruct('.','val', '{}',{6}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','rfiles'));
matlabbatch{7}.spm.spatial.preproc.channel(2).biasreg = 0.001;
matlabbatch{7}.spm.spatial.preproc.channel(2).biasfwhm = 60;
matlabbatch{7}.spm.spatial.preproc.channel(2).write = [0 0];
matlabbatch{7}.spm.spatial.preproc.tissue(1).tpm = {'/nic/sw/spm/spm12latest/tpm/TPM.nii,1'};
matlabbatch{7}.spm.spatial.preproc.tissue(1).ngaus = 1;
matlabbatch{7}.spm.spatial.preproc.tissue(1).native = [1 0];
matlabbatch{7}.spm.spatial.preproc.tissue(1).warped = [0 0];
matlabbatch{7}.spm.spatial.preproc.tissue(2).tpm = {'/nic/sw/spm/spm12latest/tpm/TPM.nii,2'};
matlabbatch{7}.spm.spatial.preproc.tissue(2).ngaus = 1;
matlabbatch{7}.spm.spatial.preproc.tissue(2).native = [1 0];
matlabbatch{7}.spm.spatial.preproc.tissue(2).warped = [0 0];
matlabbatch{7}.spm.spatial.preproc.tissue(3).tpm = {'/nic/sw/spm/spm12latest/tpm/TPM.nii,3'};
matlabbatch{7}.spm.spatial.preproc.tissue(3).ngaus = 2;
matlabbatch{7}.spm.spatial.preproc.tissue(3).native = [1 0];
matlabbatch{7}.spm.spatial.preproc.tissue(3).warped = [0 0];
matlabbatch{7}.spm.spatial.preproc.tissue(4).tpm = {'/nic/sw/spm/spm12latest/tpm/TPM.nii,4'};
matlabbatch{7}.spm.spatial.preproc.tissue(4).ngaus = 3;
matlabbatch{7}.spm.spatial.preproc.tissue(4).native = [0 0];
matlabbatch{7}.spm.spatial.preproc.tissue(4).warped = [0 0];
matlabbatch{7}.spm.spatial.preproc.tissue(5).tpm = {'/nic/sw/spm/spm12latest/tpm/TPM.nii,5'};
matlabbatch{7}.spm.spatial.preproc.tissue(5).ngaus = 4;
matlabbatch{7}.spm.spatial.preproc.tissue(5).native = [0 0];
matlabbatch{7}.spm.spatial.preproc.tissue(5).warped = [0 0];
matlabbatch{7}.spm.spatial.preproc.tissue(6).tpm = {'/nic/sw/spm/spm12latest/tpm/TPM.nii,6'};
matlabbatch{7}.spm.spatial.preproc.tissue(6).ngaus = 2;
matlabbatch{7}.spm.spatial.preproc.tissue(6).native = [0 0];
matlabbatch{7}.spm.spatial.preproc.tissue(6).warped = [0 0];
matlabbatch{7}.spm.spatial.preproc.warp.mrf = 1;
matlabbatch{7}.spm.spatial.preproc.warp.cleanup = 1;
matlabbatch{7}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
matlabbatch{7}.spm.spatial.preproc.warp.affreg = 'mni';
matlabbatch{7}.spm.spatial.preproc.warp.fwhm = 0;
matlabbatch{7}.spm.spatial.preproc.warp.samp = 3;
matlabbatch{7}.spm.spatial.preproc.warp.write = [0 0];
matlabbatch{7}.spm.spatial.preproc.warp.vox = NaN;
matlabbatch{7}.spm.spatial.preproc.warp.bb = [NaN NaN NaN
                                              NaN NaN NaN];
                                          
spm_jobman('run', matlabbatch);

% construct variables for filenames of segmentations as output by SPM
[ ~ , inv1basename, ~ ] = fileparts(INV1file);
gmmapfile = strcat(workdir,'/c1r',inv1basename,'.nii');
wmmapfile = strcat(workdir,'/c2r',inv1basename,'.nii');
csfmapfile = strcat(workdir,'/c3r',inv1basename,'.nii');
[ ~, maskedMP2file, ~ ] = fileparts(MP2file);
maskedMP2file = strcat(workdir,'/',maskedMP2file,'.skullstripped.nii');

% read segmentation maps in matlab (using Freesurfer matlab routines)
addpath('/nic/sw/FreeSurfer/7.2.0/matlab');
gmmap = MRIread(gmmapfile);
gmmap = gmmap.vol;
wmmap = MRIread(wmmapfile);
wmmap = wmmap.vol;
csfmap = MRIread(csfmapfile);
csfmap = csfmap.vol;

% threshold maps, dilate and erode to obtain skullstripping mask
mask = (gmmap > 0.5) | (wmmap > 0.5) | (csfmap > 0.99);
mask = imdilate(mask,strel('sphere',2));
mask = imerode(mask,strel('sphere',1));

% read actual MP2 volume and mask
orig_masked_MP2 = MRIread(MP2file);

orig_masked_MP2.vol = orig_masked_MP2.vol .* mask;

MRIwrite(orig_masked_MP2,maskedMP2file);

end
