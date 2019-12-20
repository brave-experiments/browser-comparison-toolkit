#!/bin/bash 
## Notes: Manage battery bypass of batterylab devices 
## Author: Matteo Varvello (Brave Software)
## Date: 04/10/2019

# helper to load files
load_file(){
    if [ -f $1 ]
    then
        source $1
    else
        echo "Utility file $1 is missing"
        exit 1
    fi
}

# import file with common function
# import utilities files needed
adb_file="/home/pi/batterylab/src/automation/adb-utils.sh"
load_file $adb_file

# fixing  uhubctl PATH so it is callable by jenkins 
uhubctl_PATH="/home/pi/batterylab/src/setup/uhubctl"

# script usage
usage(){
    echo "=================================================================================================================="
    echo "USAGE: $0 -d,--device    -o,--opt    --wifi"
    echo "=================================================================================================================="
    echo "-d,--device    Human-readable identifier of the device under test. Default: DUO "
    echo "-o,--opt       Safe switch requested [mon-to-batt, batt-to-mon]"
    echo "--vrs          Version: 1.0 [original, imperial] 1.1 [last meross, northwestern], 1.2 [no meross, imperial]"
    echo "--wifi         Use wifi or not [default: true]"
    echo "=================================================================================================================="
    exit -1
}

# general parameters
#monsoon_path=$HOME"/batterylab/android-energy/src/monsoon"  # path for monsoon scripts
monsoon_path=$HOME"/batterylab/src/monsoon"                  # path for monsoon scripts
device="DUO"                                                 # human readable device identifier
opt=""                                                       # option for the switch [mon-to-batt, batt-to-mon]
def_port=5555                                                # default TCP port for adb over wifi 
screen_id=3                                                  # (virtual) display ID
vrs="1.1"                                                    # 1.0 = original imperial, 1.1 = new meross code (northwestern), 1.2 = no meross needed (imperial)
monsoon_channel="monsoon"                                    # default channel for monsoon 
use_wifi="true"                                              # use wifi or not 

# guess vrs based on host 
machine_name=`hostname`
if [ $machine_name == "batterylab-northwestern" ]
then 
	vrs="1.1"
elif [ $machine_name == "batterylab-imperial" -o $machine_name == "batterylab-nj" ]
then
	vrs="1.2"
else 
	myprint "Machine $machine_name is unknown. Verify vrs for power monitor activation (1.0, 1.1, 1.2). Defaulting to 1.1"
fi 

# read input parameters
while [ "$#" -gt 0 ]
do
    case "$1" in
        -d | --device)
            shift;
            device=$1
            shift;
            ;;
        -o | --opt)
            shift;
            opt=$1
            shift;
            ;;
        --vrs)
            shift;
            vrs=$1
            shift;
            ;;
        --wifi)
            shift;
            use_wifi=$1
            shift;
            ;;
        -h | --help)
            usage
            ;;
        -*)
            myprint "ERROR: Unknown option $1"
            usage
            ;;
    esac
done

# learn which device is on relay if any.
if [ $opt == "learn" ]
then
    channel=`python3 lab-control.py -ra | grep "ch" | grep -w "on" | cut -f 1 -d ":"`
    if [ -z $channel ]
    then
        myprint "No battery bypass was found. Turning monsoon off if needed (vrs=$vrs)"
        if [ $vrs == "1.0" ]
        then
            sudo python3 $monsoon_path/power-off.py
        elif [ $vrs == "1.1" ]
        then
            python3 $monsoon_path/meross-start.py off
        elif [ $vrs == "1.2" ]
        then
            python3 lab-control.py -d $monsoon_channel -w off
        fi
        exit 0
    else
        get_device_name_from_channel "phones-info.json" $channel
        device=$name
        myprint "Battery bypass found for device $device on channel $channel"
        opt="mon-to-batt"
    fi
fi

# populate device info
get_device_info "phones-info.json" $device
if [ -z $adb_identifier ]
then
    myprint "Device $device not supported yet"
    exit -1
fi 
device_id=$adb_identifier
device_id_wifi=$ip":"$def_port
device_ip=$ip
device_volt=$voltage
device_channel=$channel
device_mac=$mac_address

