#!/bin/bash

# Author: kond3
# Date: 31/05/2024
# Last modified: 31/05/2024 16:11:35

# Description
# Script to configure a new Sumo Tenant importing resources from previous tentant(s). Files storing credentials is created at startup, and 
# deleted overwriting with zeros their bytes 50 times (military standard is 25) before terminating. This makes the script forensic-proof.
#
# NOTE 1
# For this script to work, its direcotry must be added to $PATH and dir.sh must be in the same directory.
#
# NOTE 2: 
# APIs link various based on where your Sumo infrastructure is located (EU, US, AU, ...), set them properly in api.txt, if you
# want to add new resources in there, be careful to use the same syntax:
# resource_name (without spaces!!)  :   api_link
# Where to put your new link is up to you, it is discouraged to change APIs' order if you don't deeply understand its import - export process

# Usage
# ./configuration.sh


# Directories
dir=$(dir.sh)

mkdir "$dir"/creds &>/dev/null
mkdir "$dir"/import &>/dev/null
mkdir "$dir"/upload &>/dev/null
mkdir "$dir"/log &>/dev/null
mkdir "$dir"/error &>/dev/null
mkdir "$dir"/backup &>/dev/null

path_creds="$dir"/creds
path_import="$dir"/import
path_log="$dir"/log
path_error="$dir"/error
path_upload="$dir"/upload
path_script="$dir"/script

# Global variable used to not exceed API rate limit
api_calls=0


# Start function definition


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

  local answer
	read -r -p "" answer
}


