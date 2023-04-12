#!/bin/bash

source $SCRIPTS_DIR/s010_set_variables.sh

listofmeasures_GLM=""

for measure in $listofmeasures
do
	if [[ ! $measure =~ "asym" ]] && [[ $measure =~ ".8" ]] 
	then
		echo $measure
		listofmeasures_GLM="$listofmeasures_GLM $measure"
	fi
done

echo $listofmeasures_GLM > 0listofmeasures_GLM
