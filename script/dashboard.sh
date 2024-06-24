#!/bin/bash

# Author: kond3
# Date: 04/06/2024
# Last modified: 04/06/2024 20:08:13

# Description
# Script to convert json imported to json ready to be uploaded.

# Usage
# ./dashboard.sh <old_tenant_dirname>

dir=$(dir.sh)

tenant="$1"
tenant_name=$(head -n 1 "$dir"/creds/"$tenant".txt | awk '{print $3}')
resource_path="$dir"/import/"$tenant"/dashboard
upload_path="$dir"/upload/dashboard/"$tenant"

access_id=$(head -n 2 "$dir"/creds/new.txt | tail -n 1 | awk '{print $3}')
key=$(head -n 3 "$dir"/creds/new.txt | tail -n 1 | awk '{print $3}')
url_personal=$(cat "$dir"/script/api.txt | grep "personal_folder :" | awk '{print $3}')
url_folder=$(cat "$dir"/script/api.txt | grep "^folder :" | awk '{print $3}')

# This is done to avoid excedeing the API rate limit
sleep 1

personal_folder_id=$(curl -u "$access_id:$key" -X GET $url_personal 2>/dev/null | jq ".id" | sed 's/"//g')
dashboard_folder_id=$(curl -u "$access_id:$key" -X POST -H "Content-Type: application/json" -d "{\"name\": \"API Dashboard from $tenant_name\",\"description\": \"Folder to group dashboards imported with API\",\"parentId\": \"$personal_folder_id\"}" $url_folder 2>/dev/null | jq ".id")

i=1
for resource in $(ls "$resource_path");do
    n=$(printf "%.5d" $i)
    description=$(cat "$resource_path"/"$resource" | jq ".description")

    if [[ "$description" = "null" ]];then
        cat "$resource_path"/"$resource" | jq "{title: .title,description: \"Imported with API\",folderId: $dashboard_folder_id,topologyLabelMap: .topologyLabelMap,domain: .domain,hierarchies: .hierarchies,refreshInterval: .refreshInterval,timeRange: .timeRange,panels: .panels,layout: .layout,variables: .variables,theme: .theme,isPublic: .isPublic,highlightViolations: .highlightViolations}" > "$upload_path"/dashboard_"$n".json
    else
        cat "$resource_path"/"$resource" | jq "{title: .title,description: .description,folderId: $dashboard_folder_id,topologyLabelMap: .topologyLabelMap,domain: .domain,hierarchies: .hierarchies,refreshInterval: .refreshInterval,timeRange: .timeRange,panels: .panels,layout: .layout,variables: .variables,theme: .theme,isPublic: .isPublic,highlightViolations: .highlightViolations}" > "$upload_path"/dashboard_"$n".json
    fi

    i=$(( $i + 1 ))
done

exit 0
