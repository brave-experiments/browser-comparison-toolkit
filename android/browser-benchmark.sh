#!/bin/bash
## Notes: Script to automate benchmarking of a browser
## Author: Matteo Varvello (Brave Software)
## Date: 09/19/2019

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT
function ctrl_c() {
    myprint "Trapped CTRL-C"
    myprint "Stop CPU monitor (give it 10 seconds...)"
	echo "false" > ".to_monitor"
    sleep 10
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
adb_file=$curr_dir"/adb-utils.sh"
load_file $adb_file
browser_actions_file=$curr_dir"/browser-actions.sh"
load_file $browser_actions_file

# script usage
usage(){
    echo "======================================================================================================================================================="
    echo "USAGE: $0 -a,--app  t,--test  b,--bright  -d,--device  -i,--id  -l,--loadtime  -r,--rep  -v,--video  --mooon  --sync,  --interact,   --work"
    echo "======================================================================================================================================================="
    echo "-a,--app        Browser under test. Default is Brave. Supported: [chrome, brave, firefox, firefox-ublock, edge, adblock, kiwi, kiwi-night]"
    echo "-b,--bright     Screen brightness (0-200)"
    echo "-d,--device     Human-readable identifier of the device under test"
    echo "-i,--id         Test identifier"
    echo "-l,--loadtime   Time allowed for a page to load"
    echo "-r,--rep        Repetition identifier"
    echo "-t,--test       Test to run (launch, browse, browse-short)"
    echo "-v,--video      Record screen"
    echo "--moon          Use monsoon (default = OFF)"
    echo "--sync          Sync is requested (default = OFF)"
    echo "--clean         Use new browser profile and cache" 
    echo "--interact      Interact with a page or not (default = OFF)" 
    echo "--work          Workload to be used"
    echo "======================================================================================================================================================="
    exit -1
}

# setup browser for next experiment 
browser_setup(){
	#clean app data
	myprint "[INFO] Cleaning app data ($app-->$package)"
	adb -s $device_id shell pm clear $package

	# start browser 
	myprint "[INFO] Launching $app ($package)."
	adb -s $device_id shell am start -n $package/$activity -a android.intent.action.VIEW

	# allow browser to load
	myprint "[INFO] Sleeping 10 secs for browser to load..."
	sleep 5

	# per browser fine grained automation
	browser_setup_automation $app $app_option $device_id $device

	# stop app
	myprint "[INFO] Closing $app ($package)..."
	#sleep 10
	adb -s $device_id shell "am force-stop $package"
}

# browse a given workload in sequence, i.e., each page in a new tab 
browse_test(){
	# local parameters
	MAX_INTERACT=40    #threshold to sync up different browsers when peforming page interactions
	
	# updating loading time
	loading_time=$1

	# clean browser (profile, cache) and do basic initial setup 
	if [ $clean_run == "true" ] 
	then 
		browser_setup
	else 
		# populate entry for network card (traffic analysis) 
		echo "Not a clean run -- populate entry for network card (traffic analysis)"
		adb -s $device_id shell am start -n $package/$activity -a android.intent.action.VIEW
		sleep 5 
		adb -s $device_id shell "am force-stop $package"
	fi 
	
	# low CPU barrier (only if monsoon data collection is used)
    sync="false"
    if [ $use_monsoon == "true" -a $sync == "true" ]
    then
        t_passed=0
        while [ ! -f ".ready_to_start" ]
        do
            myprint "Low CPU sync barrier. T-passed: $t_passed"
            sleep 5
            if [ $t_passed -gt 30 ]
            then
                myprint "WARNING - CPU barrier timeout (t_passed: $t_passed)"
                break
            fi
            let "t_passed += 5"
        done
    fi

	# start monsoon data collection if needed 
	if [ $use_monsoon == "true" ] 
	then 
		t_start_monsoon=`date +%s`
		myprint "[INFO] Starting monsoon data collection"
		sudo rm ".t_monsoon" > /dev/null 2>&1 
		monsoon_log=$rep_folder"/monsoon-log-$rep.csv"
		monsoon_data_collect
		
		myprint "monsoon sync barrier..."
		f_found="false"
		while [ $f_found == "false" ] 
		do 
			if [ -f ".t_monsoon" ] 
			then 
				t_start_sync=`cat .t_monsoon`
				myprint "monsoon sync barrier - t_start_sync: $t_start_sync"
				f_found="true"
			else 
				t_start_sync=`date +%s`
			fi 
			sleep 0.1
		done 
	fi 

	# get initial network data information 
	pi_start=`cat /proc/net/dev | grep $interface  | awk '{print $10}'`
	pi_last=$pi_start
	compute_bandwidth	
	traffic_rx=$curr_traffic
	traffic_rx_last=$traffic_rx
	myprint "[INFO] App: $app Abs. Bandwidth: $traffic_rx Pi-bdw: $pi_start"

	# iterate on workload
	artificial="true"         #use an artifical PLT or not 
	counter=0
	for url in "${W2[@]}"
	do 		
		# load app and url 
		if [ $artificial == "true" ] 
		then 
			t_launch=`date +%s`
			adb -s $device_id shell am start -n $package/$activity -a $intent -d $url
			#adb -s $device_id shell am start -n $package/$activity -d $url
			t_current=`date +%s`
			let "launch_time = t_current - t_launch" 
			let "ts = t_current - t_start_sync"
			myprint "[INFO] Launched $app ($package). URL: $url. Launch-time: $t_launch Launch-duration: $launch_time Time-since-sync: $ts" 
		fi 
			
		# wait for artificial PLT or launch and wait
		if [ $artificial == "true" ] 
		then 
			myprint "Wait for artificial PLT: $loading_time sec"
			sleep $loading_time
		else
			t_sync_launch=60
			t_launch=`date +%s`
			adb -s $device_id shell am start -n $package/org.chromium.chrome.browser.ChromeTabbedActivity -d "about"
			sleep 5 
			ans_plt=`python3 load-url-plt.py $url`
			echo "$ans_plt"
			t_current=`date +%s`
			let "t_p = t_current - t_launch"
			if [ $sync_needed == "true" ]
			then 
				let "t_sleep = t_sync_launch - t_p"
				if [ $t_sleep -gt 0 ] 
				then 
					myprint "Sleeping for $t_sleep to sync up post PLT..." 
					sleep $t_sync_launch
				else 
					myprint "WARNING -- t_sync_launch > $t_sync_launch"
				fi 
				t_current=`date +%s`
				let "ts = t_current - t_start_sync"
			fi 	
			myprint "[INFO] Launched $app ($package). URL: $url. Duration load-url-plt.py: $t_p $ans_plt Time-since-sync: $ts (Forced sync was needed)" 
		fi 

		# take a screenshot 
		#rem_shot="/sdcard/screencap.png"
		#suffix=`echo $url | md5sum | cut -f1 -d " "`
		#local_shot=$rep_folder"/screen-$suffix.png"
	    #adb -s $device_id shell screencap -p $rem_shot && adb pull $rem_shot
		#mv screencap.png $local_shot

		# interact with the page 
		time_int=15
		if [ $user_interaction == "true" ] 
		then 
			myprint "Starting page interaction (duration: $time_int)"
			page_interact $time_int
		fi 
		
		# timestamp for end of automation	
		e_time=`date +%s`

		# update traffic rx (for this URL) 
		compute_bandwidth $traffic_rx_last
		pi_curr=`cat /proc/net/dev | grep $interface  | awk '{print $10}'`
		pi_traffic=`echo "$pi_curr $pi_last" | awk '{traffic = ($1 - $2)/1000000; print traffic}'` #MB
		pi_last=$pi_curr
		traffic_rx_last=$curr_traffic
		myprint "URL: $url Bandwidth: $traffic MB PI-BDW: $pi_traffic MB"
		
		# sleep in between pages to guarantee equal exp duration
		if [ $sync_needed == "true" ] 
		then 
			let "time_passed = e_time - t_launch"
			let "t_to_sync = MAX_INTERACT - time_passed" 
			myprint "[INFO] Sleeping $t_to_sync in between pages to guarantee equal exp duration..."
			if [ $t_to_sync -gt 0 ] 
			then 
				sleep $t_to_sync
				e_time=`date +%s`
				let "ts = e_time - t_start_sync"
				myprint "[INFO] Time-since-sync: $ts"
			else 
				myprint "[!!!!] t_to_sync <=0 --> Consider increasing max interaction duration (current value: $MAX_INTERACT) [!!!!]"
			fi 
		else 
			myprint "[WARNING] Equal experiment duration was not requested. Just doing a quick 3 sec sleep between pages..."
			sleep 3
		fi 
		
		# counter update
		let "counter++"
	done

	# stop app
	myprint "[INFO] Closing $app ($package)" 
	adb -s $device_id shell "am force-stop $package"

	# compute traffic rx (at the end of the experiment)
	compute_bandwidth $traffic_rx
}

#global parameters 
test_id=`date +%s`                                        # test identifier
app="brave"                                               # browser under test (default: Chrome)
app_option="None"                                         # brwoser option (default: None)
opt="launch"                                              # default test to perform 
intent="android.intent.action.VIEW"                       # default Intent in Android
device="S9"                                               # default device is S9 (can be change with -d, --device)
declare -gA list_ids                                      # list of phone ids
declare -gA list_ips                                      # list of phone ips
declare -gA list_mac                                      # list of phone macs
declare -gA dict_screen                                   # dict of device screen widthxheigh                   
declare -gA dict_packages                                 # dict of browser packages 
declare -gA dict_activities                               # dict of browser activities
declare -ag W2                                            # array for wokload 
screen_brightness=70                                      # default screen brightness
loading_time=30                                           # default loading time
video_recording="false"                                   # record screen or not 
def_port="5555"                                           # default port for adb over wifi
rep="0"                                                   # repetition identifier 
use_monsoon="false"                                       # flag to control whether to use monsoon power meter or not 
sync_needed="false"                                       # flag to control if browsing synchronization is needed or not 
clean_run="false"                                         # flag to control if to do a clean run (clean cache and profile) or not
interface="wlan"                                          # current default interface where to collect data 
user_interaction="false"                                  # control if to interact with a page or not during a test 
workload="classic"                                        # workload to be used 
MIN_SPACE=1                                               # only run if there is at least 1GB of hard disk free 

# read input parameters
while [ "$#" -gt 0 ]
do
	case "$1" in
		-a | --app)
			shift;
			app=`echo $1 | cut -f 1 -d "-" | tr '[:upper:]' '[:lower:]'`
			app_option=`echo "$1" | cut -f 2 -d "-" | tr '[:upper:]' '[:lower:]'`
			app_id=$app
			if [ $app_option == $app ] 
			then 
				app_option="None"
			else 
				app_id=$app_id"-"$app_option
			fi 
			shift
			;;
		-t | --test)
			shift; opt="$1"; shift;
			;;
		-b | --bright)
			shift; screen_brightness="$1"; shift;
			;;
		-l | --loadtime)
			shift; loading_time="$1"; shift;
			;;
		-v | --video)
			shift; video_recording="true";
			;;
		-d | --device)
			shift; device=$1; shift;
			;;
		-i | --id)
			shift; test_id=$1; shift;
			;;
		-r | --rep)
			shift; rep=$1; shift;
			;;
		--moon)
			shift; use_monsoon="true";
			;;
		--sync)
			shift; sync_needed="true";
			;;
		--clean)
			shift; clean_run="true";
			;;
		--interact)
			shift; user_interaction="true";
			;;
		--work)
			shift; workload=$1; shift;
			;;
		-h | --help)
			usage
			;;	
		-*)
			echo "ERROR: Unknown option $1"
			usage
			;;
	esac
