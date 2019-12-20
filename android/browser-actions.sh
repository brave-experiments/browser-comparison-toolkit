#!/bin/bash
## Browser automation - one function per browser. 
## To add a new browser, just add a function and hook it up with browser_setup_automation
## Author: Matteo Varvello (Brave Software)
## Date: 09/19/2019

# helper funtion to  perform a tap  via ADB 
tap_screen(){
	x=$1
	y=$2
	t=$3
	echo "adb -s $device_id shell \"input tap $x $y\"" 
	adb -s $device_id shell "input tap $x $y" 
	sleep $t 
}

# prepare browser for an experiment 
browser_setup_automation(){
	# required input  parameters 
	app=$1
	app_option=$2
	device_id=$3
	device_name=$4 

	# detect foreground activity -- used for detecting eventual onboarding
	foreground_activity=`adb -s $device_id shell dumpsys window windows | grep -E 'mCurrentFocus' | cut -f 2 -d "/" | sed s/"}"// | awk -F '.' '{print $NF}'`
	myprint "Foreground Activity: $foreground_activity"
	
	# FIREFOX 
	if [ $app == "firefox" ] 
	then 
		myprint "firefox setup - nothing to do unless it is a fresh install? Sleeping 15..."
		sleep 15
		#firefox_setup
	# FIREFOX-FOCUS
	elif [ $app == "firefox_focus" ] 
	then 
		firefox_focus_setup
	#EDGE
	elif [ $app == "edge" ] 
	then
		edge_setup
	#ADBLOCK
	elif [ $app == "adblock" ] 
	then
		myprint "[INFO] Nothing to be done for adblock browser" 
	#KIWI
	elif [ $app == "kiwi" ] 
	then 
		kiwi_setup
	# CHROME
	elif [ $app == "chrome" ] 
	then 
		#chrome_setup
		if [ $foreground_activity == "FirstRunActivity" ] 
		then 
			myprint "chrome setup -- Onboarding detected..."
			chrome_setup_new
		else 
			myprint "chrome setup -- Onboarding not detected. Sleeping 15 sec..."
			sleep 15
		fi 
	# BRAVE
	elif [ $app == "brave" ] 
	then 
		if [ $foreground_activity == "OnboardingActivity" ] 
		then 
			myprint "brave setup"
			brave_setup
		elif [ $foreground_activity == "Main" ]
		then
			myprint "brave setup -- Onboarding not detected. Sleeping 15 sec..."
			sleep 15
		else 
			myprint "brave setup -- New activity detected. Check: $foreground_activity"
			sleep 15
		fi 
	#OPERA
	elif [ $app == "opera" ] 
	then 
		opera_setup
	fi 
}

# opera setup 
opera_setup(){
	sleep 5 
	if [ $device_name == "LM-X210" ] 
	then 
		tap_screen 621 1126 3 
	elif [ $device_name == "J7DUO" ] 
	then
		tap_screen 350 1201 3
		tap_screen 622 1215 3
		tap_screen 622 1215 3
	elif [ $device_name == "E5PLAY" ]
	then
		tap_screen 234 820 3
		tap_screen 388 834 3 
		tap_screen 388 834 3 
	elif [ $device_name == "SM-J337A" ]
	then 
		 tap_screen 657 1218 3
	fi 
}

# chrome setup
chrome_setup_new(){
	if [ $device_name == "LM-X210" ] 
	then 
		tap_screen 366 1131 3 
		tap_screen 625 1113 3
	elif [ $device_name == "J7DUO" ] 
	then
		tap_screen 357 1216 3 
		tap_screen 612 1205 3
	elif [ $device_name == "S9" ] 
	then
		tap_screen 551 1980 3 
		tap_screen 900 1969 3
	elif [ $device_name == "E5PLAY" ]
	then
		tap_screen 225 835 3
		tap_screen 402 675 3
		tap_screen 244 832 3
		tap_screen 396 820 3	
	elif [ $device_name == "SM-J337A" ]
	then 
		tap_screen 344 1206 3 
		tap_screen 625 1198 3 
	fi 
}

