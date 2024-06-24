#!/bin/bash

# Author: kond3
# Date: 03/06/2024
# Last modified: 03/06/2024 23:32:41

# Description
# Script to convert json imported to json ready to be uploaded.

# Usage
# ./script/user.sh <old_tenant_dirname>

dir=$(dir.sh)

tenant="$1"
resource_path="$dir"/import/"$tenant"/user
upload_path="$dir"/upload/user/"$tenant"

"$dir"/script/pair.sh "$tenant" "role" "https://api.de.sumologic.com/api/v1/roles" "data"

i=1
for resource in $(ls "$resource_path");do
    n=$(printf "%.5d" $i)
    cat "$resource_path"/"$resource" | jq "{firstName: .firstName,lastName: .lastName,email: .email,roleIds: .roleIds}" > "$upload_path"/user_"$n".json

    cat "$upload_path"/user_"$n".json | jq ".roleIds[]" | sed 's/"//g' > "$dir"/script/pair/tmp.txt

    all_roles=0
    while read -r line;do
        if ! cat "$dir"/script/pair/pair.txt | grep "$line";then
            all_roles=1
            break
        fi
    done < "$dir"/script/pair/tmp.txt

    if [ $all_roles -eq 1 ];then
        continue
    fi
    
    while read -r line;do
        new_id=$(echo $line | awk '{print $1}')
        old_id=$(echo $line | awk '{print $3}')
        sed "s/$old_id/$new_id/" -i "$upload_path"/user_"$n".json
    done < "$dir"/script/pair/pair.txt
    
    i=$(( $i + 1 ))
done

# rm "$dir"/script/pair/*

exit 0