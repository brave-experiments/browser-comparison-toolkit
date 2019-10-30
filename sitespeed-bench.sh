#!/usr/bin/env bash

# BROWSER=$1
TEST=$1

IFS=$'\n' read -d '' -r -a PAGES < $TEST


for i in "${!PAGES[@]}"
do
	url="${PAGES[$i]}"
	for BROWSER in Chrome Brave Firefox Opera
	do
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
				FLAGS="--chrome.chromedriverPath=$(pwd)/chromedrivers/chromedriver"
				SPBROWSER="chrome"
				;;
			Opera )
				LAUNCH=(--chrome.binaryPath /Users/brave/Applications/Opera\ Beta.app/Contents/MacOS/Opera)
				FLAGS="--chrome.chromedriverPath=$(pwd)/chromedrivers/operadriver"
				SPBROWSER="chrome"
				;;
			ChromeUBO )
				LAUNCH=(--chrome.binaryPath /Applications/Google\ Chrome\ 3.app/Contents/MacOS/Google\ Chrome)
				FLAGS=(--chrome.chromedriverPath=$(pwd)/chromedrivers/chromedriver --chrome.args load-extension=$(pwd)/uBO)
				SPBROWSER="chrome"
				;;
		esac

		browsertime -b $SPBROWSER "${LAUNCH[@]}" "${FLAGS[@]}" \
			-n 3 \
			--pageCompleteCheckInactivity \
			--resultDir browsertime/$BROWSER/4g/$i \
			--viewPort maximize \
			--connectivity.alias unthrottled \
			$url
						# --preURL $url \
	done
done

