#!/bin/bash

# Author: kond3
# Date: 14/06/2024
# Last modified: 14/06/2024 09:49:42

# Description
# Script to convert json imported to json ready to be uploaded.

# Usage
# ./cse_custom_insight.sh <old_tenant_dirname>

dir=$(dir.sh)

tenant="$1"
tenant_name=$(head -n 1 "$dir"/creds/"$tenant".txt | awk '{print $3}')
resource_path="$dir"/import/"$tenant"/cse_custom_insight
upload_path="$dir"/upload/cse_custom_insight/"$tenant"

"$dir"/script/pair.sh "$tenant" "cse_rule" "https://api.de.sumologic.com/api/sec/v1/rules?limit=500&q=ruleSource:\"user\"" "data | .objects"

i=1
for resource in $(ls "$resource_path");do
    n=$(printf "%.5d" $i)
    description=$(cat "$resource_path"/"$resource" | jq ".description" | sed 's/"//g')
    
    if [[ "$description" = "" ]];then
        description="Imported with API from tenant $tenant_name"
    fi

    cat "$resource_path"/"$resource" | jq "{fields: {name: .name,description: \"$description\",severity: .severity,ordered: .ordered,enabled: .enabled,tags: .tags,dynamicSeverity: .dynamicSeverity,ruleIds: .ruleIds,signalNames: .signalNames}}" > "$upload_path"/cse_custom_insight_"$n".json
    
    while read -r line;do
        new_id=$(echo $line | awk '{print $1}')
        old_id=$(echo $line | awk '{print $3}')
        sed "s/$old_id/$new_id/" -i "$upload_path"/cse_custom_insight_"$n".json
    done < "$dir"/script/pair/pair.txt
    
    i=$(( $i + 1 ))
done

# rm "$dir"/script/pair/*

exit 0
