#!/bin/bash


if [[ $1 == "" ]]
then
  echo "usage: $0 volumefile"
  echo 
  echo "hrT1 volume lesion file: file with lesion ROI (voxels = 1) in register to hrT1 orig.mgz"
  echo "naming scheme: <ID>.<hemi>.filename.mgz, e.g.: A.BCDE12F.lh.hrT1orig.lesion.mgz"
  echo "all output will also be written to the current working directory"
  exit 1
fi	


hrT1_volumefile=$(realpath $1)
lesiondir=$(dirname $hrT1_volumefile)
subject_basename=$(basename $1)
subject_basename=${subject_basename:0:9}
hemi=$(basename $1)
hemi=${hemi:10:2}

echo $hrT1_volumefile
echo $subject_basename
echo $hemi

source $SCRIPTS_DIR/s010_set_variables.sh  # for $SUBJECTS_DIR

cd $lesiondir

#############################################################################################

# map volume ROI to surface
mri_vol2surf \
  --mov ${hrT1_volumefile} \
  --regheader ${subject_basename}_hrT1 \
  --hemi ${hemi} \
  --o ${hrT1_volumefile}_surf.mgh \
  --projfrac-max -1 1 0.2

# convert surface data to label in native space
mri_vol2label \
  --i ${hrT1_volumefile}_surf.mgh \
  --l ${hrT1_volumefile}_label.label \
  --id 1 \
  --surf ${subject_basename}_hrT1 ${hemi} white


# map to fsaverage_sym lh
if [[ $hemi == "lh" ]]
then
	mris_apply_reg \
	  --src-label ${hrT1_volumefile}_label.label \
	  --trg ${hrT1_volumefile}_label.lh.fsaverage_sym.label \
	  --streg ${SUBJECTS_DIR}/${subject_basename}_hrT1/surf/lh.fsaverage_sym.sphere.reg \
	          ${SUBJECTS_DIR}/fsaverage_sym/surf/lh.sphere.reg
else
	mris_apply_reg \
	  --src-label ${hrT1_volumefile}_label.label \
	  --trg ${hrT1_volumefile}_label.lh.fsaverage_sym.label \
	  --streg ${SUBJECTS_DIR}/${subject_basename}_hrT1/xhemi/surf/lh.fsaverage_sym.sphere.reg \
	          ${SUBJECTS_DIR}/fsaverage_sym/surf/lh.sphere.reg
fi

# opening and closing surface label to close holes
mri_label2label \
	--srclabel ${hrT1_volumefile}_label.lh.fsaverage_sym.label --srcsubject fsaverage_sym \
	--trglabel ${hrT1_volumefile}_label.lh.fsaverage_sym.label --trgsubject fsaverage_sym \
	--hemi lh --close 1 --open 1 --regmethod surface

#############################################################################################

# co-register subject_hrT1/mri/orig.mgz to subject_MP2/mri/orig.mgz using bbregister
bbregister \
  --s ${subject_basename}_MP2 \
  --mov ${SUBJECTS_DIR}/${subject_basename}_hrT1/mri/orig.mgz \
  --t1 \
  --reg hrT1_to_MP2.dat

# apply registration to the lesion ROI volume (so that it is now in register to subject_MP2/mri/orig.mgz
mri_vol2vol \
  --mov ${hrT1_volumefile} \
  --o ${hrT1_volumefile}_regMP2.mgz \
  --reg hrT1_to_MP2.dat \
  --fstarg


# now same steps as for hrT1-based lesion mask
# map volume ROI to surface
mri_vol2surf \
  --mov ${hrT1_volumefile}_regMP2.mgz \
  --regheader ${subject_basename}_MP2 \
  --hemi ${hemi} \
  --o ${hrT1_volumefile}_regMP2_surf.mgh \
  --projfrac-max -1 1 0.2

# additional binarization with threshold 0.5 because coregistration/reslicing
mri_binarize \
  --i ${hrT1_volumefile}_regMP2_surf.mgh \
  --o ${hrT1_volumefile}_regMP2_surf.mgh \
  --min 0.5

# convert surface data to label in native space
mri_vol2label \
  --i ${hrT1_volumefile}_regMP2_surf.mgh \
  --l ${hrT1_volumefile}_regMP2_label.label \
  --id 1 \
  --surf ${subject_basename}_MP2 ${hemi} white

