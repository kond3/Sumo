#!/bin/bash

# Author: kond3
# Date: 08/06/2024
# Last modified: 08/06/2024 08:17:47

# Description
# Script to import sources, for them API url requires correspondig collector ID.

# Usage
# ./script/import_source.sh <old tenant dirname>

dir=$(dir.sh)

tenant="$1"
access_id=$(head -n 2 "$dir"/creds/"$tenant".txt | tail -n 1 | awk '{print $3}')
key=$(head -n 3 "$dir"/creds/"$tenant".txt | tail -n 1 | awk '{print $3}')

mkdir "$dir"/import/"$tenant"/source
mkdir "$dir"/script/tmp/all
mkdir -p "$dir"/script/source/import/$tenant

api_calls=0

cat "$dir"/import/"$tenant"/all/collector.json | jq ".collectors[] | .id" > "$dir"/script/tmp/old_collector_id.txt

i=1
while read -r collector_id in <&8;do
    n=$(printf "%.5d" $i)

    if [ $(($api_calls % 4)) -eq 0 ];then
      wait
      sleep 0.5
    fi

    curl -s -u "$access_id:$key" -X GET https://api.de.sumologic.com/api/v1/collectors/"$collector_id"/sources > "$dir"/script/tmp/all/all_source_"$collector_id".json
    api_calls=$(($api_calls + 1))
    
    i=$(( $i + 1 ))
done 8< "$dir"/script/tmp/old_collector_id.txt

for s in $(ls "$dir"/script/tmp/all);do
    id=$(echo "$s" | sed 's/all_source_//' | sed 's/.json//')

    collector_file=$(grep "$id" "$dir"/import/"$tenant"/collector/* | head -n 1 | awk '{print $1}' | sed 's/://')
    collector_type=$(cat "$collector_file" | jq ".collectorType" | sed 's/"//g')

    if [[ "$collector_type" != "Hosted" ]];then
        continue
    fi

    mkdir "$dir"/script/source/import/$tenant/$id          # This directory will be used (and then deleted) in upload_source.sh

    total=$(cat "$dir"/script/tmp/all/"$s" | jq ".[] | length" | head -n 1)
    j=0
    while [ $j -lt $total ]; do
        m=$(( $j + 1 ))
        n=$(printf "%.5d" $m)

        cat "$dir"/script/tmp/all/"$s" | jq ".sources[$j]" > "$dir"/script/source/import/$tenant/$id/source_"$n".json

        j=$(( $j + 1 ))
    done
done

rm -rf "$dir"/script/tmp/*

exit 0
