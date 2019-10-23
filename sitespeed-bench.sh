#!/usr/bin/env bash

BROWSER=$1
TEST=$2

case $BROWSER in
	Brave )
		LAUNCH=(--chrome.binaryPath /Applications/Brave\ Browser\ Beta.app/Contents/MacOS/Brave\ Browser\ Beta)
		# FLAGS="--chrome.chromedriverPath=$(pwd)/chromedriver"
		SPBROWSER="chrome"
		;;
	Firefox )
		LAUNCH=(--firefox.binaryPath /Applications/Firefox.app/Contents/MacOS/firefox)
		SPBROWSER="firefox"
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

IFS=$'\n' read -d '' -r -a PAGES < $TEST

for url in "${PAGES[@]}"
do
	browsertime -b $SPBROWSER "${LAUNCH[@]}" "${FLAGS[@]}" \
		-n 3 \
		--pageCompleteCheckInactivity \
		--connectivity.engine throttle \
		--connectivity.profile custom \
		--connectivity.alias broadband \
		--connectivity.downstreamKbps 30720 \
		--connectivity.upstreamKbps 31000 \
		--connectivity.latency 100 \
		--viewPort maximize \
		$url
done