# map to fsaverage_sym lh
if [[ $hemi == "lh" ]]
then
	mris_apply_reg \
	  --src-label ${hrT1_volumefile}_regMP2_label.label \
	  --trg ${hrT1_volumefile}_regMP2_label.lh.fsaverage_sym.label \
	  --streg ${SUBJECTS_DIR}/${subject_basename}_MP2/surf/lh.fsaverage_sym.sphere.reg \
	          ${SUBJECTS_DIR}/fsaverage_sym/surf/lh.sphere.reg
else
	mris_apply_reg \
	  --src-label ${hrT1_volumefile}_regMP2_label.label \
	  --trg ${hrT1_volumefile}_regMP2_label.lh.fsaverage_sym.label \
	  --streg ${SUBJECTS_DIR}/${subject_basename}_MP2/xhemi/surf/lh.fsaverage_sym.sphere.reg \
	          ${SUBJECTS_DIR}/fsaverage_sym/surf/lh.sphere.reg
fi

# opening and closing surface label to close holes
mri_label2label \
	--srclabel ${hrT1_volumefile}_regMP2_label.lh.fsaverage_sym.label --srcsubject fsaverage_sym \
	--trglabel ${hrT1_volumefile}_regMP2_label.lh.fsaverage_sym.label --trgsubject fsaverage_sym \
	--hemi lh --close 1 --open 1 --regmethod surface

#############################################################################################

# intersection of hrT1- and MP2-volume based surface labels (for classifier training)
labels_intersect ${hrT1_volumefile}_label.lh.fsaverage_sym.label ${hrT1_volumefile}_regMP2_label.lh.fsaverage_sym.label ${hrT1_volumefile}_final_intersect.label

# dilated union label (for automated cluster evaluation)
labels_union ${hrT1_volumefile}_label.lh.fsaverage_sym.label ${hrT1_volumefile}_regMP2_label.lh.fsaverage_sym.label ${hrT1_volumefile}_final_union.label

mri_label2label \
	--srclabel ${hrT1_volumefile}_final_union.label --srcsubject fsaverage_sym \
	--trglabel ${hrT1_volumefile}_final_union_dilated.label --trgsubject fsaverage_sym \
	--hemi lh --dilate 4 --regmethod surface

#############################################################################################
# surface registration quality check: check that labels are similar 
intersect_size=`cat ${hrT1_volumefile}_final_intersect.label | wc -l`
union_size=`cat ${hrT1_volumefile}_final_union.label | wc -l`

if (( $(echo `echo ${intersect_size} \* 2.0 | bc` \< ${union_size} | bc ) ))
then
	echo "######### ERROR ##############"
	echo "hrT1/MP2-volume-based labels appear not similar"
	exit 1
fi



#############################################################################################
# display for quality control
freeview --hide-3d-slices --hide-3d-frames \
  -f \
  ${SUBJECTS_DIR}/${subject_basename}_hrT1/surf/${hemi}.inflated:label=${hrT1_volumefile}_label.label \
  ${SUBJECTS_DIR}/${subject_basename}_MP2/surf/${hemi}.inflated:label=${hrT1_volumefile}_regMP2_label.label \
  ${SUBJECTS_DIR}/fsaverage_sym/surf/lh.inflated:label=${hrT1_volumefile}_label.lh.fsaverage_sym.label:label=${hrT1_volumefile}_regMP2_label.lh.fsaverage_sym.label:label=${hrT1_volumefile}_final_union_dilated.label

#freeview --hide-3d-slices --hide-3d-frames\
#  -v ${SUBJECTS_DIR}/${subject}/mri/orig.mgz ${PWD}/${volumefile}:colormap=jet \
#  -f ${SUBJECTS_DIR}/${subject}/surf/${hemi}.white:overlay=${PWD}/${volumefile}_ns_surface.mgh:edgecolor=overlay:hide_in_3d=true \
#     ${SUBJECTS_DIR}/${subject}/surf/${hemi}.inflated:label=${PWD}/${volumefile}_ns.label \
#     ${SUBJECTS_DIR}/fsaverage_sym/surf/lh.inflated:label=$fsaverage_sym_orig_labelfile \
#     ${SUBJECTS_DIR}/fsaverage_sym/surf/lh.inflated:label=$fsaverage_sym_labelfile

# cleanup
#rm ${hrT1_volumefile}_surf.mgh
#rm ${hrT1_volumefile}_label.label
#rm ${hrT1_volumefile}_label.lh.fsaverage_sym.label
#rm ${hrT1_volumefile}_regMP2.mgz
#rm ${hrT1_volumefile}_regMP2_surf.mgh
#rm ${hrT1_volumefile}_regMP2_label.label
#rm ${hrT1_volumefile}_regMP2_label.lh.fsaverage_sym.label
#rm hrT1_to_MP2*