# brave setup
brave_setup(){
	vrs=`adb -s $device_id shell dumpsys package "com.brave.browser" | grep "versionName" | cut -f 2 -d "=" | cut -f 1,2 -d "." | sed s/"\."//`
	if [ $device_name == "Nokia1" ] 
	then
		tap_screen 386 742 3
		tap_screen 386 742 3
		tap_screen 386 742 3
		tap_screen 407 643 3
		tap_screen 379 741 5
		tap_screen 246 561 3
	elif [ $device_name == "LM-X210" ] 
	then 
		tap_screen 595 1144 3
		tap_screen 595 1144 3
		tap_screen 595 1144 3
		tap_screen 624 1011 3
		tap_screen 605 1148 5
		tap_screen 361 962 3
	elif [ $device_name == "J7DUO" ] 
	then
		tap_screen 612 1234 3
		tap_screen 612 1234 3
		tap_screen 612 1234 3
		tap_screen 633 1110 3
		tap_screen 608 1235 5
		tap_screen 380 1072 3
		tap_screen 605 714 3
	elif [ $device_name == "E5PLAY" ]
	then
		tap_screen 408 846 3
		tap_screen 408 846 3
		tap_screen 408 846 5
		tap_screen 240 702 5 
		tap_screen 411 516 3
	elif [ $device_name == "SM-J337A" ]
	then 
		tap_screen  639 1232 3
		tap_screen  639 1232 3
		if [ $vrs -lt 15 ]
		then 
			echo "Detected older version ($vrs), changing automation"
			tap_screen  639 1232 3
			tap_screen  624 1090 3
		fi 
		tap_screen  639 1232 5
		tap_screen  369 1038 1 
	fi 
}

# setup Firefox
firefox_setup(){
	if [ $device_name == "LM-X210" ] 
	then 
		tap_screen 380 984 3
		tap_screen 380 984 3
		tap_screen 380 984 3
	elif [ $device_name == "E5PLAY" ]
	then
		tap_screen 253 724 3
		tap_screen 253 724 3
		tap_screen 253 724 3
		tap_screen 418 253 3
	elif [ $device_name == "SM-J337A" ]
	then 
		tap_screen 362 1072 3
		tap_screen 362 1072 3
		tap_screen 362 1072 3
	fi 
}

# setup Firefox focus (old version)
firefox_focus_setup(){
	for ((i=0; i<4; i++))
	do 
		#w=1080 h=2220
		x=`echo $width | awk '{print $1-(50/100)*$1}'`
		y=`echo $height | awk '{print $1-(22/100)*$1}'`
		myprint "[INFO] Clicking next... ($x, $y)"
		adb -s $device_id shell "input tap $x $y"
		#adb -s $device_id shell "input tap 540 1460"
		sleep 1
	done
}	

# setup Edge  (old version)
edge_setup(){
	x=`echo $width | awk '{print (90/100)*$1}'`
	y=`echo $height | awk '{print (8/100)*$1}'`
	myprint "[INFO] Skipping Microsoft sign-in ($x, $y)"
	adb -s $device_id shell "input tap $x $y"
	sleep 1
	x=`echo $width | awk '{print (28/100)*$1}'`
	# NOTE: 78% on S9? 
	y=`echo $height | awk '{print (86/100)*$1}'`
	myprint "[INFO] Skipping syncing browsing history across devices ($x, $y)"
	adb -s $device_id shell "input tap $x $y"
	sleep 1
	x=`echo $width | awk '{print (44/100)*$1}'`
	y=`echo $height | awk '{print (85/100)*$1}'` ## NOTE: 80% on S9? 
	myprint "[INFO] Not make edge default browser ($x, $y)"
	adb -s $device_id shell "input tap $x $y"
	sleep 1
}

