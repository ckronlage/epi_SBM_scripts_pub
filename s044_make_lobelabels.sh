#!/bin/bash


mkdir 0lobelabels_fsaverage_sym
mkdir 0lobelabels_fsaverage_sym/tmp

cd 0lobelabels_fsaverage_sym

mri_annotation2label --subject fsaverage --hemi lh --outdir tmp

cd tmp

mri_mergelabels \
  -o ../lh.frontal.label \
  -i lh.superiorfrontal.label \
  -i lh.rostralmiddlefrontal.label \
  -i lh.caudalmiddlefrontal.label \
  -i lh.parsopercularis.label \
  -i lh.parstriangularis.label \
  -i lh.parsorbitalis.label \
  -i lh.lateralorbitofrontal.label \
  -i lh.medialorbitofrontal.label \
  -i lh.precentral.label \
  -i lh.paracentral.label \
  -i lh.frontalpole.label \
  -i lh.rostralanteriorcingulate.label \
  -i lh.caudalanteriorcingulate.label
  
mri_mergelabels \
  -o ../lh.frontalwoprecentral.label \
  -i lh.superiorfrontal.label \
  -i lh.rostralmiddlefrontal.label \
  -i lh.caudalmiddlefrontal.label \
  -i lh.parsopercularis.label \
  -i lh.parstriangularis.label \
  -i lh.parsorbitalis.label \
  -i lh.lateralorbitofrontal.label \
  -i lh.medialorbitofrontal.label \
  -i lh.paracentral.label \
  -i lh.frontalpole.label \
  -i lh.rostralanteriorcingulate.label \
  -i lh.caudalanteriorcingulate.label
  
mri_mergelabels \
  -o ../lh.parietal.label \
  -i lh.superiorparietal.label \
  -i lh.inferiorparietal.label \
  -i lh.supramarginal.label \
  -i lh.postcentral.label \
  -i lh.precuneus.label \
  -i lh.posteriorcingulate.label \
  -i lh.isthmuscingulate.label
  
mri_mergelabels \
  -o ../lh.parietalwopostcentral.label \
  -i lh.superiorparietal.label \
  -i lh.inferiorparietal.label \
  -i lh.supramarginal.label \
  -i lh.precuneus.label \
  -i lh.posteriorcingulate.label \
  -i lh.isthmuscingulate.label
  
mri_mergelabels \
  -o ../lh.central.label \
  -i lh.precentral.label \
  -i lh.postcentral.label
  
mri_mergelabels \
  -o ../lh.temporal.label \
  -i lh.superiortemporal.label \
  -i lh.middletemporal.label \
  -i lh.inferiortemporal.label \
  -i lh.bankssts.label \
  -i lh.fusiform.label \
  -i lh.transversetemporal.label \
  -i lh.entorhinal.label \
  -i lh.temporalpole.label \
  -i lh.parahippocampal.label
  
mri_mergelabels \
  -o ../lh.occipital.label \
  -i lh.lateraloccipital.label \
  -i lh.lingual.label \
  -i lh.cuneus.label \
  -i lh.pericalcarine.label

cp \
  lh.insula.label \
  ../lh.insula.label
  
