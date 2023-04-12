#!/bin/bash

source $SCRIPTS_DIR/s010_set_variables.sh

folder=0rand_stats
if [ ! -d $folder ]
then
    mkdir $folder
fi
cd $folder

if [ ! -d gridlogs ]
then
    mkdir gridlogs
fi
cd gridlogs

###################################################
cat > gridjob_simulate_random_clusters.sh << EOF       
#!/bin/bash                                      
echo "Starting job: \$JOB_ID@\$HOSTNAME"                 
echo NOW=\$(date +%F\ %H:%M:%S)                               
echo PWD=\$PWD                                                   
echo JOB_ID=\$JOB_ID                                           
echo TASK_ID=\$TASK_ID                          
echo SGE_TASK_ID=\$SGE_TASK_ID                 
echo HOSTNAME=\$HOSTNAME                                    
echo
echo cmd = matlab9.11 -nodisplay -batch "addpath('$SCRIPTS_DIR'); for i=1:\$1 ; s050_analyse_clusters('rand_sim'); end;"
echo

matlab9.11 -nodisplay -batch "addpath('$SCRIPTS_DIR'); for i=1:\$1 ; s050_analyse_clusters('rand_sim'); end;"

echo
echo "Done with job: \$JOB_ID@\$HOSTNAME"       
echo NOW=\$(date +%F\ %H:%M:%S) 
times                                                                         
EOF
###################################################

chmod +x gridjob_simulate_random_clusters.sh

JOBS=20
SIMSPERJOB=5000
for i in `seq $JOBS`; do
	qsub \
	  -q matlab.q \
	  -cwd -V -b y -j n ./gridjob_simulate_random_clusters.sh $SIMSPERJOB
done