#[monsoon --> battery]
if [ $opt == "mon-to-batt" ] 
then
	# make sure USB is off for iPhone 
	if [ $device_os == "ios" ] 
	then
		myprint "turn off USB"
		sudo env "PATH=$uhubctl_PATH" uhubctl -l 1-1 -p 2 -a off -r 100
	else 
		myprint "turn on USB"
		sudo env "PATH=$uhubctl_PATH" uhubctl -l 1-1 -p 2 -a on
	fi  
	sleep 10

	# do the switch 
	myprint "Switching relay from monsoon to battery (potential phone reboot)..."
	python3 lab-control.py -d $device_channel -w off
	if [ $? -eq 1 ] 
	then 
		myprint "Something wrong with relay switch"
		exit -1 
	fi 
	sleep 10

	# turn off monsoon 
	myprint "Turning OFF monsoon" 
	if [ $vrs == "1.0" ] 
	then 
		sudo python3 $monsoon_path/power-off.py
	elif [ $vrs == "1.1" ]
	then 
		python3 $monsoon_path/meross-start.py off
	elif [ $vrs == "1.2" ]
	then
		python3 lab-control.py -d $monsoon_channel -w off
	fi 

	if [ $device_os == "android" ]
    then
		# wait for device to be up
		myprint "Checking that phone is on..."
		wait_for_phone
		# disconnect wifi (if it was connected)
		myprint "disconecting adb over wifi (if there)"
		adb disconnect $device_ip:$def_port
		# switch screen mirrorring to USB-adb
		#switch_screen $device_id	
	fi 
	if [ $device_os == "ios" ] 
	then
		myprint "Wait 60 seconds for iphone to be OFF, then turn USB back on"
		sleep 60
		sudo env "PATH=$uhubctl_PATH" uhubctl -l 1-1 -p 2 -a on
	fi 
#[battery --> monsoon]
elif [ $opt == "batt-to-mon" ] 
then
	target_volt=`echo $device_volt | awk '{target_volt = $1 + 0.3; print target_volt}'`
	monsoon_state=`python3 lab-control.py -r -d monsoon`
	if [ $monsoon_state == "off" ]
	then 
		# always make sure that USB is on (needed by Monsoon)
		myprint "turn on USB"
		sudo env "PATH=$uhubctl_PATH" uhubctl -l 1-1 -p 2 -a on
		sleep 10
		
		#turn on monsoon and give voltage 
		myprint "Starting monsoon!"
		if [ $vrs == "1.1" ]
		then 
			python3 $monsoon_path/meross-start.py on
		elif [ $vrs == "1.2" ]
		then
			python3 lab-control.py -d $monsoon_channel -w on
		fi 
		sleep 10
	else 
		myprint "Monsoon already on was detected"
	fi 
	
	# do the relay switch (potential phone reboot) 
	device_state=`python3 lab-control.py -r -d $device_channel`
	if [ $device_state == "off" ]
	then 
		# give (right) power via monsoon and verify it worked 
		myprint "Set right voltage for this device: $target_volt (nominal voltage: $device_volt)"
		sudo python3 $monsoon_path/set-target-voltage.py $target_volt
		if [ $? -eq 1 ] 
		then 
			myprint "ERROR -- Something wrong activating monsoon" 
			exit 1 
		fi 
		sleep 5

		# do the relay switch 
		myprint "Switching relay from battery to monsoon (potential phone reboot...)"
		python3 lab-control.py -d $device_channel -w on
		sleep 10
		# wait for phone to come up
		wait_for_phone
		if [ $? -ne 0 ] 
		then 
			exit 1
		fi 
	else 
		myprint "Battery bypass already found for $device (channel: $device_channel)"
	fi 
		
	# default to adb over wifi for android
	if [ $device_os == "android" -a $use_wifi == "true" ]
	then
		# verify device-identifier 
		adb devices | grep $device_id > /dev/null 
		if [ $? -eq 1 ] 
		then 
			adb devices | grep $device_id_wifi
			if [ $? -eq 0 ]
			then
				myprint "Device is reachable via ADB over WiFi. Updating device_id to $device_id_wifi"
				device_id=$device_id_wifi
			else 
				myprint "ERROR. Something is wrong. The device $device is neither reachable via USB ($device_id) or WiFi ($device_id_wifi)"
				exit 1 
			fi 
		fi 

		# verify wireless connectivity is right (and potentially fix things) 
		wifi_full_test
 
		# enable wifi over adb, if needed 
		if [ $device_id != "$device_id_wifi" ] 
		then
			enable_adb_wifi $device_id
			if [ $? -eq 1 ]
			then
				myprint "ERROR -- Something wrong while activating wifi over adb"
				exit 1
			fi
		else 
			myprint "The device is already reachable over WiFi"
		fi 
	fi
	if [ $device_os == "ios" -a $use_wifi == "true" ]
	then
		iphone_wifi_test
	fi 

	# turn off USB
	myprint "turn off USB"
	sudo env "PATH=$uhubctl_PATH" uhubctl -l 1-1 -p 2 -a off -r 100
else 
	myprint "Option $opt not supported yet"
	exit 1 
fi 
