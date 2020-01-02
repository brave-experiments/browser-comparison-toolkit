#!/bin/bash 
# NOTES: master script used to benchmark Brave 1.0 against other browsers 
# Author: Matteo Varvello 
# Date: 10/15/2019

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT
function ctrl_c() {
    myprint "Trapped CTRL-C"
    myprint "EXIT!"
    exit -1
}

#helper to  load utilities files
load_file(){
    if [ -f $1 ]
    then
        source $1
    else
        echo "Utility file $1 is missing"
        exit -1
    fi
}

# import utilities files needed
curr_dir=`pwd`
f=$curr_dir"/common.sh"
load_file $f

# params 
REM_FOLDER="/home/pi/batterylab/src/remote-access"
ADB_PORT="5555"
SESSION_ID=`date +%s`
TEST_OPT="browse"
DEVICE_NAME="J7DUO"
LOAD_TIME=$1
WORKLOAD=$2
POWER_MONITOR=$3
NUM_REPS=$4
INTERACTION=$5
TIMEOUT=3600

# get device info needed
get_device_info "phones-info.json" $DEVICE_NAME
DEVICE=$adb_identifier
DEVICE_IP=$ip
DEVICE_WIFI="${DEVICE_IP}:${ADB_PORT}"

# common preparation
mkdir -p "logs"

# check if monsoon should be started 
if [ ${POWER_MONITOR} == "true" ] 
then
	echo "Activating power monitor --> ./safe-switch.sh -d ${DEVICE_NAME} -o batt-to-mon"
	./safe-switch.sh -d ${DEVICE_NAME} -o batt-to-mon
	echo "Updating device identifier: ${DEVICE_WIFI}"
	DEVICE=${DEVICE_WIFI}
	
	# stop potential remote access 
	cd ${REM_FOLDER}
	./stop-run.sh
	cd - > /dev/null
fi 

# calculate option needed 
common_opt=" -t "$TEST_OPT" -i "$SESSION_ID" --clean  -l "$LOAD_TIME" --work "$WORKLOAD
if [ ${POWER_MONITOR} == "true" ]
then
	common_opt=$common_opt" --moon "
fi 
if [ ${INTERACTION} == "true" ]
then
	common_opt=$common_opt" --interact "
fi 
common_opt=$common_opt" -d "$DEVICE

# iterate on browsers and repetitions needed 
browser_list=( 'brave' 'chrome' )
#browser_list=( 'brave' 'chrome' 'opera' 'firefox' )
for((i=0; i<NUM_REPS; i++))
do
	for browser in "${browser_list[@]}"
	do
		res_folder="./browser-mesurements/$DEVICE/$SESSION_ID/$browser/"
		mkdir -p $res_folder 
		log_file=$res_folder"/run-$i.log"
		opt=$common_opt" -a "$browser" --rep "$i
		echo "timeout ${TIMEOUT} ./browser-benchmark.sh  ${opt} > ${log_file} 2>&1"
		timeout ${TIMEOUT} ./browser-benchmark.sh  ${opt} > ${log_file} 2>&1
	done
done

if [ ${POWER_MONITOR} == "true" ] 
then
	echo "Test is DONE! Removing battery bypass and turning off monsoon"
	./safe-switch.sh -d ${DEVICE_NAME}  -o mon-to-batt
fi 

echo "All done"
