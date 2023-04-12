#!/bin/bash

source $SCRIPTS_DIR/s010_set_variables.sh

if [ $# != 1 ] || [ $1 == "" ]
then
  echo "ERROR"
  exit 1
fi	

subject_suffix=$1




for hemi in lh rh
do	
	#############################################################
	# 1) recalculate thickness values with maximum of 15mm (instead of default 5mm)
	mris_thickness -max 15 $subject_suffix $hemi ${hemi}.nthickness.mgh
	
	#############################################################
	# 2) convert surface measures from "curv" format to ".mgh"
	#    for more consistent handling later
	
	for curvmeasure in sulc curv area volume
	do
		mri_convert \
		    ${subject_suffix}/surf/${hemi}.${curvmeasure} \
		    ${subject_suffix}/surf/${hemi}.${curvmeasure}.mgh

	done # curvmeasure loop   

	listofrawmeasures="sulc curv AICI nthickness area volume w-g.pct"

	#############################################################
	# 3) calculate intensities of the T1 and FLAIR volumes along surfaces shifted 
	# from "white" fractionally into the cortex (projfrac, i.e. 0.25, 0.5, 0.75) 
	# and in absolute distances (projdist, in the subcortical direction, i.e. -1, -2)
	
	listofprojfracs="0.00 0.25 0.50 0.75"
	listofprojdists="-2 -1"
	
	for projfrac in $listofprojfracs
	do
		mri_vol2surf \
		   --mov ${subject_suffix}/mri/nu.mgz_normalized.mgz \
		   --regheader ${subject_suffix} \
		   --hemi $hemi \
		   --projfrac $projfrac \
		   --cortex \
		   --o ${subject_suffix}/surf/${hemi}.nu_intensity.projfrac_${projfrac}.mgh
		   
		listofrawmeasures="$listofrawmeasures nu_intensity.projfrac_${projfrac}" 
		  
	done
	
	for projdist in $listofprojdists
	do
		mri_vol2surf \
		   --mov ${subject_suffix}/mri/nu.mgz_normalized.mgz \
		   --regheader ${subject_suffix} \
		   --hemi $hemi \
		   --projdist $projdist \
		   --cortex \
		   --o ${subject_suffix}/surf/${hemi}.nu_intensity.projdist_${projdist}.mgh
		  
		listofrawmeasures="$listofrawmeasures nu_intensity.projdist_${projdist}" 
	done
	
	
	#### FLAIR
	#if  [[ $subject_suffix == *"FLAIR"* ]]
	#then
		for projfrac in $listofprojfracs
		do
			mri_vol2surf \
			   --mov ${subject_suffix}/mri/FLAIR.prenorm.nu.mgz_normalized.mgz \
			   --regheader ${subject_suffix} \
			   --hemi $hemi \
			   --projfrac $projfrac \
			   --cortex \
			   --o ${subject_suffix}/surf/${hemi}.FLAIR_intensity.projfrac_${projfrac}.mgh
			   
			listofrawmeasures="$listofrawmeasures FLAIR_intensity.projfrac_${projfrac}" 
			  
		done
		
		for projdist in $listofprojdists
		do
			mri_vol2surf \
			   --mov ${subject_suffix}/mri/FLAIR.prenorm.nu.mgz_normalized.mgz \
			   --regheader ${subject_suffix} \
			   --hemi $hemi \
			   --projdist $projdist \
			   --cortex \
			   --o ${subject_suffix}/surf/${hemi}.FLAIR_intensity.projdist_${projdist}.mgh
			  
			listofrawmeasures="$listofrawmeasures FLAIR_intensity.projdist_${projdist}" 
		done
	#fi  # if FLAIR
	
done #hemi loop

#############################################################
# 4) resample all surface values to fsaverage_sym

for measure in $listofrawmeasures
do
	# for lh
	mris_apply_reg \
	  --src ${subject_suffix}/surf/lh.${measure}.mgh \
	  --trg ${subject_suffix}/surf/lh.${measure}.fsaverage_sym.mgh \
	  --streg ${subject_suffix}/surf/lh.fsaverage_sym.sphere.reg \
	       fsaverage_sym/surf/lh.sphere.reg
	          
	# for rh on rh.fsaverage_sym (-> rh_on_rh.*)
	#mris_apply_reg \
	#  --src ${subject_suffix}/surf/rh.${measure}.mgh \
	#  --trg ${subject_suffix}/surf/rh_on_rh.${measure}.fsaverage_sym.mgh \
	#  --streg ${subject_suffix}/surf/rh.fsaverage_sym.sphere.reg \
	#       fsaverage_sym/surf/rh.sphere.reg
	
	# for rh on lh.fsaverage_sym
	mris_apply_reg \
	  --src ${subject_suffix}/surf/rh.${measure}.mgh \
      	  --trg ${subject_suffix}/surf/rh_on_lh.${measure}.fsaverage_sym.mgh \
          --streg ${subject_suffix}/xhemi/surf/lh.fsaverage_sym.sphere.reg \
	       fsaverage_sym/surf/lh.sphere.reg
	
	#############################################################
	# 6) calculate asymmetry differences
	            
	mris_calc \
	  --output ${subject_suffix}/surf/lh.${measure}.asym.fsaverage_sym.mgh \
	  ${subject_suffix}/surf/lh.${measure}.fsaverage_sym.mgh sub \
	  ${subject_suffix}/surf/rh_on_lh.${measure}.fsaverage_sym.mgh
	  	
	mris_calc \
	  --output ${subject_suffix}/surf/rh_on_lh.${measure}.asym.fsaverage_sym.mgh \
	  ${subject_suffix}/surf/rh_on_lh.${measure}.fsaverage_sym.mgh sub \
	  ${subject_suffix}/surf/lh.${measure}.fsaverage_sym.mgh  
	  
	listofrawmeasures="$listofrawmeasures ${measure}.asym"
  
done # listofmeasures loop

# save smoothed measures to seperate directory
if [ ! -d ${subject_suffix}/0surf_features ]
then
    mkdir ${subject_suffix}/0surf_features
fi

listofmeasures=""

for measure in $listofrawmeasures
do
 	#############################################################
	# 5) smoothing
	
	if [[ $measure == *"asym"* ]]
	then
		listofsmoothings="8"
		listofDoGs=""
	else
		listofsmoothings="8 32"
		listofDoGs="8-32"
	fi

	for smoothing in $listofsmoothings
	do
		for hemi in lh rh_on_lh
		do
			mris_fwhm \
			  --s fsaverage_sym \
			  --hemi lh \
			  --cortex \
			  --smooth-only \
			  --fwhm $smoothing \
			  --i ${subject_suffix}/surf/${hemi}.${measure}.fsaverage_sym.mgh \
			  --o ${subject_suffix}/0surf_features/${hemi}.${measure}.${smoothing}.fsaverage_sym.mgh
			# ""--hemi lh" because this is on the fsaverage_sym-subject
			
		done # hemi loop
		
		listofmeasures="$listofmeasures ${measure}.${smoothing}"
		
	done # listofsmoothings loop     
	
	#############################################################
	# 6) difference of gaussians filtering

	
	for DoGsmoothing in $listofDoGs
	do
		smoothing1=${DoGsmoothing%-*}
		smoothing2=${DoGsmoothing#*-}

		for hemi in lh rh_on_lh
		do
			# check whether files exist
			if [ ! -f ${subject_suffix}/0surf_features/${hemi}.${measure}.${smoothing1}.fsaverage_sym.mgh ] \
			|| [ ! -f ${subject_suffix}/0surf_features/${hemi}.${measure}.${smoothing2}.fsaverage_sym.mgh ]
			then
				echo $ERROR
				exit 1
			fi
		
			mris_calc \
			  --output ${subject_suffix}/0surf_features/${hemi}.${measure}.DoG${DoGsmoothing}.fsaverage_sym.mgh \
			  ${subject_suffix}/0surf_features/${hemi}.${measure}.${smoothing1}.fsaverage_sym.mgh \
			  sub \
			  ${subject_suffix}/0surf_features/${hemi}.${measure}.${smoothing2}.fsaverage_sym.mgh
			
		done # hemi loop
		
		listofmeasures="$listofmeasures ${measure}.DoG${DoGsmoothing}"
		
	done # listofDoGsmoothings loop     
done # listofmeasureswasymm loop

#############################################################
# 7) save list of raw (unsmoothed) and smoothed measure names to file
#    to be used as a variable in the other scripts

if [ ! -f 0listofrawmeasures ]
then
	echo $listofrawmeasures > 0listofrawmeasures	
fi

if [ ! -f 0listofmeasures ]
then	
	echo $listofmeasures > 0listofmeasures
fi


