#!/bin/bash

# publication version containing only example subject IDs

source $SCRIPTS_DIR/s010_set_variables.sh

mkdir 0groundtruthlabels

# P.EXMP01A rh frontal (manual label)
cp 0lesions/P.EXMP01A.rh.hrT1orig.lesion.mgz_final_union_dilated.label 0groundtruthlabels/P.EXMP01A.01.rh_on_lh.wide.label
cp 0lesions/P.EXMP01A.rh.hrT1orig.lesion.mgz_final_intersect.label 0groundtruthlabels/P.EXMP01A.01.rh_on_lh.strict.label

# P.FOBR02B rh frontal
mri_mergelabels -i 0lobelabels_fsaverage_sym/lh.frontal.label -i 0lobelabels_fsaverage_sym/lh.temporal.label -o 0groundtruthlabels/P.FOBR02B.01.rh_on_lh.wide.label
