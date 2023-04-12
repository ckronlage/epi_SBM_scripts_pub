#!/bin/bash

source $SCRIPTS_DIR/s010_set_variables.sh

for subject in $listofsubjects
do
	for suffix in $listofsuffixes 
	do
		qsub \
		  -q long.q \
		  -e 0gridlogs/ \
		  -o 0gridlogs/ \
		  -cwd -V -b y \
		  $SCRIPTS_DIR/s027_coregister_FLAIR.sh $subject $suffix
	done
done


