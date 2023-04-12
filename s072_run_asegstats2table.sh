#!/bin/bash

source $SCRIPTS_DIR/s010_set_variables.sh

mkdir -p 0hrT1MP2diff

for suffix in "_hrT1" "_MP2"
do
	cmd="asegstats2table --tablefile 0hrT1MP2diff/asegstats${suffix}.csv --subjects "
	
	for subject in C.??????? #$listofsubjects
	do
		cmd="${cmd} ${subject}${suffix}"
	done
	
	eval $cmd
done
