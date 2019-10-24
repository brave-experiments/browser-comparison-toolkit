browser=$1

echo "["
for file in ./browsertime-Friefox/*/*/browsertime.json
do

    (
        jq " .[] | {
            browser: \"$browser\",
            url: .info .url,
            timestamp: .info .timestamp,
            rumSpeedIndex: .statistics .timings .rumSpeedIndex | {median: .median, mean: .mean, stddev: .stddev},
            firstPaint: .statistics .timings .firstPaint | {median: .median, mean: .mean, stddev: .stddev},
            loadEvent: .statistics .timings .loadEventEnd | {median: .median, mean: .mean, stddev: .stddev},
            fullyLoaded: .statistics .timings .fullyLoaded | {median: .median, mean: .mean, stddev: .stddev}
        }" $file;
        jq ".log | {
            sizes: .entries 
                | group_by(.pageref) 
                | map({
                      (.[0].pageref): map(.response ._transferSize) | add
                  })
                | add
          }" $(dirname "$file")/$(basename "$file" .json).har
    ) | jq -n '[inputs] | add'
    echo ","

done
echo "]"
