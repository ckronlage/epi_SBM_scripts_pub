#!/bin/bash

source $SCRIPTS_DIR/s010_set_variables.sh


if [ $# != 1 ] || [ $1 == "" ]
then
  echo "ERROR"
  exit 1
fi	

subject_suffix=$1

surfreg --s $subject_suffix --t fsaverage_sym
surfreg --s $subject_suffix --t fsaverage_sym --lh --xhemi
