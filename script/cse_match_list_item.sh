#!/bin/bash

# Author: kond3
# Date: 17/06/2024
# Last modified: 17/06/2024 17:50:19

# Description
# Script to convert json imported to json ready to be uploaded.

# Usage
# ./cse_match_list_item.sh <old tenant dirname>

dir=$(dir.sh)

tenant="$1"
tenant_name=$(head -n 1 "$dir"/creds/"$tenant".txt | awk '{print $3}')
resource_path="$dir"/import/"$tenant"/cse_match_list_item
all_path="$dir"/import/"$tenant"/all/cse_match_list_item.json

mkdir -p "$dir"/script/cse_match_list_item/upload/"$tenant"
rm -rf "$dir"/upload/cse_match_list_item
upload_path="$dir"/script/cse_match_list_item/upload/"$tenant"

"$dir"/script/pair.sh "$tenant" "cse_match_list" "https://api.de.sumologic.com/api/sec/v1/match-lists" "data | .objects" &>/dev/null

cat "$all_path" | jq ".data | {names: [.objects[] | .listName] | unique}" > "$dir"/script/cse_match_list_item/names.json

while read -r name <&10;do

    id=$(cat "$dir"/script/pair/couple_new.txt | grep "\"$name\"" | awk '{print $1}' | sed 's/"//g')
    mkdir "$upload_path"/$id
    cat "$all_path" | jq ".data | .objects | map (select(.listName == \"$name\"))" | jq "{items: [{value: .[] | .value, active: .[] | .active,description: \"Imported with API from $tenant_name\"}] | unique}" > "$upload_path"/$id/items.json

done 10< <(cat "$dir"/script/cse_match_list_item/names.json | jq ".names[]" | sed 's/"//g')

exit 0