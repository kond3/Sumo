#!/bin/bash

# Author: kond3
# Date: 17/06/2024
# Last modified: 17/06/2024 15:55:22

# Description
# Script to convert json imported to json ready to be uploaded.

# Usage
# ./cse_match_list.sh <old_tenant_dirname>

dir=$(dir.sh)

tenant="$1"
tenant_name=$(head -n 1 "$dir"/creds/"$tenant".txt | awk '{print $3}')
resource_path="$dir"/import/"$tenant"/cse_match_list
upload_path="$dir"/upload/cse_match_list/"$tenant"

"$dir"/script/pair.sh "$tenant" "custom_match_list_column" "https://api.de.sumologic.com/api/sec/v1/custom-match-list-columns" "data"

i=1
for resource in $(ls "$resource_path");do
    n=$(printf "%.5d" $i)
    description=$(cat "$resource_path"/"$resource" | jq ".description" | sed 's/"//g')
    
    if [[ "$description" = "" ]];then
        description="Imported with API from tenant $tenant_name"
    fi

    cat "$resource_path"/"$resource" | jq "{fields: {name: .name,description: \"$description\",targetColumn: .targetColumn,defaultTtl: .defaultTtl,active: true}}" > "$upload_path"/cse_match_list_"$n".json
    
    while read -r line;do
        id=$(echo $line | awk '{print $1}')
        name=$(echo $line | awk '{print $3}')
        sed "s/\"targetColumn\": $id/\"targetColumn\": $name/" -i "$upload_path"/cse_match_list_"$n".json
    done < "$dir"/script/pair/couple_old.txt
    
    i=$(( $i + 1 ))
done

exit 0
