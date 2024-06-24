#!/bin/bash

# Author: kond3
# Date: 14/06/2024
# Last modified: 14/06/2024 09:02:55

# Description
# Script to convert json imported to json ready to be uploaded.

# Usage
# ./cse_entity_criticality_config.sh <old_tenant_dirname>

dir=$(dir.sh)

tenant="$1"
resource_path="$dir"/import/"$tenant"/cse_entity_criticality_config
upload_path="$dir"/upload/cse_entity_criticality_config/"$tenant"

i=1
for resource in $(ls "$resource_path");do
    n=$(printf "%.5d" $i)

    cat "$resource_path"/"$resource" | jq "{fields: {name: .name,severityExpression: .severityExpression}}" > "$upload_path"/cse_entity_criticality_config_"$n".json

    i=$(( $i + 1 ))
done

exit 0