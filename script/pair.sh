#!/bin/bash

# Author: kond3
# Date: 04/06/2024
# Last modified: 04/06/2024 11:44:32

# Description
# Script used to match IDs between new and old tenants resources.

# Usage
# ./pair.sh <old_tenant_dirname> <resource> <api_url> <array_name>

dir=$(dir.sh)

if ! [ -d "$dir"/script/pair ];then
    mkdir "$dir"/script/pair
fi

rm "$dir"/script/pair/* &>/dev/null

old_tenant="$1"
resource="$2"
api_url="$3"
array_name="$4"

access_id=$(head -n 2 "$dir"/creds/new.txt | tail -n 1 | awk '{print $3}')
key=$(head -n 3 "$dir"/creds/new.txt | tail -n 1 | awk '{print $3}')

# This is done to avoid excedeing the API rate limit
sleep 1

curl -s -u "$access_id:$key" -X GET "$api_url" | jq ".$array_name[] | {name: .name,id: .id}" > "$dir"/script/pair/new.txt
cat "$dir"/import/"$old_tenant"/all/"$resource".json | jq ".$array_name[] | {name: .name,id: .id}" > "$dir"/script/pair/old.txt

while read -r name;do
	echo -n $(cat "$dir"/script/pair/new.txt | grep -A 1 "$name" | tail -n 1 | awk '{print $2}') >> "$dir"/script/pair/couple_new.txt
	echo -n " : " >> "$dir"/script/pair/couple_new.txt
	echo "$name" >> "$dir"/script/pair/couple_new.txt
done < <(cat "$dir"/script/pair/new.txt | jq ".name")

while read -r name;do
	echo -n $(cat "$dir"/script/pair/old.txt | grep -A 1 "$name" | tail -n 1 | awk '{print $2}') >> "$dir"/script/pair/couple_old.txt
	echo -n " : " >> "$dir"/script/pair/couple_old.txt
	echo "$name" >> "$dir"/script/pair/couple_old.txt
done < <(cat "$dir"/script/pair/old.txt | jq ".name")

while read -r line;do
	name=$(echo $line | sed 's/.*: //')
	echo "$name"
	if cat "$dir"/script/pair/couple_old.txt | grep "$name" &>/dev/null;then
		new_id=$(echo "$line" | awk '{print $1}')
		old_id=$(cat "$dir"/script/pair/couple_old.txt | grep "$name" | awk '{print $1}')
		echo "$new_id : $old_id" | sed 's/"//g' >> "$dir"/script/pair/pair.txt
	fi
done < "$dir"/script/pair/couple_new.txt

# rm "$dir"/script/pair/couple* "$dir"/script/pair/new.txt  "$dir"/script/pair/old.txt
# rm "$dir"/script/pair/*

exit 0
