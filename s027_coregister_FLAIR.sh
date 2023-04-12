#!/bin/bash

source $SCRIPTS_DIR/s010_set_variables.sh

subject=$1

suffix=$2

bbregister --s ${subject}${suffix} --mov ${subject}/${subject}.hrFLAIR.nii --reg ${subject}${suffix}/mri/transforms/customFLAIR.dat --init-coreg --T2 --gm-proj-abs 2 --wm-proj-abs 1 --no-coreg-ref-mask

mri_vol2vol --mov ${subject}/${subject}.hrFLAIR.nii --o ${subject}${suffix}/mri/FLAIR.prenorm.mgz --reg ${subject}${suffix}/mri/transforms/customFLAIR.dat --fstarg

