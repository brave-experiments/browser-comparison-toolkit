#!/usr/bin/env bash

BROWSER=$1
TEST=$2

case $BROWSER in
	Brave )
		LAUNCH=(--chrome.binaryPath /Applications/Brave\ Browser\ Beta.app/Contents/MacOS/Brave\ Browser\ Beta)
		FLAGS="--chrome.chromedriverPath=$(pwd)/chromedriver"
		SPBROWSER="chrome"
		;;
	Firefox )
		LAUNCH=(--firefox.binaryPath /Applications/Firefox.app/Contents/MacOS/firefox)
		SPBROWSER="firefox"
		;;
	Safari )
		SPBROWSER="safari"
		;;
	Chrome )
		LAUNCH=(--chrome.binaryPath /Applications/Google\ Chrome\ 3.app/Contents/MacOS/Google\ Chrome)
		FLAGS="--chrome.chromedriverPath=$(pwd)/chromedriver"
		SPBROWSER="chrome"
		;;
	ChromeUBO )
		LAUNCH=(--chrome.binaryPath /Applications/Google\ Chrome\ 3.app/Contents/MacOS/Google\ Chrome)
		FLAGS=(--chrome.chromedriverPath=$(pwd)/chromedriver --chrome.args load-extension=$(pwd)/uBO)
		SPBROWSER="chrome"
		;;
esac

sitespeed.io -b $SPBROWSER "${LAUNCH[@]}" "${FLAGS[@]}" \
	--name ${BROWSER}-${TEST} \
	--logToFile \
	--outputFolder sitespeed-result/${BROWSER}-${TEST} \
	./scenarios/${TEST}.txt
