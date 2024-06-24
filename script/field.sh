#!/bin/bash

# Author: kond3
# Date: 04/06/2024
# Last modified: 04/06/2024 22:23:23

# Description
# Script to convert json imported to json ready to be uploaded.

# Usage
# ./field.sh <old_tenant_dirname>

dir=$(dir.sh)

tenant="$1"
resource_path="$dir"/import/"$tenant"/field
upload_path="$dir"/upload/field/"$tenant"

i=1
for resource in $(ls "$resource_path");do
    n=$(printf "%.5d" $i)

    cat "$resource_path"/"$resource" | jq "{fieldName: .fieldName}" > "$upload_path"/field_"$n".json

    i=$(( $i + 1 ))
done

exit 0
