#!/bin/bash

# Author: kond3
# Date: 13/06/2024
# Last modified: 13/06/2024 17:03:49

# Description
# Script to convert json imported to json ready to be uploaded.

# Usage
# ./cse_threat_intel_source.sh <old_tenant_dirname>

dir=$(dir.sh)

tenant="$1"
tenant_name=$(head -n 1 "$dir"/creds/"$tenant".txt | awk '{print $3}')
resource_path="$dir"/import/"$tenant"/cse_threat_intel_source
upload_path="$dir"/upload/cse_threat_intel_source/"$tenant"

i=1
for resource in $(ls "$resource_path");do
    n=$(printf "%.5d" $i)

    description=$(cat "$resource_path"/"$resource" | jq ".description" | sed 's/"//g')

    if [[ "$description" = "null" ]];then
        description="Imported with API from tenant $tenant_name"
    fi

    cat "$resource_path"/"$resource" | jq "{fields: {name: .name,description: \"$description\"}}" > "$upload_path"/cse_threat_intel_source_"$n".json

    i=$(( $i + 1 ))
done

exit 0