done 

# make sure there is enough space on the device 
free_space=`df | grep root | awk '{print $4/(1000*1000)}'`
is_full=`echo "$free_space $MIN_SPACE" | awk '{if($1 <= $2) print "true"; else print "false";}'`
if [ $is_full == "true" ] 
then
	myprint "ERROR -- Low hard disk space detected ($free_space <= $MIN_SPACE)."
	exit -1 
fi 
myprint "Current free  space on hard disk: $free_space GB"

# populate useful info about device under test 
get_device_info "phones-info.json" $device
if [ -z $adb_identifier ]
then
    myprint "Device $device not supported yet"
    exit -1
fi
usb_device_id=$adb_identifier
device_ip=$ip
device_mac=$mac_address
width=`echo $screen_res | cut -f 1 -d "x"`
height=`echo $screen_res | cut -f 2 -d "x"`

# find device id to be used and verify all is good
identify_device_id

# verify that wifi works 
wifi_test

# make sure the screen is ON
turn_device_on

# load browser package and activity needed
load_browser

# pacakge and activity selection based on browser under test 
app_info

# phone preparation for test
phone_setup_simple
#phone_setup $use_vpn $block_ads $usb_device_id $bright_savings $use_vpn
if [ $? -eq -1 ]
then
	myprint "Something went wrong during phone_setup (adb-utils.sh)"
	return -1
