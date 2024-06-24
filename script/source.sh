#!/bin/bash

# Author: kond3
# Date: 08/06/2024
# Last modified: 08/06/2024 20:07:53

# Description
# Script to convert json imported to json ready to be uploaded.

# Usage
# ./source.sh <old tenant dirname>

dir=$(dir.sh)

tenant="$1"
resource_path="$dir"/script/source/import/"$tenant"

mkdir -p "$dir"/script/source/upload/"$tenant"
rm -rf "$dir"/upload/source/
upload_path="$dir"/script/source/upload/"$tenant"

# echo "$tenant"

"$dir"/script/pair.sh "$tenant" "collector" "https://api.de.sumologic.com/api/v1/collectors" "collectors"

for collector_old_id in $(ls "$resource_path");do

    collector_new_id=$(cat "$dir"/script/pair/pair.txt | grep "$collector_old_id" | awk '{print $1}')

    if [ -z "$collector_new_id" ];then
        continue
    fi

    mkdir "$upload_path"/"$collector_new_id"
    i=1
    for s in $(ls "$resource_path"/"$collector_old_id");do
        n=$(printf "%.5d" $i)
        name=$(cat "$resource_path"/"$collector_old_id"/"$s" | jq ".name" | sed 's/"//g')
        description=$(cat "$resource_path"/"$collector_old_id"/"$s" | jq ".description" | sed 's/"//g')
        category=$(cat "$resource_path"/"$collector_old_id"/"$s" | jq ".category" | sed 's/"//g')

        if [[ "$name" = "null" ]];then
            name=$(cat "$resource_path"/"$collector_old_id"/"$s" | jq ".config | .name" | sed 's/"//g')
        fi
        if [[ "$description" = "null" ]];then
            description="Imported with API"
        fi
        if [[ "$category" = "null" ]];then
            category="Imported with API"
        fi

        source_type=$(cat "$resource_path"/"$collector_old_id"/"$s" | jq ".sourceType" | sed 's/"//g')

        if [[ "$source_type" = "Polling" ]];then
            cat "$resource_path"/"$collector_old_id"/"$s" | jq "{source: {name: \"$name\",description: \"$description\",category: \"$category\",fields: .fields,sourceType: .sourceType,scanInterval: .scanInterval,paused: .paused,automaticDateParsing: .automaticDateParsing,multilineProcessingEnabled: .multilineProcessingEnabled,useAutolineMatching: .useAutolineMatching,forceTimeZone: .forceTimeZone,cutoffTimestamp: .cutoffTimestamp,filters: .filters,thirdPartyRef: .thirdPartyRef}}" > "$upload_path"/"$collector_new_id"/source_"$n".json

            i=$(( $i + 1 ))
            continue
        fi

        cat "$resource_path"/"$collector_old_id"/"$s" | jq "{source: {name: \"$name\",description: \"$description\",category: \"$category\",fields: .fields,sourceType: .sourceType,hostName: .hostName, automaticDateParsing: .automaticDateParsing, multilineProcessingEnabled: .multilineProcessingEnabled,useAutolineMatching: .useAutolineMatching,forceTimeZone: .forceTimeZone,cutoffTimestamp: .cutoffTimestamp,filters: .filters, hashAlgorithm: .hashAlgorithm}}" > "$upload_path"/"$collector_new_id"/source_"$n".json

    i=$(( $i + 1 ))
    done
done

exit 0