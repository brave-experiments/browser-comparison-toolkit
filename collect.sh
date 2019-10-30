dir=$1
scenario=$2
output=$3

(echo "["
for BROWSER in Chrome Brave Firefox Opera
do
    for file in $dir/$BROWSER/$scenario/*/browsertime.json
    do
        har=$(dirname "$file")/$(basename "$file" .json).har
        browsertime=$file
        if [[ -f "$browsertime" ]] && [[ -f "$har" ]]; then
            #statements
            (
                jq " .[] | {
                    browser: \"$BROWSER\",
                    url: .info .url,
                    timestamp: .info .timestamp,
                    rumSpeedIndex: .statistics .timings .rumSpeedIndex | {median: .median, mean: .mean, stddev: .stddev},
                    firstPaint: .statistics .timings .firstPaint | {median: .median, mean: .mean, stddev: .stddev},
                    loadEvent: .statistics .timings .loadEventEnd | {median: .median, mean: .mean, stddev: .stddev},
                    fullyLoaded: .statistics .timings .fullyLoaded | {median: .median, mean: .mean, stddev: .stddev}
                }" $browsertime;
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
                  }" $har
            ) | jq -n '[inputs] | add'
            echo ","
        fi

    done
done
echo "]") | json2csv --flatten > $output
