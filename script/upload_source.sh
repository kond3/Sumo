#!/bin/bash

# Author: kond3
# Date: 08/06/2024
# Last modified: 08/06/2024 14:32:07

# Description
# Non-standard upload for sources

# Usage
# ./upload_source.sh

dir=$(dir.sh)

path_creds="$dir"/creds
path_log="$dir"/log
path_error="$dir"/error

resource_path="$dir"/script/source/upload/

access_id=$(head -n 2 "$path_creds"/new.txt | tail -n 1 | awk '{print $3}')
key=$(head -n 3 "$path_creds"/new.txt | tail -n 1 | awk '{print $3}')
base_url=$(cat "$dir"/api/upload.txt | grep "^source\s:"| awk '{print $3}')


function nl() {
  for i in {1..$1};do
   	echo ""
  done
}


function cow() {
  clear
  cowsay -f tux -W $1 "$2"
}


function next() {
  cow 24 "$1! Press enter to continue.."
  nl 2
  read -r -p "" answer
}


function basic_upload(){
#   echo "Basic upload function entered successfully"
#   echo ""
#   echo "Resource_path: $resource_path"
#   ls "$resource_path"
#   read -r -p "Press enter to continue.."
  
  echo -e -n "\n\n\nUploading all source at once ..."

  api_calls=0

  for tenant in $(ls "$resource_path");do

    # echo ""
    # echo "Tenant: $tenant"
    # read -r -p "Press enter to continue.."
    
    for collector_id in $(ls "$resource_path"/"$tenant");do
      collector_name=$(cat "$dir"/script/pair/couple_new.txt | grep "$collector_id" | awk '{print $3 $4 $5 $6 $7}' | sed 's/ /_/g' | sed 's/"//g')
      mkdir "$path_log"/upload/source/"$tenant"/collector_"$collector_name"
      mkdir "$path_error"/upload/source/"$tenant"/collector_"$collector_name"

      url=$(echo $base_url | sed "s/collector_ID/$collector_id/")

    #   echo ""
    #   echo "Collector_id: $collector_id"
    #   echo "Base_url: $base__url"
    #   echo "Url: $url"
    #   read -r -p "Press enter to continue.."

      for resource in $(ls "$resource_path"/"$tenant"/"$collector_id");do
        # echo ""
        # echo "Resource: $resource"
        # read -r -p "Press enter to continue.."

        if [ $(($api_calls % 4)) -eq 0 ];then
            wait
            sleep 0.5
        fi
        
        curl -s -u "$access_id:$key" -X POST -H "Content-Type: application/json" -T "$resource_path"/"$tenant"/"$collector_id"/"$resource" -o "$path_log"/upload/source/"$tenant"/collector_"$collector_name"/"$resource" "$url" &
        api_calls=$(($api_calls + 1))

      done
    done
  done
  wait
}


function medium_upload(){
#   echo "Medium upload function entered successfully"
#   echo ""
#   echo "Resource_path: $resource_path"
#   ls "$resource_path"
#   read -r -p "Press enter to continue.."

  for tenant in $(ls "$resource_path");do
    tenant_name=$(head -n 1 "$path_creds"/"$tenant".txt | awk '{print $3}')
    next "We are now uploading source resources from $tenant_name"
    nl 2

    # echo ""
    # echo "Tenant: $tenant"
    # echo "Tenant_name: $tenant_name"
    # read -r -p "Press enter to continue.."

    for collector_id in $(ls "$resource_path"/"$tenant");do
      collector_name=$(cat "$dir"/script/pair/couple_new.txt | grep "$collector_id" | awk '{print $3 $4 $5 $6 $7}' | sed 's/ /_/g' | sed 's/"//g')
      mkdir "$path_log"/upload/source/"$tenant"/collector_"$collector_name"
      mkdir "$path_error"/upload/source/"$tenant"/collector_"$collector_name"

      url=$(echo $base_url | sed "s/collector_ID/$collector_id/")

    #   echo ""
    #   echo "Collector_id: $collector_id"
    #   echo "Base_url: $base__url"
    #   echo "Url: $url"
    #   read -r -p "Press enter to continue.."
    #   echo ""
        next "We are now uploading source to collector $collector_name"
    #   read -r -p "Press enter to continue.."

      for resource in $(ls "$resource_path"/"$tenant"/"$collector_id");do
        total_lines=$(cat "$resource_path"/"$tenant"/"$collector_id"/"$resource" | wc -l)

        if [[ $total_lines -gt 14 ]];then
          cow 54 "The following is a preview of the source to be imported, since its lines are a lot! To see the full resource check out $resource_path/$tenant/$collector_id/$resource"
          nl 2
          head -n 14 "$resource_path"/"$tenant"/"$collector_id"/"$resource"
        else
          cow 24 "The source configuration you're about to upload is the following"
          nl 2
          cat "$resource_path"/"$tenant"/"$collector_id"/"$resource" | jq
        fi

        nl 5
        read -r -N 1 -p "Are you sure you want to upload the described source? (y/n) " confirm

        if [[ "$confirm" != "y" ]];then
          next "Upload aborted"
          continue
        else
          next "Upload confirmed"
        fi

        curl -s -u "$access_id:$key" -X POST -H "Content-Type: application/json" -T "$resource_path"/"$tenant"/"$collector_id"/"$resource" -o "$path_log"/upload/source/"$tenant"/collector_"$collector_name"/"$resource" "$url" &
      done
    done
  done
  wait
}


