#!/bin/bash

# Author: kond3
# Date: 14/06/2024
# Last modified: 14/06/2024 14:10:11

# Description
# Script to convert json imported to json ready to be uploaded.

# Usage
# ./cse_context_action.sh <old_tenant_dirname>

dir=$(dir.sh)

tenant="$1"
resource_path="$dir"/import/"$tenant"/cse_context_action
upload_path="$dir"/upload/cse_context_action/"$tenant"

i=1
for resource in $(ls "$resource_path");do
    n=$(printf "%.5d" $i)

    cat "$resource_path"/"$resource" | jq "{name: .name,type: .type,template: .template,iocTypes: .iocTypes,entityTypes: .entityTypes,recordFields: .recordFields,allRecordFields: .allRecordFields}" > "$upload_path"/cse_context_action_"$n".json

    i=$(( $i + 1 ))
done

exit 0
