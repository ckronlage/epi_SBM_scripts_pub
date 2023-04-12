#!/bin/bash

source $SCRIPTS_DIR/s010_set_variables.sh


for subject in $listofsubjects
do
	qsub \
	  -q long.q \
	  -e 0gridlogs/ \
	  -o 0gridlogs/ \
	  -cwd -V -b y \
	  $SCRIPTS_DIR/s022_skullstrip_recon_all_MP2.sh ${subject}
	    
done

