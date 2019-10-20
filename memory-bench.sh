#!/usr/bin/env bash

BROWSER=$1
TEST=$2
DURATION=20
REPEATS=3

case $BROWSER in
	Brave )
		PROCESS_NAMES="Brave Browser"
		EXECUTABLE="/Applications/Brave Browser Beta.app/Contents/MacOS/Brave Browser Beta"
		APPLICATION="Brave Browser"
		;;
	Firefox )
		PROCESS_NAMES="firefox|plugin-container"
		EXECUTABLE="/Applications/Firefox.app/Contents/MacOS/firefox"
		APPLICATION="Firefox"
		;;
	Safari )
		PROCESS_NAMES="Safari|WebKit"
		EXECUTABLE="/Applications/Safari.app/Contents/MacOS/Safari"
		APPLICATION="Safari"
		;;
	Chrome )
		PROCESS_NAMES="Google Chrome"
		EXECUTABLE="/Applications/Google Chrome 3.app/Contents/MacOS/Google Chrome"
		APPLICATION="Google Chrome 3"
		;;
	ChromeUBO )
		PROCESS_NAMES="Google Chrome"
		EXECUTABLE="/Applications/Google Chrome 3.app/Contents/MacOS/Google Chrome"
		FLAGS="--load-extension=./uBO"
		APPLICATION="Google Chrome 3"
		;;
	Opera )
		PROCESS_NAMES="Opera"
		EXECUTABLE="/Users/brave/Applications/Opera Beta.app/Contents/MacOS/Opera"
		APPLICATION="Opera Beta"
		;;
	Edge )
		PROCESS_NAMES="Microsoft Edge"
		EXECUTABLE="/Applications/Microsoft Edge Beta.app/Contents/MacOS/Microsoft Edge Beta"
		APPLICATION="Microsoft Edge"
		;;
esac

case $TEST in
	blank )
		PAGES=""
		;;
	cnet )
		PAGES="https://cnet.com"
		;;
	basic )
		PAGES="https://www.google.com/search?q=brave https://youtube.com https://cnet.com https://amazon.com https://outlook.live.com/owa/"
		;;
	news )
		PAGES="https://theblaze.com https://thedailybeast.com https://independent.co.uk https://nypost.com https://salon.com https://cnn.com https://sfgate.com https://latimes.com https://mirror.co.uk https://cnet.com"
		;;
esac

for (( i = 0; i < $REPEATS; i++ )); do
	
	"$EXECUTABLE" ${FLAGS} > /dev/null 2>&1 &
	sleep 3  # Wait a little bit for the app to start
	IFS=' ' read -r -a openpages <<< "$PAGES"
	for url in "${openpages[@]}"
	do
		command="tell application \"$APPLICATION\" to open location \"$url\""
	    osascript -e "$command"
	    sleep 5;	# Sleep for 5 seconds after each page opened
	done

# 	read -r -d '' cycle_tabs << EOM
# tell application "${APPLICATION}"
#     set i to 0
#     repeat with t in (tabs of (first window whose index is 1))
#         set i to i + 1
#         set (active tab index of (first window whose index is 1)) to i
#         delay 2
#     end repeat
# end tell
# EOM

	# osascript -e "$cycle_tabs"

	sleep $DURATION

	echo "Calculating memory use"
	top -l 1 -stats mem,command \
		| egrep "$PROCESS_NAMES" \
		| awk -v run=$i -v browser=$BROWSER '{
	    ex = index("KMGTPEZY", substr($1, length($1)-1, 1))
	    val = substr($1, 0, length($1) - 2)
	    prod = val * 1024^ex
	    sum += prod
	}
	END {print browser " run " run ": total memory " sum / 1024 / 1024 " MB"}';
	
	echo "Terminating"
	closewindow="tell application \"${APPLICATION}\" to close window 1"
	quit="quit app \"${APPLICATION}\""
	osascript -e "$closewindow"
	osascript -e "$quit"
	sleep 3
done
