#!/bin/bash

# Author: kond3
# Date: 14/06/2024
# Last modified: 14/06/2024 14:22:13

# Description
# Script to convert json imported to json ready to be uploaded.

# Usage
# ./cse_custom_entity_type.sh <old_tenant_dirname>

dir=$(dir.sh)

tenant="$1"
resource_path="$dir"/import/"$tenant"/cse_custom_entity_type
upload_path="$dir"/upload/cse_custom_entity_type/"$tenant"

i=1
for resource in $(ls "$resource_path");do
    n=$(printf "%.5d" $i)

    cat "$resource_path"/"$resource" | jq "{fields: {name: .name,fields: .fields,identifier: .identifier}}" > "$upload_path"/cse_custom_entity_type_"$n".json

    i=$(( $i + 1 ))
done

exit 0