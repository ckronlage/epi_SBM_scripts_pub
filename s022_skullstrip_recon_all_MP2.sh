#!/bin/bash

if [[ $1 == "" ]]
then
  echo "ERROR"
  exit 1
fi	

subject=$1

mkdir ${subject}/MP2_SPMskullstrip

cp ${subject}/${subject}.MP2RAGE.MP2.A.nii ${subject}/MP2_SPMskullstrip/
cp ${subject}/${subject}.MP2RAGE.inv1.A.nii ${subject}/MP2_SPMskullstrip/
cp ${subject}/${subject}.MP2RAGE.inv2.A.nii ${subject}/MP2_SPMskullstrip/

matlab9.11 -nodisplay -batch "addpath('/home/ckronlage/epi/epi_SBM_scripts/'); s021_skullstrip_MP2RAGE_SPM('${SUBJECTS_DIR}/${subject}/MP2_SPMskullstrip/${subject}.MP2RAGE.MP2.A.nii','${SUBJECTS_DIR}/${subject}/MP2_SPMskullstrip/${subject}.MP2RAGE.inv1.A.nii','${SUBJECTS_DIR}/${subject}/MP2_SPMskullstrip/${subject}.MP2RAGE.inv2.A.nii')"

cp ${subject}/MP2_SPMskullstrip/${subject}.MP2RAGE.MP2.A.skullstripped.nii ${subject}/

recon-all -sd $PWD -s ${subject}_MP2 -i ${subject}/${subject}.MP2RAGE.MP2.A.skullstripped.nii -all -openmp 4

