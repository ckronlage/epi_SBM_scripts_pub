#!/bin/bash

# $SCRIPTS_DIR must be set to the directory containing this file and the other bash scripts

# print freesurfer version
# recon-all --version

export SUBJECTS_DIR=/home/ckronlage/epi/DATA/current
cd $SUBJECTS_DIR

listofsubjects=`cat 0listofsubjects`
listofsuffixes="_hrT1 _MP2"

listofrawmeasures=""
if [ -f 0listofrawmeasures ]
then
	listofrawmeasures=`cat 0listofrawmeasures`
fi


listofmeasures=""
if [ -f 0listofmeasures ]
then
	listofmeasures=`cat 0listofmeasures`
fi


listofmeasures_GLM=""
if [ -f 0listofmeasures_GLM ]
then
	listofmeasures_GLM=`cat 0listofmeasures_GLM`
fi

listoflesionalsubjects=`cat 0listoflesionalsubjects`


if [ ! -d 0gridlogs ]
then
    mkdir 0gridlogs
fi

if [ ! -d fsaverage_sym ]
then
	echo "copied fsaverage_sym"
    cp -r $FREESURFER_HOME/subjects/fsaverage_sym .
fi


