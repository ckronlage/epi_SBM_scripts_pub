#!/bin/bash

source $SCRIPTS_DIR/s010_set_variables.sh

mkdir -p 0hrT1MP2diff

for measure in "nthickness" # "nu_intensity.projdist_-1" "nu_intensity.projfrac_0.50"
do
	for hemi in "lh" "rh_on_lh"
	do
		cmd="mri_concat "
		
		for subject in C.??????? #$listofsubjects
		do
			mkdir -p ${subject}_diff
		
			# mris_calc \
			#  --output ${subject}_diff/${hemi}.${measure}.hrT1MP2diff.fsaverage_sym.mgh \
			#  ${subject}_hrT1/surf/${hemi}.${measure}.fsaverage_sym.mgh sub \
			#  ${subject}_MP2/surf/${hemi}.${measure}.fsaverage_sym.mgh
			
			cmd="${cmd} --i ${subject}_diff/${hemi}.${measure}.hrT1MP2diff.fsaverage_sym.mgh "
		done
		
		cmd="${cmd} --o 0hrT1MP2diff/${hemi}.${measure}.stack.mgh"
		# run concatenation
		eval $cmd 
		
		
		mri_glmfit --y 0hrT1MP2diff/${hemi}.${measure}.stack.mgh \
		  --osgm --surf fsaverage_sym lh --cortex \
		  --glmdir 0hrT1MP2diff/${hemi}.${measure}_glm/

		 
		if [[ $hemi == "rh_on_lh" ]]
		then
			mris_apply_reg \
			  --src 0hrT1MP2diff/${hemi}.${measure}_glm/beta.mgh \
			  --trg 0hrT1MP2diff/${hemi}.${measure}_glm/rh_on_rh_beta.mgh \
			  --streg fsaverage_sym/surf/lh.sphere.left_right \
			  	  fsaverage_sym/surf/rh.sphere.left_right
		fi
			   
		 
	done
done
