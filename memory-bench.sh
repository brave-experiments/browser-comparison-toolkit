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
		EXECUTABLE="/Applications/Opera.app/Contents/MacOS/Opera"
		APPLICATION="Opera"
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
	random20 )
		PAGES="https://www.theguardian.com https://www.sciencedirect.com/research-recommendations https://uk.reuters.com/video/2019/09/03/uk-pm-johnson-threatens-election-ahead-o?videoId=595311898&videoChannel=75 http://www.pbs.org/black-culture/ https://www.etsy.com/uk/c/wedding-and-party?ref=catnav-10983 https://www.tmz.com/2019/09/03/youtuber-brooke-houts-no-charges-animal-cruelty-dog-abusing-video/ https://boards.4chan.org/u/ https://edition.cnn.com/sport https://www.shutterstock.com/video https://www.asos.com/women/outlet/ctas/outlet-edits/outlet-edit-2/cat/?cid=28606&nlid=ww|outlet|ctas https://www.wowhead.com/zone=9616 https://kiwifarms.net/threads/archiving-the-lolcow-wiki.53747/post-5180264 https://www.earthcam.com/usa/michigan/brighton/ https://www.samsung.com/uk/explore/productivity/life/data-detox-how-to-amp-up-your-digital-security/ https://www.earthcam.com/company/privacy.php https://platekompaniet.no/ https://edition.cnn.com http://www.sky.com/shop/store-locator http://forum.kinozal.tv/showthread.php?goto=lastpost&t=304125 https://www.ebay.co.uk/"
		;;
	random10 )
		PAGES="https://www.wikihow.com/Special:CommunityDashboard https://www.xpres.co.uk/c-812-chromaluxe-aluminium-panels-xpres.aspx https://kiwifarms.net/members/loose-handle.39029/ https://www.mathletics.com/uk/for-schools/free-trial/ https://www.salon.com/2019/09/02/americas-slow-motion-coup-keeps-grinding-forward-but-is-donald-trump-really-the-one-to-blame/ https://www.salon.com/2019/09/01/planning-an-outdoor-barbecue-for-labor-day-follow-these-pro-tips-from-the-masters-of-the-craft/ https://www.marineinsight.com/category/videos/ https://sport.bt.com/more-sport-01363810551131 https://www.vice.com/en_uk/article/43kwpm/the-dm-that-changed-my-life-a-three-word-email-from-my-mum https://www.purevpn.com/dk/"
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
