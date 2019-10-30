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
            sizes=$(jq -r ".log | .entries
                    | group_by(.pageref)
                    | map([ 
                            (map(.response | ([.headersSize, .bodySize] | add)) | add),
                            (map(.request | ([.headersSize, .bodySize] | add)) | add)
                        ] | add)
                    | .[]" $har);
            size_average=$(awk '{ sum=sum+$1 } END { avg=sum/NR; printf "%f", avg }' <<< "$sizes");
            size_stddev=$(awk '{sum+=$0;a[NR]=$0}END{for(i in a)y+=(a[i]-(sum/NR))^2;printf "%f", sqrt(y/(NR-1))}' <<< "$sizes");
            size_median=$(awk '{arr[NR]=$1} END {if (NR%2==1) print arr[(NR+1)/2]; else print (arr[NR/2]+arr[NR/2+1])/2}' <<< sort <<< "$sizes");

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
                
                jq -n --arg mean "$size_average" \
                    --arg stddev "$size_stddev" \
                    --arg median "$size_median" \
                    '{ size: {
                        median: $median | tonumber,
                        mean: $mean | tonumber,
                        stddev: $stddev | tonumber
                    }}'
            ) | jq -n '[inputs] | add'
            echo ","
        fi

    done
done
echo "]") | json2csv --flatten > $output
