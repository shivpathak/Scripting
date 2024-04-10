#!/bin/bash

# This script fetches logs when run from that time - 1mins delay for first run to last 24 hours from cloudflare and store it to log files hourly
# Then it merges all hourly log files to single file
# Then it convert single log file to json array from ndjson format
# Then it dedup the json based on ClientIP key
# Then it convert from json to csv and stores it in ip.csv

# Set Cloudflare API keys and Zone Id ID
export CLOUDFLARE_API_KEYS="some-token"
export CLOUDFLARE_ZONE_ID="some-zone-id"

# Function to fetch logs for a given time range and save to a JSON file
fetch_logs() {
    local startdate=$1
    local enddate=$2
    local suffix=$(date -d "${enddate}" -u +"%Y_%m_%d_%H_%M_%S")
    local output_file="/tmp/logs_${suffix}.json"

    curl -s "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/logs/received?start=${startdate}Z&end=${enddate}Z&fields=ClientIP,ClientRequestHost" \
         -H "Content-Type: application/json" \
         -H "Authorization: Bearer ${CLOUDFLARE_API_KEYS}" \
         > "${output_file}"

    echo "${output_file}"
}

# Main loop to fetch logs at hourly intervals for the last 24 hours
success_files=()
enddate="$(date -u -d "1 minutes ago" +"%Y-%m-%dT%H:%M:%S")"

for (( i = 0; i < 24; i++ )); do
    # First cloudflare expects 1m0s delay in log delivery so on first run enddate should be current time - 1 minute and onwards 1 hour ago
    if [ $i -eq 0 ]; then
        enddate="$(date -u -d "1 minutes ago" +"%Y-%m-%dT%H:%M:%S")"
    else
        enddate="$(date -u -d "${i} hours ago" +"%Y-%m-%dT%H:%M:%S")"
    fi

    startdate="$(date -u -d "$((i + 1)) hours ago" +"%Y-%m-%dT%H:%M:%S")"
    
    log_file=$(fetch_logs "${startdate}" "${enddate}")

    if [ -s "${log_file}" ]; then
        date
        echo "Fetching logs for ${startdate} ==> ${enddate}"
        echo "Logs fetched successfully: ${log_file}"
        success_files+=("${log_file}")
    else
        echo "Error: Failed to fetch logs for ${startdate} ==> ${enddate}"
        # exit 1
    fi
done

# Combine hourly log files into a single JSON array file
all_logs_json="/tmp/all_logs.json"
for files in "${success_files[@]}"; do
  echo "Merging ${files} to ${all_logs_json} file"
  cat "${files}" >> "${all_logs_json}"
done

# Convert ndjson to array json file
all_logs_json_array="/tmp/all_logs_in_array.json"
jq -s '.' "${all_logs_json}" > "${all_logs_json_array}"

# Deduplicate logs based on ClientIP field and save to a JSON file
logs_deduplicated="/tmp/logs_deduplicated.json"
jq -c --arg key ClientIP 'group_by(.[$key]) | map(.[0])' ${all_logs_json_array} > ${logs_deduplicated}

# Convert deduplicated JSON logs to CSV format
csv_output="/tmp/ip.csv"
cat ${logs_deduplicated} | jq -r '(map(keys) | add | unique) as $keys | map(. as $row | $keys | map($row[.])) as $rows | $keys, $rows[] | @csv' > "${csv_output}"

echo "Logs have been processed and saved to ${csv_output}"
