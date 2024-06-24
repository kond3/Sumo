#!/bin/bash

# Author: kond3
# Date: 03/06/2024
# Last modified: 03/06/2024 18:04:46

# Description
# Script to convert json imported to json ready to be uploaded.

# Usage
# ./collector.sh <old_tenant_dirname>

dir=$(dir.sh)

tenant="$1"
resource_path="$dir"/import/"$tenant"/collector
upload_path="$dir"/upload/collector/"$tenant"

i=1
for resource in $(ls "$resource_path");do
    n=$(printf "%.5d" $i)

    if cat "$resource_path"/"$resource" | grep '"collectorType": "Hosted"' &>/dev/null;then
        description=$(cat "$resource_path"/"$resource" | jq ".description")
        category=$(cat "$resource_path"/"$resource" | jq ".category")

        if [[ "$description" = "null" && "$category" = "null" ]];then
        cat "$resource_path"/"$resource" | jq "{collector:{collectorType: .collectorType,name: .name,timeZone: .timeZone,description: \"Imported with API\",category: \"Imported with API\",fields: .fields}}" > "$upload_path"/collector_"$n".json
        elif [[ "$description" = "null" ]];then
            cat "$resource_path"/"$resource" | jq "{collector:{collectorType: .collectorType,name: .name,timeZone: .timeZone,description: \"Imported with API\",category: .category,fields: .fields}}" > "$upload_path"/collector_"$n".json
        elif [[ "$category" = "null" ]];then
            cat "$resource_path"/"$resource" | jq "{collector:{collectorType: .collectorType,name: .name,timeZone: .timeZone,description: .description,category: \"Imported with API\",fields: .fields}}" > "$upload_path"/collector_"$n".json
        else
            cat "$resource_path"/"$resource" | jq "{collector:{collectorType: .collectorType,name: .name,timeZone: .timeZone,description: .description,category: .category,fields: .fields}}" > "$upload_path"/collector_"$n".json
        fi
        i=$(( $i + 1 ))
    fi
done

exit 0
