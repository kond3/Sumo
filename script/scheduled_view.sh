#!/bin/bash

# Author: kond3
# Date: 05/06/2024
# Last modified: 05/06/2024 00:04:08

# Description
# Script to convert json imported to json ready to be uploaded.

# Usage
# ./scheduled_view.sh <old_tenant_dirname>

dir=$(dir.sh)

tenant="$1"
resource_path="$dir"/import/"$tenant"/scheduled_view
upload_path="$dir"/upload/scheduled_view/"$tenant"

i=1
for resource in $(ls "$resource_path");do
    n=$(printf "%.5d" $i)

    cat "$resource_path"/"$resource" | jq "{query: .query,indexName: .indexName,startTime: .startTime,retentionPeriod: .retentionPeriod,parsingMode: .parsingMode}" > "$upload_path"/scheduled_view_"$n".json

    i=$(( $i + 1 ))
done

exit 0
