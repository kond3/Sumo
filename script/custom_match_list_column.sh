#!/bin/bash

# Author: kond3
# Date: 17/06/2024
# Last modified: 17/06/2024 15:29:49

# Description
# Script to convert json imported to json ready to be uploaded.

# Usage
# ./custom_match_list_column.sh <old_tenant_dirname>

dir=$(dir.sh)

tenant="$1"
resource_path="$dir"/import/"$tenant"/custom_match_list_column
upload_path="$dir"/upload/custom_match_list_column/"$tenant"

i=1
for resource in $(ls "$resource_path");do
    n=$(printf "%.5d" $i)

    cat "$resource_path"/"$resource" | jq "{fields: {name: .name,fields: .fields}}" > "$upload_path"/custom_match_list_column_"$n".json

    i=$(( $i + 1 ))
done

exit 0
