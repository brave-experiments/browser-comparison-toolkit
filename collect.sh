dir=$1
browser=$2
scenario=$3

(echo "["
for file in $dir/$browser/$scenario/*/browsertime.json
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
                      (.[0].pageref): [
                            (map(.response | ([.headersSize, .bodySize] | add)) | add),
                            (map(.request | ([.headersSize, .bodySize] | add)) | add)
                        ] | add
                  })
                | add
          }" $(dirname "$file")/$(basename "$file" .json).har
    ) | jq -n '[inputs] | add'
    echo ","

done
echo "]") > $browser-$scenario.json


