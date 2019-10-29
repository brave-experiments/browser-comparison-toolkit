#!/usr/bin/env bash

dir=$1

browser="opera"

for file in $dir/*/*.json
do
    jq -c "select(has(\"requestedUrl\")) | {
        browser: \"$browser\",
        url: .requestedUrl,
        timestamp: .fetchTime,
        rumSpeedIndex: .audits .metrics .details .items[] .speedIndex,
        firstPaint: .audits .metrics .details .items[] .observedFirstPaint,
        loadEvent: .audits .metrics .details .items[] .observedLoad,
        fullyLoaded: ((.audits .\"network-requests\" .details .items | map(.startTime) | max) - (.audits .\"network-requests\" .details .items | map(.startTime) | min)) | round,
        size: .audits .\"network-requests\" .details .items | map(.transferSize) | add,
    }" $file;
done