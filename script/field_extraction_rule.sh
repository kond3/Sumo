#!/bin/bash

# Author: kond3
# Date: 04/06/2024
# Last modified: 04/06/2024 23:02:16

# Description
# Script to convert json imported to json ready to be uploaded.

# Usage
# ./field_extractoin_rule.sh <old_tenant_dirname>

dir=$(dir.sh)

tenant="$1"
resource_path="$dir"/import/"$tenant"/field_extraction_rule
upload_path="$dir"/upload/field_extraction_rule/"$tenant"

i=1
for resource in $(ls "$resource_path");do
    n=$(printf "%.5d" $i)

    cat "$resource_path"/"$resource" | jq "{name: .name,scope: .scope,parseExpression: .parseExpression,enabled: .enabled}" > "$upload_path"/field_extraction_rule_"$n".json

    i=$(( $i + 1 ))
done

exit 0
