#!/bin/bash

# Author: kond3
# Date: 13/06/2024
# Last modified: 13/06/2024 07:36:11

# Description
# Script to convert json imported to json ready to be uploaded.

# Usage
# ./cse_rule_tuning_expression.sh <old_tenant_dirname>


dir=$(dir.sh)

tenant="$1"
tenant_name=$(head -n 1 "$dir"/creds/"$tenant".txt | awk '{print $3}')
resource_path="$dir"/import/"$tenant"/cse_rule_tuning_expression
upload_path="$dir"/upload/cse_rule_tuning_expression/"$tenant"

"$dir"/script/pair.sh "$tenant" "cse_rule" "https://api.de.sumologic.com/api/sec/v1/rules?limit=500&q=ruleSource:\"user\"" "data | .objects"

i=1
for resource in $(ls "$resource_path");do
    n=$(printf "%.5d" $i)
    description=$(cat "$resource_path"/"$resource" | jq ".description" | sed 's/"//g')
    
    if [[ "$description" = "" ]];then
        description="Imported with API from tenant $tenant_name"
    fi

    cat "$resource_path"/"$resource" | jq "{fields: {name: .name,description: \"$description\",expression: .expression,enabled: .enabled, isGlobal: .isGlobal,exclude: .exclude,ruleIds: .ruleIds}}" > "$upload_path"/cse_rule_tuning_expression_"$n".json

    # cat "$upload_path"/cse_rule_tuning_expression_"$n".json | jq ".ruleIds[]" | sed 's/"//g' > "$dir"/script/pair/tmp.txt

    # all_rules=0
    # while read -r line;do
    #     if ! cat "$dir"/script/pair/pair.txt | awk '{print $1}' | grep "$line";then
    #         all_rules=1
    #         break
    #     fi
    # done < "$dir"/script/pair/tmp.txt

    # if [ $all_rules -eq 1 ];then
    #     continue
    # fi
    
    while read -r line;do
        new_id=$(echo $line | awk '{print $1}')
        old_id=$(echo $line | awk '{print $3}')
        sed "s/$old_id/$new_id/" -i "$upload_path"/cse_rule_tuning_expression_"$n".json
    done < "$dir"/script/pair/pair.txt
    
    i=$(( $i + 1 ))
done

# rm "$dir"/script/pair/*

exit 0