function advanced_upload(){
#   echo "Advanced upload function entered successfully"
#   echo ""
#   echo "Resource_path: $resource_path"
#   ls "$resource_path"
#   read -r -p "Press enter to continue.."

  for tenant in $(ls "$resource_path");do
    tenant_name=$(head -n 1 "$path_creds"/"$tenant".txt | awk '{print $3}')
    next "We are now uploading source resources from $tenant_name"
    nl 2

    # echo ""
    # echo "Tenant: $tenant"
    # echo "Tenant_name: $tenant_name"
    # read -r -p "Press enter to continue.."

    for collector_id in $(ls "$resource_path"/"$tenant");do
      collector_name=$(cat "$dir"/script/pair/couple_new.txt | grep "$collector_id" | awk '{print $3 $4 $5 $6 $7}' | sed 's/ /_/g' | sed 's/"//g')
      mkdir "$path_log"/upload/source/"$tenant"/collector_"$collector_name"
      mkdir "$path_error"/upload/source/"$tenant"/collector_"$collector_name"

      url=$(echo $base_url | sed "s/collector_ID/$collector_id/")

    #   echo ""
    #   echo "Collector_id: $collector_id"
    #   echo "Base_url: $base__url"
    #   echo "Url: $url"
    #   read -r -p "Press enter to continue.."
    #   echo ""
        next "We are now uploading source to collector $collector_name"
    #   read -r -p "Press enter to continue.."

      for resource in $(ls "$resource_path"/"$tenant"/"$collector_id");do
        total_lines=$(cat "$resource_path"/"$tenant"/"$collector_id"/"$resource" | wc -l)

        if [[ $total_lines -gt 14 ]];then
          cow 54 "The following is a preview of the source to be imported, since its lines are a lot! To see the full resource check out $resource_path/$tenant/$collector_id/$resource"
          nl 2
          head -n 14 "$resource_path"/"$tenant"/"$collector_id"/"$resource"
        else
          cow 24 "The source configuration your're about to upload is the following"
          nl 2
          cat "$resource_path"/"$tenant"/"$collector_id"/"$resource" | jq
        fi

        nl 5

        ok=0
        PS3="
What do you want to do with this source: "
  
        select action in "upload" "change and upload" "drop" "drop all remaining";do
          case "$action" in
            "upload")
              next "Upload confirmed"
              ;;
            "change and upload")
              nano "$resource_path"/"$tenant"/"$collector_id"/"$resource"
              nl 1
              read -r -N 1 -p "Confirm changes and upload? (y/n) " confirm
                if [[ "$confirm" != "y" ]];then
                  next "Upload aborted"
                  ok=1
                else
                  next "Upload confirmed"
                fi
              ;;
            "drop")
              next "Upload aborted"
              ok=1
              ;;
            "drop all remaining")
              next "All remaining uploads aborted"
              exit 0
              ;;
            *)
              ;;
          esac
          break
        done
  
        if [ $ok -eq 1 ];then
          continue
        fi        
        
        curl -s -u "$access_id:$key" -X POST -H "Content-Type: application/json" -T "$resource_path"/"$tenant"/"$collector_id"/"$resource" -o "$path_log"/upload/source/"$tenant"/collector_"$collector_name"/"$resource" "$url" &
      done
    done
  done
  wait
}


function mode_choice(){
  total=0
  for tenant in $(ls "$resource_path");do
    for collector_id in $(ls "$resource_path"/"$tenant");do
        partial=$(ls -1 "$resource_path"/"$tenant"/"$collector_id" | wc -l)
        total=$(( $total + $partial ))
        # echo "$partial"
        # echo "$total"
        # echo "$resource_path"
        # echo "$tenant"
        # echo "$collector_id"
        # echo ""
        # read -r -p "Press enter to continue.."
    done
  done

  if [ $total -eq 0 ];then
    echo "0 source found from previous tenant(s), skipping..."
    sleep 3
    return 4
  fi
  PS3="
Basic:    Upload all resources
Medium:   Check resources and eventually drop something
Advanced: Check resources and eventually change something

Total resource to add: $total

Select the mode for uploading source: "

select mode in "Basic" "Medium" "Advanced"; do
  case "$mode" in
    "Basic")
      return 1
      ;;
    "Medium")
      return 2
      ;;
    "Advanced")
      return 3
      ;;
    *)
      echo -e "\nInvalid number!\n"
      PS3="Select the mode for uploading source: "
      ;;
  esac
done
}


# End of function definition


mode_always=$(head -n 1 "$path_creds/mode_upload.txt")
if [ $mode_always -eq 1 ];then
  mode_choice
  mode_answer=$?
  nl 1
  
  if [ $mode_answer -ne 4 ];then
    read -r -N 1 -p "Do you want to use this mode for all future resources? (y/n) " mode_skip
    if [[ "$mode_skip" = "y" ]];then
      echo "0" > "$path_creds/mode_upload.txt"
      echo "$mode_answer" >> "$path_creds/mode_upload.txt"
    fi
  fi
else
  mode_answer=$(head -n 2 "$path_creds/mode_upload.txt" | tail -n 1)
fi

case "$mode_answer" in
  1)
    basic_upload
    ;;
  2)
    medium_upload
    ;;
  3)
    advanced_upload
    ;;
  4)
    rm -rf "$dir"/script/source/*
    exit 0
    ;;
  *)
    ;;
esac

rm -rf "$dir"/script/source/*

exit 0
