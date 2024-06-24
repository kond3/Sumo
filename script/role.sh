#!/bin/bash

# Author: kond3
# Date: 03/06/2024
# Last modified: 03/06/2024 21:56:05

# Description
# Script to convert json imported to json ready to be uploaded.

# Usage
# ./script/role.sh <old_tenant_dirname>

dir=$(dir.sh)

tenant="$1"
resource_path="$dir"/import/"$tenant"/role
upload_path="$dir"/upload/role/"$tenant"

i=1
for resource in $(ls "$resource_path");do
    n=$(printf "%.5d" $i)
    description=$(cat "$resource_path"/"$resource" | jq ".description")

	if [[ "$description" = "null" ]];then
        cat "$resource_path"/"$resource" | jq "{name: .name,description: \"Imported with API\",filterPredicate: .filterPredicate,capabilities: .capabilities}" > "$upload_path"/role_"$n".json
    else
        cat "$resource_path"/"$resource" | jq "{name: .name,description: .description,filterPredicate: .filterPredicate,capabilities: .capabilities}" > "$upload_path"/role_"$n".json
    fi
    i=$(( $i + 1 ))
done

exit 0