fi

# folder organization 
rep_folder="./browser-mesurements/$device/$test_id/$app_id"
mkdir -p $rep_folder

# manage screen recording 
if [ $video_recording == "true" ] 
then 
	t=`date +%s`
	screen_video="/sdcard/last-run-$t"
	(adb -s $device_id shell screenrecord $screen_video".mp4" &)
fi 

# start background procees to monitor CPU on the device 
log_cpu=$rep_folder"/cpu-log-$rep.csv"
clean_file $log_cpu
myprint "Starting cpu monitor. Log: $log_cpu"
echo "true" > ".to_monitor"
cpu_monitor $log_cpu & 
log_traffic=$rep_folder"/traffic-"$rep".txt"
clean_file $log_traffic 

# select the test
myprint "[INFO] Experiment requested: $opt User-interaction: $user_interaction"
case $opt in
	# just browser setup 
	"launch")
		browser_setup
		;;

	# regular browsing 
	"browse")
		#load_workload 10             # load workload to be used 
		#load_workload 100 $workload  # MV -- using Andrius news workload 
		load_workload 10 "news"       
		num_down=4                    # number of DOWN scroll 
		num_up=2                      # number of UP scrolls 
		browse_test $loading_time 10
		;;
	
	# super short browsing session 
	"browse-short")
		#load_workload 2            # load workload to be used 
		load_workload 2 "news"      # MV -- using Andrius news workload 
		num_down=4                  # number of DOWN scroll 
		num_up=2                    # number of UP scrolls 

		# run the experiment 
		browse_test $loading_time 2
		;;

	# browse full workload 
	"browse-long")
		load_workload 100          #  load workload to be used 
		num_down=6                 # number of DOWN scroll 
		num_up=4                   # number of UP scrolls 
		let "loading_time += 3" 
		browse_test $loading_time 100
		;;

	"*")
		myprint "[WARNING] test $opt not supported yet"
		exit -1 
		;;
