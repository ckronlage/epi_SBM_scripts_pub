#!/bin/bash

source $SCRIPTS_DIR/s010_set_variables.sh

cd 0gridlogs

###################################################
cat > gridjob_normalize_intensities.sh << EOF       
#!/bin/bash                                      
echo "Starting job: \$JOB_ID@\$HOSTNAME"                 
echo NOW=\$(date +%F\ %H:%M:%S)                               
echo PWD=\$PWD                                                   
echo JOB_ID=\$JOB_ID                                           
echo TASK_ID=\$TASK_ID                          
echo SGE_TASK_ID=\$SGE_TASK_ID                 
echo HOSTNAME=\$HOSTNAME                                    
echo
echo cmd = matlab9.11 -nodisplay -batch "addpath('$SCRIPTS_DIR'); s029_normalize_intensities('\$1','\$2')"
echo

matlab9.11 -nodisplay -batch "addpath('$SCRIPTS_DIR'); s029_normalize_intensities('\$1','\$2')"

echo
echo "Done with job: \$JOB_ID@\$HOSTNAME"       
echo NOW=\$(date +%F\ %H:%M:%S) 
times                                                                         
EOF
###################################################

chmod +x gridjob_normalize_intensities.sh

for suffix in "_hrT1" "_MP2" #$listofsuffixes
do
	for subject in $listofsubjects
	do
		qsub \
		  -q matlab.q \
		  -cwd -V -b y -j n ./gridjob_normalize_intensities.sh $subject $suffix
	done
done

