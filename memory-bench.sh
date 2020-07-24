#!/usr/bin/env bash

BROWSER=$1
TESTSET=$2
DURATION=20
REPEATS=3

case $BROWSER in
	Brave )
		PROCESS_NAMES="Brave Browser"
		EXECUTABLE="/Applications/Brave Browser Nightly.app"
		APPLICATION="Brave Browser"
		;;
	Firefox )
		PROCESS_NAMES="firefox|plugin-container"
		EXECUTABLE="/Applications/Firefox.app"
		APPLICATION="Firefox"
		;;
	Safari )
		PROCESS_NAMES="Safari|WebKit"
		EXECUTABLE="/Applications/Safari.app"
		APPLICATION="Safari"
		;;
	Chrome )
		PROCESS_NAMES="Google Chrome"
		EXECUTABLE="/Applications/Google Chrome.app"
		APPLICATION="Google Chrome"
		;;
	ChromeUBO )
		PROCESS_NAMES="Google Chrome"
		EXECUTABLE="/Applications/Google Chrome.app"
		FLAGS="--load-extension=$(pwd)/uBO"
		APPLICATION="Google Chrome"
		;;
	Opera )
		PROCESS_NAMES="Opera"
		EXECUTABLE="/Users/brave/Applications/Opera Beta.app"
		APPLICATION="Opera Beta"
		;;
	Edge )
		PROCESS_NAMES="Microsoft Edge"
		EXECUTABLE="/Applications/Microsoft Edge Beta.app"
		APPLICATION="Microsoft Edge"
		;;
esac

for TEST in ./scenarios/$TESTSET*.txt
do
	echo "$BROWSER Processing $TEST file..."

	IFS=$'\n' read -d '' -r -a PAGES < ${TEST}

	for (( i = 0; i < $REPEATS; i++ )); do
		
		open -a "$EXECUTABLE" --args ${FLAGS} #> /dev/null 2>&1 &
		sleep 3  # Wait a little bit for the app to start
		# IFS=' ' read -r -a openpages <<< "$TEST"
		for url in "${PAGES[@]}"
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
			ex = index("KMGTPEZY", substr($1, length($1), 1));
			val = substr($1, 0, length($1) - 1)
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

done
