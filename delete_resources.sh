#!/bin/bash

# Author: kond3
# Date: 05/06/2024
# Last modified: 05/06/2024 10:37:23

# Description
# Script to delete resources during test process. Access_id and key for the test tenant are hardcoded here.

# Usage
# ./delete_resources.sh <resource_name>

dir=$(dir.sh)
mkdir "$dir"/delete 2>/dev/null

if [[ "$1" = "" ]];then
    echo -e "\nUsage: \t delete_resources.sh <resource_name_1> [resource_name_2] ... [resource_name_n]\n"
    exit 0
fi

access_id= # Insert Access ID here
key= # Insert Access key here
api_calls=0

resources=("$@")

for r in "${resources[@]}";do
    resource_name="$r"
    get_url=$(cat "$dir"/api/import.txt | grep "^$resource_name\s:"| awk '{print $3 $4}')
    del_url=$(cat "$dir"/api/import.txt | grep "^$resource_name\s:"| awk '{print $3}')

    echo -e "\nDeleting $resource_name ... \n"

    wait
    curl -u "$access_id:$key" -X GET "$get_url" | jq > "$dir"/delete/delete.txt
    api_calls=$(($api_calls + 1))
    array_name=$(cat "$dir"/delete/delete.txt | jq | head -n 2 | tail -n 1 | sed 's/[^a-zA-Z]//g')

    if [[ "$resource_name" = "field" ]];then
        for id in $(jq ".$array_name[] | .fieldId" "$dir"/delete/delete.txt | sed 's/"//g');do
            if [ $(($api_calls % 4)) -eq 0 ];then
                wait
                sleep 0.5
            fi
            curl -s -u "$access_id:$key" -X DELETE "$del_url"/"$id"
            api_calls=$(($api_calls + 1))
        done
    elif [[ "$resource_name" =~ cse_.* ]];then
        for id in $(jq ".data | .objects[] | .id" "$dir"/delete/delete.txt | sed 's/"//g');do
            if [ $(($api_calls % 4)) -eq 0 ];then
                wait
                sleep 0.5
            fi
            curl -s -u "$access_id:$key" -X DELETE "$del_url"/"$id" 1>/dev/null &
            api_calls=$(($api_calls + 1))
        done
    else
        for id in $(jq ".$array_name[] | .id" "$dir"/delete/delete.txt | sed 's/"//g');do
            if [ $(($api_calls % 4)) -eq 0 ];then
                wait
                sleep 0.5
            fi
            curl -s -u "$access_id:$key" -X DELETE "$del_url"/"$id"
            api_calls=$(($api_calls + 1))
        done
    fi
    echo ""
done

wait
rm -rf "$dir"/delete

exit 0


