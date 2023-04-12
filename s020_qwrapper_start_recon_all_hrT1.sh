#!/bin/bash

source $SCRIPTS_DIR/s010_set_variables.sh


for subject in $listofsubjects
do
	qsub \
	  -q long.q \
	  -e 0gridlogs/ \
	  -o 0gridlogs/ \
	  -cwd -V -b y \
	  recon-all \
	    -sd $PWD \
	    -s ${subject}_hrT1 \
	    -i ${subject}/${subject}.hrT1.nii \
	    -all \
	    -openmp 4
	    
done

