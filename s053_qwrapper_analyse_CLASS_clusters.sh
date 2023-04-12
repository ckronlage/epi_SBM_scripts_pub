#!/bin/bash

source $SCRIPTS_DIR/s010_set_variables.sh

if [ ! -d 0stats ]
then
    mkdir 0stats
fi
cd 0stats

if [ ! -d gridlogs ]
then
    mkdir gridlogs
fi

cd gridlogs

###################################################
cat > gridjob_analyse_CLASS_clusters.sh << EOF       
#!/bin/bash                                      
echo "Starting job: \$JOB_ID@\$HOSTNAME"                 
echo NOW=\$(date +%F\ %H:%M:%S)                               
echo PWD=\$PWD                                                   
echo JOB_ID=\$JOB_ID                                           
echo TASK_ID=\$TASK_ID                          
echo SGE_TASK_ID=\$SGE_TASK_ID                 
echo HOSTNAME=\$HOSTNAME                                    
echo
echo cmd = matlab9.11 -nodisplay -batch "addpath('$SCRIPTS_DIR'); s050_analyse_clusters('classifier_pred_map','\$1','\$2')"
echo

matlab9.11 -nodisplay -batch "addpath('$SCRIPTS_DIR'); s050_analyse_clusters('classifier_pred_map','\$1','\$2')"

echo
echo "Done with job: \$JOB_ID@\$HOSTNAME"       
echo NOW=\$(date +%F\ %H:%M:%S) 
times                                                                         
EOF
###################################################

chmod +x gridjob_analyse_CLASS_clusters.sh

for suffix in $listofsuffixes
do
	for measure in "MAH" #"RFC" "IFST" "MAH"
	do 
		for usedmeasures in 1 2 3 4 5 6
		do
		qsub \
		  -q matlab.q \
		  -cwd -V -b y -j n ./gridjob_analyse_CLASS_clusters.sh $suffix ${measure}.usedmeasures${usedmeasures}
		  
		done
	done
done

