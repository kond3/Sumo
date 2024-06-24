#!/bin/bash

# Author: kond3
# Date: 13/06/2024
# Last modified: 13/06/2024 15:20:55

# Description
# Script to convert json imported to json ready to be uploaded.

# Usage
# ./cse_log_mapping.sh <old_tenant_dirname>

dir=$(dir.sh)

tenant="$1"
resource_path="$dir"/import/"$tenant"/cse_log_mapping
upload_path="$dir"/upload/cse_log_mapping/"$tenant"

i=1
for resource in $(ls "$resource_path");do
    n=$(printf "%.5d" $i)

    cat "$resource_path"/"$resource" | jq "{fields: {name: .name,skippedValues: .skippedValues,fields: .fields,enabled: .enabled,relatesEntities: .relatesEntities,unstructuredFields: .unstructuredFields,structuredFields: .structuredFields,structuredInputs: .structuredInputs,recordType: .recordType,productGuid: .productGuid}}" > "$upload_path"/cse_log_mapping_"$n".json

    i=$(( $i + 1 ))
done

exit 0