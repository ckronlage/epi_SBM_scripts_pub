#!/bin/bash

source $SCRIPTS_DIR/s010_set_variables.sh

cd 0gridlogs

###################################################
cat > gridjob_run_GLM.sh << EOF       
#!/bin/bash                                      
echo "Starting job: \$JOB_ID@\$HOSTNAME"                 
echo NOW=\$(date +%F\ %H:%M:%S)                               
echo PWD=\$PWD                                                   
echo JOB_ID=\$JOB_ID                                           
echo TASK_ID=\$TASK_ID                          
echo SGE_TASK_ID=\$SGE_TASK_ID                 
echo HOSTNAME=\$HOSTNAME                                    
echo
echo cmd = matlab9.11 -nodisplay -batch "addpath('/home/ckronlage/epi/epi_SBM_scripts/'); s041_run_GLM('\$1','\$2')"
echo

matlab9.11 -nodisplay -batch "addpath('/home/ckronlage/epi/epi_SBM_scripts/'); s041_run_GLM('\$1','\$2')"

echo
echo "Done with job: \$JOB_ID@\$HOSTNAME"       
echo NOW=\$(date +%F\ %H:%M:%S) 
times                                                                         
EOF
###################################################

chmod +x gridjob_run_GLM.sh

for suffix in $listofsuffixes
do
	for subject in $listofsubjects
	do
		qsub \
		  -q matlab.q \
		  -cwd -V -b y -j n ./gridjob_run_GLM.sh $suffix $subject
	done
done