esac

# stop monsoon data collection 
stop_monsoon

# stop monitoring CPU 
echo "false" > ".to_monitor"
sleep 5 

# re-enable notifications and screen timeout 
myprint "[INFO] ALL DONE -- Re-enabling notifications and screen timeout"
adb -s $device_id shell settings put global heads_up_notifications_enabled 1
adb -s $device_id shell settings put system screen_off_timeout 600000

# pull video recording
if [ $video_recording == "true" ] 
then 
	pid=`ps aux | grep "screenrecord" | grep -v "grep" | awk '{print $2}'`
	kill -9 $pid 
	sleep 1 
	adb -s $device_id pull $screen_video".mp4" ./
	adb -s $device_id shell rm $screen_video".mp4"
	local_screen_video=`echo $screen_video | awk -F "/" '{print $NF}'`
	myprint "[INFO] Converting screen recording from .mp4 to .webm..."
	ffmpeg -i $local_screen_video".mp4" -c:v libvpx -crf 10 -b:v 1M -c:a libvorbis $local_screen_video".webm"
	mr $local_screen_video".mp4"
	myprint "[INFO] Check video recording: $local_screen_video.webm"
fi 

# report on free space 
free_space=`df | grep root | awk '{print $4/(1000*1000)}'`
myprint "Current free  space on hard disk: $free_space GB"

# all good 
echo "DONE :-)"
