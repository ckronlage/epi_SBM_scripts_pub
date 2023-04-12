#!/bin/bash

source $SCRIPTS_DIR/s010_set_variables.sh

cd 0gridlogs

###################################################
cat > gridjob_run_classifier.sh << EOF       
#!/bin/bash                                      
echo "Starting job: \$JOB_ID@\$HOSTNAME"                 
echo NOW=\$(date +%F\ %H:%M:%S)                               
echo PWD=\$PWD                                                   
echo JOB_ID=\$JOB_ID                                           
echo TASK_ID=\$TASK_ID                          
echo SGE_TASK_ID=\$SGE_TASK_ID                 
echo HOSTNAME=\$HOSTNAME                                    
echo
echo cmd = matlab9.11 -nodisplay -batch "addpath('$SCRIPTS_DIR'); s046_run_RFC('\$1','\$2',\$3)"
echo

matlab9.11 -nodisplay -batch "addpath('$SCRIPTS_DIR'); s046_run_classifier('\$1','\$2',\$3)"

echo
echo "Done with job: \$JOB_ID@\$HOSTNAME"       
echo NOW=\$(date +%F\ %H:%M:%S) 
times                                                                         
EOF
###################################################

chmod +x gridjob_run_classifier.sh

for suffix in $listofsuffixes
do
	for subject in $listofsubjects
	do
		for opt_usedmeasures in "1" "2" "3" "4" "5" "6"
		do
			qsub \
			  -q matlab.q \
			  -cwd -V -b y -j n -l mem_free=10G ./gridjob_run_classifier.sh $suffix $subject $opt_usedmeasures
		done
	done
done

