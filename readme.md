# MP2RAGE vs. MPRAGE surface-based morphometry in focal epilepsy

This repository contains the scripts used in the publication _________

You can get in touch via: cornelius.kronlage[at]med.uni-tuebingen.de

## Instructions for usage:
1) Prerequisites and file structure:
- The environment variable $BASH_SCRIPTS is set to the path containing all script files. Script files are numbered (s000-s999). Some parts are bash, some matlab scripts.
``` 
	$ call this in bash
	>> call this in matlab
```
- The working directory (set as $SUBJECTS_DIR) contains a folder for each subject named after the subject ID (e.g. P.ABCD01X) and further files:
	- 0listofsubjects: text file, lists all subject IDs
	- 0covariates_raw.csv: csv file, contains covariates (age, gender, site) for GLM
	- 0listoflesionalsubjects : text file, lists IDs of MRI-positive patients
	- 0lesions: folder containing manual volume ground truth lesion labels for MRI-positive patients, named <ID>.<hemi>.lesion_name.mgz
- Each subject folder contains multiple .nii image files (MPRAGE 'hrT1', and MP2RAGE). The file suffixes '_hrT1' and '_MP2' denote the different processing streams for all further processed data.
- *qwrapper* scripts are meant for parallelizing processing steps by executing on an grid engine cluster.

2) Run script files
- s010-s019: Helper scripts, only called indirectly to set variables etc.
- s020-s026: Run skullstripping for MP2RAGE and standard freesurfer recon-all for all data, including registration to fsaverage_sym
```
	$ s020_qwrapper_start_recon_all_hrT1.sh
	$ s023_qwrapper_start_recon_all_MP2.sh
	$ s026_qwrapper_start_xhemi_all.sh
```
- s027-s031: Generate all surface data for further statistical evaluation (i.e.  T1 and FLAIR intensities, curvature), resample to fsaverage_sym, smoothing and filtering
```
	$ s027_qwrapper_coregister_FLAIR.sh
	>> s028_filter_gaussiancurv.m
	$ s029_qwrapper_normalize_intensities.sh
	$ s031_qwrapper_calculate_surfacemeasures.sh
```
- s039-s042: Run GLM analysis 
```
	$ s039_select_measures_GLM.sh
	$ s042_qwrapper_run_GLM.sh
```
- s044-s046: Generate ground truth surface labels (from hypotheses for MRI-negative patients, from manual volume labels for MRI-positive patients)
```
	$ s044_make_lobelabels.sh
	$ s045_convert_lesion_labels.sh
	$ s046_copy_merge_groundtruthlabels.sh
```
- s046-s047: Run multivariate classifier training and prediction
```
	$ s047_qwrapper_run_classifier.sh
```
- s049-s053: Automated detection performance evaluation of maps generated in previous steps
```
	$ s051_qwrapper_simulate_random_clusters.sh
	$ s052_qwrapper_analyse_GLM_clusters.sh
	$ s053_qwrapper_analyse_CLASS_clusters.sh
```
- s060: Analyse and visualise generated FROC data
```
	>> s060_analyse_stats.m
```
- s070-s074: Additional scripts for comparing segmentation between hrT1 and MP2 (figure 2, 3)

- s100: Matlab Script for simulating and visualizing random guessing AFROCs (figure 1)
