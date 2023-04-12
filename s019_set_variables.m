% set all relevant variables

setenv('SCRIPTS_DIR','/home/ckronlage/epi/epi_SBM_scripts')
addpath('/nic/sw/FreeSurfer/7.2.0/matlab/');

SUBJECTS_DIR='/home/ckronlage/epi/DATA/current';
cd(SUBJECTS_DIR)
setenv('SUBJECTS_DIR','.');

% get some variables from bash scripts for consistency

[~,cmdout] = system('bash $SCRIPTS_DIR/s011_echo_listofsubjects.sh');
listofsubjects = strtrim(strsplit(cmdout,{' '},'CollapseDelimiters',true));

[~,cmdout] = system('bash $SCRIPTS_DIR/s012_echo_listofsuffixes.sh');
listofsuffixes = strtrim(strsplit(cmdout,{' '},'CollapseDelimiters',true));

[~,cmdout] = system('bash $SCRIPTS_DIR/s013_echo_listofmeasures.sh');
listofmeasures = strtrim(strsplit(cmdout,{' '},'CollapseDelimiters',true));

[~,cmdout] = system('bash $SCRIPTS_DIR/s014_echo_listofmeasures_GLM.sh');
listofmeasures_GLM = strtrim(strsplit(cmdout,{' '},'CollapseDelimiters',true));

[~,cmdout] = system('bash $SCRIPTS_DIR/s015_echo_listoflesionalsubjects.sh');
listoflesionalsubjects = strtrim(strsplit(cmdout,{' '},'CollapseDelimiters',true));

hemis = {'lh', 'rh_on_lh'};


% compute lists of control and hypothesis subjects
listofcontrolsubjects = listofsubjects(contains(listofsubjects,'C.'));
listofhypothesissubjects = setdiff(listofsubjects(contains(listofsubjects,'P.')),listoflesionalsubjects);