# setup Kiwi (old version)
kiwi_setup(){
	if [ $app_option == "night" ] 
	then 
		#w=1080 h=2220
		myprint "[INFO] Activating Night mode"
		x=`echo $width | awk '{print $1-(6.3/100)*$1}'`
		y=`echo $height | awk '{print $1-(94/100)*$1}'`
		myprint "[INFO] Clicking ... ($x, $y)"
		adb -s $device_id shell "input tap $x $y"
		#adb -s $device_id shell "input tap 1012 133"
		myprint "[INFO] Scrolling down..."
		sleep 1 
		adb -s $device_id shell input swipe 500 1000 300 300
		sleep 1 
		x=`echo $width | awk '{print $1-(51/100)*$1}'`
		y=`echo $height | awk '{print (58/100)*$1}'` #NOTE: 50.4 <- turns of ads (1101)
		myprint "[INFO] Clicking night mode ($x, $y)"
		adb -s $device_id shell "input tap $x $y" 
		sleep 1
	else
		myprint "[INFO] Nothing to be done for $app" 
	fi 
}

# setup Chrome (old versions)
chrome_setup(){
	# click accept and continue 
	let "x=width/2"
	y=`echo $height | awk '{print 95/100*$1}'`
	#y=`echo $height | awk '{print 87/100*$1}'`
	adb -s $device_id shell "input tap $x $y"
	myprint "[INFO] Clicking accept and continue... ($x, $y)"
	sleep 1

	# in some cases turn off lite-mode 
	echo "ACEEPT LITE MODE - 1) FIXME: hard-coded (tap 350 1217), 2) turning it off now"
	adb -s $device_id shell input tap 637 885
	adb -s $device_id shell input tap 350 1217
	sleep 1 

	let "x=width-100"
	y=`echo $height | awk '{print 95/100*$1}'`
	#y=`echo $height | awk '{print 87/100*$1}'`
	myprint "[INFO] Clicking continue ($x ; $y)"
	adb -s $device_id shell "input tap $x $y"
	sleep 1 

	# click OK got it 
	myprint "[INFO] Clicking OK got it..."
	adb -s $device_id shell "input tap $x $y"
	#adb -s $device_id shell "input tap 901 1970"
	sleep 1 
	
	# enable dark mode if requested 
	if [ $app_option == "dark" ] 
	then 
		dark_mode_setup
	fi 
}

# enable dark mode if requested (Chrome and Brave) 
dark_mode_setup(){
	if [ $app != "brave" -o $app != "chrome" ] 
	then 
		myprint "Currently only tested dark mode support for Brave and Chrome. Skipping"
		return -1 	
	fi 
	# navigate to chrome://flags
	x=`echo $width | awk '{print 0.5*$1}'`
	y=`echo $height | awk '{print 0.08*$1}'`
	adb -s $device_id shell input tap $x $y
	#adb -s $device_id shell input tap 360 100
	adb -s $device_id shell input text "chrome://flags"
	adb -s $device_id shell input keyevent 66
	sleep 2 

	# look for Dark mode
	adb -s $device_id shell input text "Dark"
	sleep 2 

	# enable dark mode 
	x=`echo $width | awk '{print 0.22*$1}'`
	y=`echo $height | awk '{print 0.56*$1}'`
	adb -s $device_id shell input tap $x $y
	#adb -s $device_id shell input tap 160 713
	x=`echo $width | awk '{print 0.5*$1}'`
	y=`echo $height | awk '{print 0.5*$1}'`
	adb -s $device_id shell input tap $x $y
	#adb -s $device_id shell input tap 360 640

	# click relaunch and wait 	
	x=`echo $width | awk '{print 0.82*$1}'`
	y=`echo $height | awk '{print 0.875*$1}'`
	adb -s $device_id shell input tap $x $y
	#adb -s $device_id shell input tap 590 1120 
	sleep 5 
}

