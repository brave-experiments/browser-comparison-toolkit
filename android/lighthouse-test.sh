#!/bin/bash
## Notes:  PLT testing script (using lighthouse) 
## Author: Matteo Varvello (Brave Software)
## Date:   10/28/2019

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
adb_file=$curr_dir"/adb-utils.sh"
load_file $adb_file
curr_dir=`pwd`
browser_actions_file=$curr_dir"/browser-actions.sh"
echo $browser_actions_file
load_file $browser_actions_file

#function to wait for VPN to be ready
wait_for_vpn(){
	MAX_CONN_TIME=30
	t_s=`date +%s`
	echo "Waiting up to $MAX_CONN_TIME secs for <<Initialization Sequence Complete>>"
	while [ $vpn_ready == "false" ]
	do
		if [ ! -f $log_vpn ] 
		then 
			echo "VPN-log $log_vpn is missing"
			sleep 3 
		fi 
		cat $log_vpn | grep "Initialization Sequence Completed"
		ans=$?
		if [ $ans -eq 0 ]
		then
			my_ip=`curl -s https://ipinfo.io/ip`
			vpn_ready="true"
			echo "VPN setup. New IP: $my_ip"
		else
			sleep 1
			t_c=`date +%s`
			let "t_p = t_c - t_s"
			if [ $t_p -gt $MAX_CONN_TIME -a $vpn_ready == "false" ]
			then
				echo "Timeout detected for $curr_vpn - Aborting"
				break
			fi
		fi
	done
}

# function to make sure VPN is off
vpn_off(){
	echo "turning VPN off"
	for pid in `ps aux | grep "openvpn" | grep -v "grep" | awk '{print $2'}`
	do 
		sudo  kill -9 $pid 
	done  
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
    browser_setup_automation $app $app_option $device_id $device_name
}

# parameters 
#device_id=$1
device_name=$1
app=$2
workload=$3
test_id=$4
app_option="None"
intent="android.intent.action.VIEW"
use_vpn="false"
log_vpn="log-vpn.txt"
vpn_ready="false"
PORT=9222
screen_brightness=70
activity="com.google.android.apps.chrome.Main"

# timeout setup 
MAX_DUR=200000
let "MAX_DURATION = MAX_DUR/1000 + 10"

# turn off previous VPN 
vpn_off
my_ip=`curl -s https://ipinfo.io/ip`
echo "Current IP: $my_ip" 

# retrieve info about device under test
get_device_info "phones-info.json" $device_name
if [ -z $adb_identifier ]
then
    myprint "Device $device not supported yet"
    exit -1
fi
device_id=$adb_identifier

# VPN setup 
if [ $use_vpn == "true" ] 
then 
	cd /home/pi/openvpn
	(sudo openvpn --config us-ca-102.protonvpn.com.udp.ovpn --auth-user-pass pass.txt > $log_vpn 2>&1 &)
	wait_for_vpn
	cd - > /dev/null 
fi 

# prep the device 
phone_setup_simple

# load URLs to be tested 
c=0
while read url
do 
	W2[$c]="$url"
	let "c++"
done < "$workload"

# prepare both chrome and brave 
if [ $app == "brave" ] 
then 
	package="com.brave.browser"
elif [ $app == "chrome" ] 
then 
	package="com.android.chrome"
fi 
browser_setup 

# prepping for  lighthouse
adb kill-server
sleep 5 
adb devices 
echo "Activating port forwarding for devtools (9222)"
adb -s $device_id forward tcp:$PORT localabstract:chrome_devtools_remote
sleep 5 

# iterate on URLs
res_folder="PLT-results/"$test_id"/"$app
mkdir -p $res_folder 
for((i=0; i<c; i++))
do
	url=${W2[$i]}
	id=`echo $url | md5sum | cut -f1 -d " "`
	log_run=$id".log"
	output_path=$res_folder"/"$id".json" 
	echo "$url $output_path"
	timeout $MAX_DURATION lighthouse $url --max-wait-for-load $MAX_DUR --port=9222 --save-assets --emulated-form-factor=none --throttling-method=provided --output-path=$output_path --output=json
done 

# turn off VPN if it was used
if [ $use_vpn == "true" ] 
then
	vpn_off
fi 