# This function perform an initilia clean up of directories remained from a previous program execution
function clean(){
  shred -n 50 -z -u "$dir"/creds/old* "$dir"/creds/new.txt &>/dev/null
  rm -rf "$dir"/import/* "$dir"/upload/* "$path_script"/pair/* "$path_script/resource_order.txt" "$path_script"/source/* &>/dev/null # "$dir"/test/*
  clear
}


# Adding "$dir" in front of .tar.gz filenames and target dirs was ending up in a backup of /home directory. Strange D:
function log_backup(){

  log_empty=$(ls "$path_log" | wc -l)
  error_empty=$(ls "$path_error" | wc -l)

  if [ $log_empty -eq 0 ] && [ $error_empty -eq 0 ];then
    return 0
  fi

  cow 24 "Time for an important decision!"
  nl 2

  local create_backup
  read -r -N 1 -p "Do you want to create a backup of previous log files? (y/n) " create_backup

  if [[ "$create_backup" = "y" ]];then
    log_date=$(date +%d.%m.%y_%H.%M.%S)
    tar -czvf backup/log_"$log_date".tar.gz log &>/dev/null
    tar -czvf backup/error_"$log_date".tar.gz error &>/dev/null
    nl 1
    echo -e "Backup successfully created:\nbackup/log_"$log_date".tar\nbackup/error_"$log_date".tar"
    nl 1
    local backup_done
    read -r -p "Press enter to continue.." backup_done
  fi
  rm -rf "$dir"/log/* "$dir"/error/* 2>/dev/null
}


# This function performs an initial check, eventually changing directory to the correct one
# And creating directories for log and error files.
function check(){
	if [[ $(pwd) != "$dir" ]];then
		cd "$dir"
	fi
	if ! [ -d "$dir"/log ];then
		mkdir "$dir"/log
	fi
	if ! [ -d "$dir"/error ];then
		mkdir "$dir"/error
	fi
  if ! [ -d "$dir"/creds ];then
		mkdir "$dir"/creds
	fi
}


# This function welcomes the user and initialize a file with credentials for the new tenant.
function welcome() {
	cow 34 "Welcome to Sumo tenant configuration script! Configuring a new Sumo tenant from scratch through its web interface can be a real pain, fortunately CLI and API can make your life much easier. Let's start with tenant name and credentials."

	nl 2

  local name
  local access_id
  local access_key

	read -r -p "Insert the tenant name: " name
	read -r -p "Insert your access id: " access_id
	read -r -p "Insert your access key: " access_key

  touch "$dir"/creds/new.txt
  echo "name : $name" > "$dir"/creds/new.txt
  echo "access_id : $access_id" >> "$dir"/creds/new.txt
  echo "access_key : $access_key" >> "$dir"/creds/new.txt
}


# This function configure files for previous tenant(s) and for each tenant a directory in "$dir"/import
function old_tenant(){
	cow 24 "At least one previous tenant is required for replicating its rersouces to the new one!"
	nl 2

  local j=1  
  local again=0
    
  while [ $again -eq 0 ];do
    n=$(printf "%.3d" $j)

    local name
    local access_id
    local access_key

    read -r -p "Insert the tenant name: " name
	  read -r -p "Insert your access id for the $name tenant: " access_id
	  read -r -p "Insert your access key for the $name tenant: " access_key

    touch "$dir"/creds/old_"$n".txt
    echo "name : $name" > "$dir"/creds/old_"$n".txt
    echo "access_id : $access_id" >> "$dir"/creds/old_"$n".txt
    echo "access_key : $access_key" >> "$dir"/creds/old_"$n".txt

    cow 24 "Tenant $name credentials addedd successfully!"
    nl 2

    local answer
    read -r -N 1 -p "Do you want to add another previous tenant? (y/n) " answer
    nl 1

    if [[ "$answer" = "y" ]];then
      again=0
      j=$(( $j + 1 ))

      cow 24 "Excellent! Let's add the previous tenant number $j"
      nl 2
    else
      again=1
    fi
  done
}


# Takes two argumens:
# $1 - tenant dirname
# $2 - resource name
#
# This function checks if special resources' dependencies are satisfied in the resources choosing process.
function import_dependencies(){
  local tenant="$1"
  local resource="$2"

  case "$resource" in
    "user")
      cat "$path_import"/"$tenant"/resources.txt | grep "^role\s:" &>/dev/null
      local role_exists=$?
      if [ $role_exists -eq 1 ];then
        echo -e "User need roles' IDs to be associated to, import role first!"
        return 1
      fi
      ;;
    "source")
      cat "$path_import"/"$tenant"/resources.txt | grep "^collector\s:" &>/dev/null
      local collector_exists=$?
      if [ $collector_exists -eq 1 ];then
        echo -e "Sources need collectors' IDs to be associated to, import collectors first!"
        return 1
      fi
      ;;
    "cse_rule_tuning_expression")
      cat "$path_import"/"$tenant"/resources.txt | grep "^cse_rule\s:" &>/dev/null
      local rule_exists=$?
      if [ $rule_exists -eq 1 ];then
        echo -e "Tuning expressions need cse_rules' IDs to be associated to, import cse_rules first!"
        return 1
      fi
      ;;
    "cse_custom_insight")
      cat "$path_import"/"$tenant"/resources.txt | grep "^cse_rule\s:" &>/dev/null
      local rule_exists=$?
      if [ $rule_exists -eq 1 ];then
        echo -e "Custom Insights need cse_rules' IDs to be associated to, import cse_rules first!"
        return 1
      fi
      ;;
    "cse_match_list")
      cat "$path_import"/"$tenant"/resources.txt | grep "^custom_match_list_column\s:" &>/dev/null
      local rule_exists=$?
      if [ $rule_exists -eq 1 ];then
        echo -e "Match list need custom match list columns' IDs to be associated to, import custom match list columns first!"
        return 1
      fi
      ;;
    "cse_match_list_item")
      cat "$path_import"/"$tenant"/resources.txt | grep "^cse_match_list\s:" &>/dev/null
      local rule_exists=$?
      if [ $rule_exists -eq 1 ];then
        echo -e "Match list items need match lists' IDs to be associated to, import match lists first!"
        return 1
      fi
      ;;
    *)
      ;;
  esac
  return 0
}


# Takes one argument:
# $1 - resource name
#
# This function creates the file "$path_script"/resource_order.txt, that will be used by the upload function to uplaod resources in the right order, rather then
# looping through "$path_upload", that will result in an alphabetic order. A space, a colon and the string "resource added" where added to the file in order to
# avoid errors when matchin field (that would also match field_extraction_rule), rule (that would also match field_extraction_rule and rule_tuning_expression), ...
# This is not a problem when looping throug the file with the upload function, since awk '{print $1}' will easyly get only the resource name.
function resource_order() {
  if ! [ -f "$path_script"/resource_order.txt ];then
    touch "$path_script"/resource_order.txt
  fi

  if [[ "$1" = "all" ]];then
    cat "$dir"/api/upload.txt | awk '{print $1, ":", "resource added"}' > "$path_script"/resource_order.txt
    return 0
  fi

  if [[ "$1" = "cse_rule" ]];then
    cat "$path_script"/resource_order.txt | grep "cse_match_rule : resource added" &>/dev/null
    local match_already=$?
    if [ $match_already -eq 1 ];then
      echo "cse_match_rule : resource added" >> "$path_script"/resource_order.txt
    fi

    cat "$path_script"/resource_order.txt | grep "cse_threshold_rule : resource added" &>/dev/null
    local threshold_already=$?
    if [ $threshold_already -eq 1 ];then
      echo "cse_threshold_rule : resource added" >> "$path_script"/resource_order.txt
    fi

    cat "$path_script"/resource_order.txt | grep "cse_chain_rule : resource added" &>/dev/null
    local chain_already=$?
    if [ $chain_already -eq 1 ];then
      echo "cse_chain_rule : resource added" >> "$path_script"/resource_order.txt
    fi
    
    cat "$path_script"/resource_order.txt | grep "cse_aggregation_rule : resource added" &>/dev/null
    local aggregation_already=$?
    if [ $aggregation_already -eq 1 ];then
      echo "cse_aggregation_rule : resource added" >> "$path_script"/resource_order.txt
    fi

    cat "$path_script"/resource_order.txt | grep "cse_first_seen_rule : resource added" &>/dev/null
    local first_already=$?
    if [ $first_already -eq 1 ];then
      echo "cse_first_seen_rule : resource added" >> "$path_script"/resource_order.txt
    fi
    
    cat "$path_script"/resource_order.txt | grep "cse_outlier_rule : resource added" &>/dev/null
    local outlier_already=$?
    if [ $outlier_already -eq 1 ];then
      echo "cse_outlier_rule : resource added" >> "$path_script"/resource_order.txt
    fi
    
    return 0
  fi

  cat "$path_script"/resource_order.txt | grep "^$1 : resource added" &>/dev/null
  local already_added=$?
  if [ $already_added -eq 1 ];then
    echo "$1 : resource added" >> "$path_script"/resource_order.txt
  fi
}


# Takes two arguments
# $1 - resource name
# $2 - array of resources
#
# This function is used to get the index of an array element.
function index(){
	local element="$1"
	shift
	local copy_array=("$@")
	for i in "${!copy_array[@]}";do
		if [[ "${copy_array[$i]}" = "$element" ]];then
			echo "$i"
		fi
	done
}


# Takes one argument:
# $1 old tenant file in "$dir"/creds
#
# This function asks the user what resources he wants to import from previous tenant(s) and for each tenant 
# starts creating files needed in future in the old tenant directory located at "$dir"/import.
# Resources numbers are not random. In order to avoid problems during the program execution, you are strongly encouraged
# to select resourcer following their ascending order.
function choice(){
  local tenant_name="$(head -n 1 "$dir"/creds/"$1" | awk '{print $3}')"
  local import_dir="$(echo "$1" | sed 's/.txt//')"

  mkdir "$dir"/import/"$import_dir"
  touch "$dir"/import/"$import_dir"/resources.txt

  cow 34 "Time to choice what resources you want to configure from tenant $tenant_name!"
  nl 4

  readarray -t resources < <(cat "$dir"/api/import.txt | awk '{print $1}')
  PS3="

Keep in mind the following dependencies:

Source                  <-  Collector   (Warning: only hosted collector can be uploaded with the API)
User                    <-  Role
Rule tuning expression  <-  Rule
Custom insight          <-  Rule
Match list              <-  Match list column
Match list item         <-  Match list



Insert the resource number: "

  select r in "${resources[@]}";do
	  local index_check=$(index "$r" "${resources[@]}")
	  if [[ "$r" = "ALL" ]];then
      cat "$dir"/api/import.txt > "$dir"/import/"$import_dir"/resources.txt
      sed '/ALL /d' -i "$dir"/import/"$import_dir"/resources.txt
      sed '/END /d' -i "$dir"/import/"$import_dir"/resources.txt
      # echo "" >> "$dir"/import/"$import_dir"/resources.txt

      resource_order "all"
		  next "All resources added"
		  break
	  elif [[ "$r" = "END" ]];then
      if [[ -z $(cat "$dir"/import/"$import_dir"/resources.txt) ]];then
        next "No resources added, this tenant won't be used"
        rm -rf "$dir"/import/"$import_dir"
      else
		    next "Selected resources added"
      fi

		  break
	  elif [ $index_check -lt "${#resources[@]}" ] 2>/dev/null;then
      local resource_name="$r\s:"
		  if cat "$dir"/import/"$import_dir"/resources.txt | grep "^$resource_name" &>/dev/null;then
        echo -e "\nResource already added! Skipping...\n"
      else
        import_dependencies "$import_dir" "$r"
        local dependencies_satisfied=$?
        if [ $dependencies_satisfied -eq 1 ];then
          PS3="Insert the next resource number: "
          continue
        fi
        echo "$(cat $dir/api/import.txt | grep ^$resource_name)" >> "$dir"/import/"$import_dir"/resources.txt
        resource_order "$r"
      fi
	  else
		  echo -e "\nError: Invalid number\n"
	  fi
	  PS3="Insert the next resource number: "
  done
}


# This function creates "$dir"/log/import and "$dir"/error/import subdirectories based on import confiuration choices
function log_error_import(){
  for tenant in $(ls "$path_import");do
    for resource in $(cat "$path_import"/"$tenant"/resources.txt | awk '{print $1}');do
      mkdir -p "$path_log"/import/"$tenant"/"$resource" 
      mkdir -p "$path_error"/import/"$tenant"/"$resource" 
    done
  done
}


# This function creates "$dir"/log/upload and "$dir"/error/upload subdirectories based on upload confiuration choices
function log_error_upload(){
  for resource in $(cat "$path_script"/resource_order.txt | awk '{print $1}');do
    for tenant in $(ls "$path_upload"/"$resource");do
      mkdir -p "$path_log"/upload/"$resource"/"$tenant"
      mkdir -p "$path_error"/upload/"$resource"/"$tenant"
    done
  done
}


# Takes two arguments
# $1 - old tenant dirname
# $2 - file resource_name.json from $dir/import/old_$i/all/$resource_name.json
#
# This function performs both import and extraction and it's intended for resources that exceed the limit API parameter.
# IMPORTANT:
# at the end of this process, dir/import/old_$i/all/$resource_name.json will not contain all actual resource, but only
# ones from the last page returned from the API. All resources will be saved individually in $dir/import/old_$i/$resource_name
#
# NOTE:
# For some resources (for example dashboard) the API returno a json parameter "next", for others (for example log_search) the parameter is called "token", this is very stupid.
function multiple_import_next(){             
  local old_tenant="$1"
  local id=$(cat "$dir"/creds/"$old_tenant".txt | head -n 2 | tail -n 1 | awk '{print $3}')
  local key=$(cat "$dir"/creds/"$old_tenant".txt | head -n 3 | tail -n 1 | awk '{print $3}')

  local file_path="$dir"/import/"$old_tenant"/all/"$2"
  local resource_name=$(echo "$2" | sed 's/.json//')

  mkdir "$dir"/import/"$old_tenant"/"$resource_name"

  local api_link=$(cat "$dir"/import/"$old_tenant"/resources.txt | grep "^$resource_name" | awk '{print $3}')
  local parameter=$(cat "$dir"/import/"$old_tenant"/resources.txt | grep "^$resource_name" | awk '{print $4}')
  local parameter+="&token="
  local next_page=$(cat $file_path | jq ".next")

  local j=1
  while [[ "$next_page" != "null" ]];do
    local array_name=$(cat "$file_path" | jq | head -n 2 | tail -n 1 | sed 's/[^a-zA-Z]//g')
    local total=0
    total=$(cat "$file_path" | jq ".[] | length" | head -n 1)
    local next_page=$(cat $file_path | jq ".next")

    local i=0
    while [ $i -lt $total ];do
      local m=$(($i + $j))
      local n=$(printf "%.5d" $m)
      cat "$file_path" | jq ."$array_name"["$i"] > "$dir"/import/"$old_tenant"/"$resource_name"/"$resource_name"_"$n".json
      i=$(( $i + 1))
    done

    if [[ "$next_page" = "null" ]];then
      break
    fi

    if [ $(($api_calls % 4)) -eq 0 ];then
      wait
      sleep 0.5
    fi

    curl -s -u "$id:$key" -X GET -o "$file_path" "$api_link""$parameter""$next_page" 
    api_calls=$(($api_calls + 1))

    j=$(( $j + $total ))
  done
}


# Same as multiple_import_next
function multiple_import_token(){             
  local old_tenant="$1"
  local id=$(cat "$dir"/creds/"$old_tenant".txt | head -n 2 | tail -n 1 | awk '{print $3}')
  local key=$(cat "$dir"/creds/"$old_tenant".txt | head -n 3 | tail -n 1 | awk '{print $3}')

  local file_path="$dir"/import/"$old_tenant"/all/"$2"
  local resource_name=$(echo "$2" | sed 's/.json//')

  mkdir "$dir"/import/"$old_tenant"/"$resource_name"

  local api_link=$(cat "$dir"/import/"$old_tenant"/resources.txt | grep "^$resource_name" | awk '{print $3}')
  local parameter=$(cat "$dir"/import/"$old_tenant"/resources.txt | grep "^$resource_name" | awk '{print $4}')
  local parameter+="&token="
  local token_page=$(cat $file_path | jq ".token")

  local j=1
  while [[ "$token_page" != "null" ]];do
    local array_name=$(cat "$file_path" | jq | head -n 2 | tail -n 1 | sed 's/[^a-zA-Z]//g')
    local total=$(cat "$file_path" | jq ".[] | length" | head -n 1)
    local token_page=$(cat $file_path | jq ".token")

    local i=0
    while [ $i -lt $total ];do
      local m=$(($i + $j))
      local n=$(printf "%.5d" $m)
      cat "$file_path" | jq ."$array_name"["$i"] > "$dir"/import/"$old_tenant"/"$resource_name"/"$resource_name"_"$n".json
      i=$(( $i + 1))
    done

    if [[ "$token_page" = "null" ]];then
      break
    fi

    if [ $(($api_calls % 4)) -eq 0 ];then
      wait
      sleep 0.5
    fi

    curl -s -u "$id:$key" -X GET -o "$file_path" "$api_link""$parameter""$token_page"
    api_calls=$(($api_calls + 1))

    j=$(( $j + $total ))
  done
}


# Takes one argument
# $1 - old tenant dirname
#
# This function extract single resources for each resources list imported with the import function (defined immediately after this)
# And create a directory named after the resource name in "$dir"/import/"$old_tenant". Sources extraction is handled in "$path_script"/import_source.sh, in 
# "$path_import"/old_n/all there won't be a source.json file, all sources will be extracted directly in "$path_import"/old_n/all/source
function extract(){
  local old_tenant="$1"

  for r in $(ls "$dir"/import/"$old_tenant"/all);do
    local next_page=$(cat "$dir"/import/"$old_tenant"/all/"$r" | jq '.next')
    if [[ "$next_page" != "null" ]] && [[ "$next_page" != "" ]];then
      multiple_import_next "$old_tenant" "$r"
      continue
    fi

    # NOTE:
    # For some resources (for example dashboard) the API returno a json parameter "next", for others (for example log_search) the parameter is called "token", this is very stupid.

    local token_page=$(cat "$dir"/import/"$old_tenant"/all/"$r" | jq '.token')
    if [[ "$token_page" != "null" ]] && [[ "$token_page" != "" ]];then
      multiple_import_token "$old_tenant" "$r"
      continue
    fi

    local resource_name=$(echo "$r" | sed 's/.json//')
    local array_name=$(cat "$dir"/import/"$old_tenant"/all/"$r" | jq | head -n 2  | tail -n 1 | sed 's/[^a-zA-Z]//g')

    mkdir "$dir"/import/"$old_tenant"/"$resource_name"

    # echo ""
    # echo "resource_name: $resource_name"
    # echo "array_name: $array_name"
    # echo "total: $total"  =~ cse_.*

    # read -r -p "Press enter" continuation

    if [[ "$resource_name" = "cse_match_list_item" ]];then
      continue
    fi

    local i=0

    # if [[ "$resource_name" = "cse_rule" ]] || [[ "$resource_name" = "cse_rule_tuning_expression" ]];then
    if [[ "$resource_name" =~ cse_.* ]];then
      local total=$(cat "$dir"/import/"$old_tenant"/all/"$r" | jq ".data | .total")

      while [ $i -lt $total ];do
        local m=$(( $i + 1 ))
        local n=$(printf "%.5d" $m)
        cat "$dir"/import/"$old_tenant"/all/"$r" | jq ".data | .objects[$i]" > "$dir"/import/"$old_tenant"/"$resource_name"/"$resource_name"_"$n".json
        i=$(( $i + 1 ))
      done
    else
      local total=$(cat "$dir"/import/"$old_tenant"/all/"$r" | jq ".[] | length" | head -n 1)

      while [ $i -lt $total ];do
        local m=$(( $i + 1 ))
        local n=$(printf "%.5d" $m)
        cat "$dir"/import/"$old_tenant"/all/"$r" | jq ."$array_name"["$i"] > "$dir"/import/"$old_tenant"/"$resource_name"/"$resource_name"_"$n".json
        i=$(( $i + 1 ))
      done
    fi
  done
}


# Takes one argument
# $1 - old tenant dirname
#
# This function uses Sumo API (configured in "$dir"/api/import.txt) to import a list for each resources selected with the choice function
function import() {
  local old_tenant="$1"

  local tenant_name=$(cat "$dir"/creds/"$old_tenant".txt | head -n 1 | awk '{print $3}')
  local id=$(cat "$dir"/creds/"$old_tenant".txt | head -n 2 | tail -n 1 | awk '{print $3}')
  local key=$(cat "$dir"/creds/"$old_tenant".txt | head -n 3 | tail -n 1 | awk '{print $3}')

  mkdir "$dir"/import/"$old_tenant"/all
  echo -n "Importing resources from $tenant_name "

  while read -r r <&9; do
    local resource_name=$(echo "$r" | awk '{print $1}')
    local api_link=$(echo "$r" | awk '{print $3}')
    local parameter=$(echo "$r" | awk '{print $4}')

    if [[ "$resource_name" = "source" ]];then
      continue
    fi

    # echo "reosurce_name: $resource_name"
    # echo "api_link: $api_link"
    # echo "parameter: $parameter"

    # read -r -p "Press enter.."

    if [ $(($api_calls % 4)) -eq 0 ];then
      wait
      sleep 0.5
    fi

    curl -s -u "$id:$key" -X GET -o "$dir"/import/"$old_tenant"/all/"$resource_name".json "$api_link""$parameter" &
    api_calls=$(($api_calls + 1))

    # read -r -p "Press enter.."
    # echo ""

    echo -n "."
  done 9< "$dir"/import/"$old_tenant"/resources.txt
  
  wait
  extract "$old_tenant"

  # This is done outside the while because of the need of "$dir"/import/"$tenant"/collector/ in "$path_script"/import_source.sh
  if cat "$dir"/import/"$old_tenant"/resources.txt | grep "^source :" &>/dev/null;then
    "$path_script"/import_source.sh "$old_tenant" #&>/dev/null
  fi

  echo -e ".\n"
}


# Takes one argument:
# $1 - old tenant dirname
#
# This function scans "$dir"/import to prepare resources in "$path_upload"/$1 before actual post requests to the API
function configure(){
  local tenant_dirname="$1"
  local tenant_path="$dir"/import/"$1"

  while read -r line <&7;do
    local resource_name=$(echo $line | awk '{print $1}')
    mkdir -p "$path_upload"/"$resource_name"/"$tenant_dirname"

    if [[ "$resource_name" = "user" ]] || [[ "$resource_name" = "source" ]] || [[ "$resource_name" = "cse_rule_tuning_expression" ]] || [[ "$resource_name" = "cse_custom_insight" ]] || [[ "$resource_name" = "cse_match_list" ]] || [[ "$resource_name" = "cse_match_list_item" ]];then
      continue
    fi

    "$path_script"/"$resource_name".sh "$tenant_dirname" &
  done 7< "$tenant_path"/resources.txt
  wait
}


# Takes one argument
# $1 - resource name
#
# This function performs a basic upload of the resources, meaning that no itermediate action is required by the user,
# all imported resources will be uploaded just as they are, without making any difference between source tenants.
# The wait within the if clause is for the limit in concurrent requests that can be made to any API, see
# https://help.sumologic.com/docs/api/getting-started/#rate-limiting
# Medium and advanced upload don't require this since user interaction already slows down the process.
function basic_upload(){
  local resource_name="$1"
  local resource_path="$path_upload"/"$resource_name"

  local access_id=$(head -n 2 "$path_creds"/new.txt | tail -n 1 | awk '{print $3}')
  local key=$(head -n 3 "$path_creds"/new.txt | tail -n 1 | awk '{print $3}')
  local url=$(cat "$dir"/api/upload.txt | grep "^$resource_name\s:"| awk '{print $3}')

  echo -e -n "\n\n\nUploading all $resource_name at once ..."

  for tenant in $(ls "$resource_path");do
    for resource in $(ls "$resource_path"/"$tenant");do
      if [ $(($api_calls % 4)) -eq 0 ];then
        wait
        sleep 0.5
      fi
      curl -s -u "$access_id:$key" -X POST -H "Content-Type: application/json" -T "$resource_path"/"$tenant"/"$resource" -o "$path_log"/upload/"$resource_name"/"$tenant"/"$resource" "$url" &
      api_calls=$(($api_calls + 1))
    done
  done
  wait
}


# Takes one argument
# $1 - resource name
#
# This function performs an upload of the resources with a medium level of control, meaning that the user can choose whether to
# confirm or drop the upload for each resource.
function medium_upload(){
  local resource_name="$1"
  local resource_path="$path_upload"/"$resource_name"

  local access_id=$(head -n 2 "$path_creds"/new.txt | tail -n 1 | awk '{print $3}')
  local key=$(head -n 3 "$path_creds"/new.txt | tail -n 1 | awk '{print $3}')
  local url=$(cat "$dir"/api/upload.txt | grep "^$resource_name\s:"| awk '{print $3}')

  for tenant in $(ls "$resource_path");do
    local tenant_name=$(head -n 1 "$path_creds"/"$tenant".txt | awk '{print $3}')
    next "We are now uploading $resource_name resources from $tenant_name"
    nl 2

    for resource in $(ls "$resource_path"/"$tenant");do
      local total_lines=$(cat "$resource_path"/"$tenant"/"$resource" | wc -l)

      if [[ $total_lines -gt 14 ]];then
        cow 54 "The following is a preview of the $resource_name to be imported, since its lines are a lot! To see the full resource check out $resource_path/$tenant/$resource"
        nl 2
        head -n 14 "$resource_path"/"$tenant"/"$resource"
      else
        cow 24 "The $resource_name configuration your're about to upload is the following"
        nl 2
        cat "$resource_path"/"$tenant"/"$resource" | jq
      fi

      nl 5
      read -r -N 1 -p "Are you sure you want to upload the described $resource_name? (y/n) " confirm

      if [[ "$confirm" != "y" ]];then
        next "Upload aborted"
        continue
      else
        next "Upload confirmed"
      fi

      curl -s -u "$access_id:$key" -X POST -H "Content-Type: application/json" -T "$resource_path"/"$tenant"/"$resource" -o "$path_log"/upload/"$resource_name"/"$tenant"/"$resource" "$url" &
    done
  done
  wait
}


# Takes one argument
# $1 - resource name
#
# This function performs an upload of the resources with an advanced level of control, meaning that the user can choose whether to confirm
# or drop the upload for each resource, or even open the json file to apply changes to the resource configuration. This mode gives aldo the capability to upload n resources and skip all
# the remainings
function advanced_upload(){
  local resource_name="$1"
  local resource_path="$path_upload"/"$resource_name"

  local access_id=$(head -n 2 "$path_creds"/new.txt | tail -n 1 | awk '{print $3}')
  local key=$(head -n 3 "$path_creds"/new.txt | tail -n 1 | awk '{print $3}')
  local url=$(cat "$dir"/api/upload.txt | grep "^$resource_name\s:"| awk '{print $3}')

  for tenant in $(ls "$resource_path");do
    local tenant_name=$(head -n 1 "$path_creds"/"$tenant".txt | awk '{print $3}')
    next "We are now uploading $resource_name resources from $tenant_name"
    nl 2

    for resource in $(ls "$resource_path"/"$tenant");do
      local total_lines=$(cat "$resource_path"/"$tenant"/"$resource" | wc -l)

      if [[ $total_lines -gt 14 ]];then
        cow 54 "The following is a preview of the $resource_name to be imported, since its lines are a lot! To see the full resource check out $resource_path/$tenant/$resource"
        nl 2
        head -n 14 "$resource_path"/"$tenant"/"$resource"
      else
        cow 24 "The $resource_name configuration your're about tu upload is the following"
        nl 2
        cat "$resource_path"/"$tenant"/"$resource" | jq
      fi

      nl 5
      local upload_confirmed=0
      
      PS3="
What do you want to do with this $resource_name: "

      select action in "upload" "change and upload" "drop" "drop all remaining";do
        case "$action" in
          "upload")
            next "Upload confirmed"
            ;;
          "change and upload")
            nano "$resource_path"/"$tenant"/"$resource"
            nl 1
            local confirm
            read -r -N 1 -p "Confirm changes and upload? (y/n) " confirm
              if [[ "$confirm" != "y" ]];then
                next "Upload aborted"
                upload_confirmed=1
              else
                next "Upload confirmed"
              fi
            ;;
          "drop")
            next "Upload aborted"
            upload_confirmed=1
            ;;
          "drop all remaining")
            next "All remaining uploads aborted"
            return 0
            ;;
          *)
            ;;
        esac
        break
      done

      if [ $upload_confirmed -eq 1 ];then
        continue
      fi

      curl -s -u "$access_id:$key" -X POST -H "Content-Type: application/json" -T "$resource_path"/"$tenant"/"$resource" -o "$path_log"/upload/"$resource_name"/"$tenant"/"$resource" "$url" &
    done
  done
  wait
}


# Takes one argument
# $1 - resource name
#
# This function is to ask the user how he wants to upload configuration to the new tenant
function mode_choice(){
  local resource_name="$1"
  local total=0
  for tenant in $(ls "$path_upload"/"$resource_name");do
    local partial=$(ls -1 "$path_upload"/"$resource_name"/"$tenant" | wc -l)
    total=$(( $total + $partial ))

  done

  if [ $total -eq 0 ];then
    echo "0 $resource_name found from previous tenant(s), skipping..."
    sleep 3
    clear
    return 4
  fi
  PS3="
Basic:    Upload all resources
Medium:   Check resources and eventually drop something
Advanced: Check resources and eventually change something

Total resource to add: $total

Select the mode for uploading $resource_name: "

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
      PS3="Select the mode for uploading $resource_name: "
      ;;
  esac
done
}


# Takes one argument:
# $1 - resource name
#
# This function is a 'wrapper' for actual upload functions defined above, its main scope is to keep track whether the user want to perform
# the mode choice each time or not
function upload(){
  local resource_name="$1"

  next "Let's upload $resource_name"
  nl 2

  if [[ "$resource_name" = "user" ]] || [[ "$resource_name" = "source" ]] || [[ "$resource_name" = "cse_rule_tuning_expression" ]] || [[ "$resource_name" = "cse_custom_insight" ]] || [[ "$resource_name" = "cse_match_list" ]] || [[ "$resource_name" = "cse_match_list_item" ]];then
    cow 24 "$resource_name require a special configuration, wait until this step is completed."
    for tenant in $(ls "$path_import");do
      if cat "$path_import"/"$tenant"/resources.txt | grep "^$resource_name :" &>/dev/null;then
        "$path_script"/"$resource_name".sh $tenant &>/dev/null
      fi
    done
  fi

  if [[ "$resource_name" = "source" ]];then
    "$path_script/upload_source.sh"
    return 0
  fi

  if [[ "$resource_name" = "cse_match_list_item" ]];then
    "$path_script/upload_cse_match_list_item.sh"
    return 0
  fi

  local mode_always=$(head -n 1 "$path_creds/mode_upload.txt")
  if [ $mode_always -eq 1 ];then
    mode_choice "$resource_name"
    local mode_answer=$?
    nl 1
    local mode_skip
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
      basic_upload "$resource_name"
      ;;
    2)
      medium_upload "$resource_name"
      ;;
    3)
      advanced_upload "$resource_name"
      ;;
    4)
      return 0
      ;;
    *)
      ;;
  esac

  case "$resource_name" in
    "dashboard")
      next "A folder named \"API Dashboard\" has been created inside your personal folder"
      ;;
    "log_search")
      next "A folder named \"API Log Search\" has been created inside your personal folder"
      ;;
    *)
      ;;
  esac
}


function extract_error(){
  cow 24 "If errors were encountered, they'll be listed below"
  sleep 2
  nl 2
  local errors=0

  echo -e "Import errors: \n"

  for tenant in $(ls "$path_log"/import);do
    local tenant_name=$(head -n 1 "$path_creds"/"$tenant".txt | awk '{print$3}')
    local prievous_errors=$errors
    for resource in $(ls "$path_log"/import/"$tenant");do
      if [[ "$resource" = "all" || "$resource" = "resources.txt" ]];then
        continue
      fi
      for r in $(ls "$path_log"/import/"$tenant"/"$resource");do
        cat "$path_log"/import/"$tenant"/"$resource"/"$r" | grep "\"errors\".*:.*\[" &>/dev/null
        error_array=$?

        if [ $error_array -eq 0 ];then
          mv "$path_log"/import/"$tenant"/"$resource"/"$r" "$path_error"/import/"$tenant"/"$resource"/"$r"
          error_message=$(cat "$path_error"/import/"$tenant"/"$resource"/"$r" | jq ".errors[] | .message")

          if [["$error_message" != ""]];then
            printf "%-100s" "For $r from $tenant_name: "
            cat "$path_error"/import/"$tenant"/"$resource"/"$r" | jq ".errors[] | .message"
            errors=$(($errors + 1))
          fi
      fi
      done
      if [ $prievous_errors -lt $errors ];then
        echo ""
      fi
    done
  done

  if [ $errors -eq 0 ];then
    echo -e "\n\nNo errors found 🤙"
  else
    echo -e "Total errors: $errors 💀"
  fi

  nl 1

  errors=0
  echo -e "\n\nUpload errors: \n"

  for resource in $(cat "$path_script"/resource_order.txt | awk '{print $1}');do
    if [[ "$resource" = "source" ]];then

      for tenant in $(ls "$path_log"/upload/"$resource");do
        tenant_name=$(head -n 1 "$path_creds"/"$tenant".txt | awk '{print$3}')
        
        for collector in $(ls "$path_log"/upload/"$resource"/"$tenant");do
          prievous_errors=$errors
          collector_name=$(echo "$collector" | sed 's/collector_//')
          for r in $(ls "$path_log"/upload/"$resource"/"$tenant"/"$collector");do
            cat "$path_log"/upload/"$resource"/"$tenant"/"$collector"/"$r" | grep "\"status\"\s:\s400" &>/dev/null
            error_400=$?

              if [ $error_400 -eq 0 ];then
                mv "$path_log"/upload/"$resource"/"$tenant"/"$collector"/"$r" "$path_error"/upload/"$resource"/"$tenant"/"$collector"/"$r"

  		          error_message=$(cat "$path_error"/upload/"$resource"/"$tenant"/"$collector"/"$r" | jq ".message")
  		          if [[ "$error_message" != "" ]];then
                  printf "%-100s" "For $r from $tenant_name, collector $collector_name: "
                  cat "$path_error"/upload/"$resource"/"$tenant"/"$collector"/"$r" | jq ".message"
                  errors=$(($errors + 1))
		            fi              
              fi
          done
          if [ $prievous_errors -lt $errors ];then
            echo ""
          fi
        done
      done
      continue
    fi

    if [[ "$resource" = "cse_match_list_item" ]];then

      for tenant in $(ls "$path_log"/upload/"$resource");do
        tenant_name=$(head -n 1 "$path_creds"/"$tenant".txt | awk '{print$3}')
        
        for match_list in $(ls "$path_log"/upload/"$resource"/"$tenant");do
          prievous_errors=$errors
          match_list_name=$(echo "$match_list" | sed 's/match_list_//')
          #for r in $(ls "$path_log"/upload/"$resource"/"$tenant"/"$match_list");do
            cat "$path_log"/upload/"$resource"/"$tenant"/"$match_list"/items.json | grep "\"status\"\s:\s400" &>/dev/null
            error_400=$?

              if [ $error_400 -eq 0 ];then
                mv "$path_log"/upload/"$resource"/"$tenant"/"$match_list"/items.json "$path_error"/upload/"$resource"/"$tenant"/"$match_list"/items.json

  		          error_message=$(cat "$path_error"/upload/"$resource"/"$tenant"/"$match_list"/items.json | jq ".message")
  		          if [[ "$error_message" != "" ]];then
                  printf "%-100s" "For $r from $tenant_name, collector $match_list_name: "
                  cat "$path_error"/upload/"$resource"/"$tenant"/"$match_list"/items.json | jq ".message"
                  errors=$(($errors + 1))
		            fi              
              fi
          #done
          if [ $prievous_errors -lt $errors ];then
            echo ""
          fi
        done
      done
      continue
    fi

    for tenant in $(ls "$path_log"/upload/"$resource");do
      tenant_name=$(head -n 1 "$path_creds"/"$tenant".txt | awk '{print$3}')
      prievous_errors=$errors
      for r in $(ls "$path_log"/upload/"$resource"/"$tenant");do
        cat "$path_log"/upload/"$resource"/"$tenant"/"$r" | grep "\"errors\".*:.*\[" &>/dev/null
        error_array=$?
        cat "$path_log"/upload/"$resource"/"$tenant"/"$r" | grep "\"status\"\s:\s400" &>/dev/null
        error_400=$?

        if [ $error_array -eq 0 ] || [ $error_400 -eq 0 ];then
          mv "$path_log"/upload/"$resource"/"$tenant"/"$r" "$path_error"/upload/"$resource"/"$tenant"/"$r"

          if [ $error_array -eq 0 ];then
		        error_message=$(cat "$path_error"/upload/"$resource"/"$tenant"/"$r" | jq ".errors[] | .message")
            
		        if [[ "$error_message" != "" ]];then
              printf "%-100s" "For $r from $tenant_name: "
              cat "$path_error"/upload/"$resource"/"$tenant"/"$r" | jq ".errors[] | .message"
              errors=$(($errors + 1))
		        fi
          fi

          if [ $error_400 -eq 0 ];then
            error_message=$(cat "$path_error"/upload/"$resource"/"$tenant"/"$r" | jq ".message")

		        if [[ "$error_message" != "" ]];then
              printf "%-100s" "For $r from $tenant_name: "
              cat "$path_error"/upload/"$resource"/"$tenant"/"$r" | jq ".message"
              errors=$(($errors + 1))
            fi
          fi
        fi
      done
      if [ $prievous_errors -lt $errors ];then
        echo ""
      fi
    done
  done

  if [ $errors -eq 0 ];then
    echo -e "\nNo errors found 🤙"
  else
    echo -e "\nTotal errors: $errors 💀"
  fi

  echo -e "\nPress enter to continue.."
  local error_check_done
  read -r -p "" error_check_done
}


function erase_creds(){
  shred -n 50 -z -u "$dir"/creds/* 2>/dev/null
}


function bye(){
	cow 24 "Program terminated! Press enter to exit..."
  local answer
	read -r -p "" answer
	clear
}


# End function definition, start of script flow


clean
welcome
log_backup
check
old_tenant
next "Very good"

for i in $(ls "$dir"/creds | grep "old");do
  choice "$i"
done

if [ -f "$path_creds"/old_002.txt ];then
  next "Resource choice from all previous tenants completed"
fi

cow 34 "Wait until import process is completed. This can take a while based on how many resources you're importing from how many previous tenants"
nl 2

for old_tenant in $(ls "$dir"/import);do
  import "$old_tenant"
done

log_error_import

next "Import step terminated, time to upload imported resources on the new tenant"
cow 24 "Wait while configurations for resources json files are built."
sleep 3

for old_tenant in $(ls "$dir"/import);do
  configure "$old_tenant"
done

log_error_upload

next "We are ready to upload all resources"
nl 2
echo "1" > "$path_creds/mode_upload.txt"

for resource in $(cat "$path_script"/resource_order.txt | awk '{print $1}');do
  upload "$resource"
done

log_empty=$(ls "$dir"/log | wc -l)
error_empty=$(ls "$dir"/error | wc -l)
if ! [ $log_empty -eq 0 ] || ! [ $error_empty -eq 0 ];then
  extract_error
fi

erase_creds
bye

exit 0
