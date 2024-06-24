#!/bin/bash

# Author: kond3
# Date: 11/06/2024
# Last modified: 11/06/2024 12:28:06

# Description
# Script to convert json imported to json ready to be uploaded.

# Usage
# ./cse_rule.sh <old_tenant_dirname>

dir=$(dir.sh)

tenant="$1"
tenant_name=$(head -n 1 "$dir"/creds/"$tenant".txt | awk '{print $3}')
resource_path="$dir"/import/"$tenant"/cse_rule


# Function definition


function prepare_upload() {

    cat "$resource_path"/* | jq ".id" | grep -i "match" &>/dev/null
    match_present=$?
    if [ $match_present -eq 1 ];then
        sed '/.*cse_match_rule :.*/d' -i "$dir"/script/resource_order.txt 
    else
        mkdir -p "$dir"/upload/cse_match_rule/"$tenant" &>/dev/null
    fi

    cat "$resource_path"/* | jq ".id" | grep -i "threshold" &>/dev/null
    threshold_present=$?
    if [ $threshold_present -eq 1 ];then
        sed '/.*cse_threshold_rule :.*/d' -i "$dir"/script/resource_order.txt
    else
        mkdir -p "$dir"/upload/cse_threshold_rule/"$tenant" &>/dev/null
    fi

    cat "$resource_path"/* | jq ".id" | grep -i "chain" &>/dev/null
    chain_present=$?
    if [ $chain_present -eq 1 ];then
        sed '/.*cse_chain_rule :.*/d' -i "$dir"/script/resource_order.txt
    else
        mkdir -p "$dir"/upload/cse_chain_rule/"$tenant" &>/dev/null
    fi

    cat "$resource_path"/* | jq ".id" | grep -i "aggregation" &>/dev/null
    aggregation_present=$?
    if [ $aggregation_present -eq 1 ];then
        sed '/.*cse_aggregation_rule :.*/d' -i "$dir"/script/resource_order.txt
    else
        mkdir -p "$dir"/upload/cse_aggregation_rule/"$tenant" &>/dev/null
    fi

    cat "$resource_path"/* | jq ".id" | grep -i "first" &>/dev/null
    first_present=$?
    if [ $first_present -eq 1 ];then
        sed '/.*cse_first_seen_rule :.*/d' -i "$dir"/script/resource_order.txt
    else
        mkdir -p "$dir"/upload/cse_first_seen_rule/"$tenant" &>/dev/null
    fi

    cat "$resource_path"/* | jq ".id" | grep -i "outlier" &>/dev/null
    outlier_present=$?
    if [ $outlier_present -eq 1 ];then
        sed '/.*cse_outlier_rule :.*/d' -i "$dir"/script/resource_order.txt
    else
        mkdir -p "$dir"/upload/cse_outlier_rule/"$tenant" &>/dev/null
    fi

}


# All the following functions take two arguments:
# $1 - resource filename from "$resource_path"
# $2 - category
m=1
function configure_match(){
    upload_path="$dir"/upload/cse_match_rule/"$tenant"
    n=$(printf "%.5d" $m)

    cat "$resource_path"/"$1" | jq "{fields: {category: \"$2\",enabled: .enabled,entitySelectors: .entitySelectors,isPrototype: .isPrototype,name: .name,parentJaskId: .parentJaskId,summaryExpression: .summaryExpression,suppressionWindowSize: .suppressionWindowSize,tags: .tags,descriptionExpression: .descriptionExpression,expression: .expression,nameExpression: .nameExpression,scoreMapping: .scoreMapping,stream: .stream}}" > "$upload_path"/cse_match_rule_"$n".json
    m=$(($m +1))
}


t=1
function configure_threshold(){
    upload_path="$dir"/upload/cse_threshold_rule/"$tenant"
    n=$(printf "%.5d" $t)

    window_size=$(cat "$resource_path"/"$resource" | jq ".windowSizeName" | sed 's/"//g')
    if [[ "$window_size" = "CUSTOM" ]];then
        window_size=$(cat "$resource_path"/"$resource" | jq ".windowSize" | sed 's/"//g')
    fi

    cat "$resource_path"/"$1" | jq "{fields: {category: \"$2\",enabled: .enabled,entitySelectors: .entitySelectors,isPrototype: .isPrototype,name: .name,parentJaskId: .parentJaskId,summaryExpression: .summaryExpression,suppressionWindowSize: .suppressionWindowSize,tags: .tags,description: .description,countDistinct: .countDistinct,countField: .countField,expression: .expression,limit: .limit,score: .score,stream: .stream,version: .version,windowSize: \"$window_size\",groupByFields: .groupByFields}}" > "$upload_path"/cse_threshold_rule_"$n".json
    t=$(($t +1))
}


c=1
function configure_chain() {
    upload_path="$dir"/upload/cse_chain_rule/"$tenant"
    n=$(printf "%.5d" $c)

    cat "$resource_path"/"$1" | jq "{fields: {category: \"$2\",enabled: .enabled,entitySelectors: .entitySelectors,isPrototype: .isPrototype,name: .name,parentJaskId: .parentJaskId,summaryExpression: .summaryExpression,suppressionWindowSize: .suppressionWindowSize,tags: .tags,description: .description,expressionsAndLimits: [.expressionsAndLimits[] | {expression: .expression,limit: .limit}],groupByFields: .groupByFields,ordered: .ordered,score: .score,stream: .stream,windowSize: .windowSizeName}}" > "$upload_path"/cse_chain_rule_"$n".json
    c=$(($c +1))
}

a=1
function configure_aggregation(){
    upload_path="$dir"/upload/cse_aggregation_rule/"$tenant"
    n=$(printf "%.5d" $a)

    cat "$resource_path"/"$1" | jq "{fields: {category: \"$2\",enabled: .enabled,entitySelectors: .entitySelectors,isPrototype: .isPrototype,name: .name,parentJaskId: .parentJaskId,summaryExpression: .summaryExpression,suppressionWindowSize: .suppressionWindowSize,tags: .tags,aggregationFunctions: .aggregationFunctions,descriptionExpression: .descriptionExpression,groupByAsset: .groupByAsset,groupByFields: .groupByFields,matchExpression: .matchExpression,nameExpression: .nameExpression,scoreMapping: .scoreMapping,stream: .stream,triggerExpression: .triggerExpression,windowSize: .windowSizeName}}" > "$upload_path"/cse_aggregation_rule_"$n".json
    a=$(($a +1))
}


f=1
function configure_first(){
    upload_path="$dir"/upload/cse_first_seen_rule/"$tenant"
    n=$(printf "%.5d" $f)
  
    cat "$resource_path"/"$1" | jq "{fields: {category: \"$2\",enabled: .enabled,entitySelectors: .entitySelectors,isPrototype: .isPrototype,name: .name,parentJaskId: .parentJaskId,summaryExpression: .summaryExpression,suppressionWindowSize: .suppressionWindowSize,tags: .tags,descriptionExpression: ,descriptionExpression,nameExpression: .nameExpression,filterExpression: .filterExpression,valueFields: .valueFields,valueExpression: .valueExpression,groupByFields: .groupByFields,score: .score,version: .version,baselineWindowSize: .baselineWindowSize,retentionWindowSize: .retentionWindowSize,baselineType: .baselineType}}" > "$upload_path"/cse_first_seen_rule_"$n".json
    f=$(($f +1))
}


o=1
function configure_outlier(){
    upload_path="$dir"/upload/cse_outlier_rule/"$tenant"
    n=$(printf "%.5d" $o)

    cat "$resource_path"/"$1" | jq "{fields: {category: \"$2\",enabled: .enabled,entitySelectors: .entitySelectors,isPrototype: .isPrototype,name: .name,parentJaskId: .parentJaskId,summaryExpression: .summaryExpression,suppressionWindowSize: .suppressionWindowSize,tags: .tags,nameExpression: .nameExpression,groupByFields: .groupByFields,score: .score,baselineWindowSize: .baselineWindowSize,retentionWindowSize: .retentionWindowSize,floorValue: .floorValue,deviationThreshold: .deviationThreshold,descriptionExpression: .descriptionExpression,matchExpression: .matchExpression,aggregationFunctions: .aggregationFunctions,windowSize: .windowSizeName}}" > "$upload_path"/cse_outlier_rule_"$n".json
    o=$(($o +1))
}

# End of function definition

rm -rf mkdir "$dir"/upload/cse_rule
prepare_upload

for resource in $(ls "$resource_path");do

    category=$(cat "$resource_path"/"$resource" | jq ".category" | sed 's/"//g')
    if [[ "$category" = "null" ]];then
        category="Imported with API from $tenant_name"
    fi

    rule_type=$(cat "$resource_path"/"$resource" | jq ".id" | sed 's/[^a-zA-Z]//g' | sed 's/U$//')

    case "$rule_type" in
        "MATCH")
            configure_match "$resource" "$category"
            ;;
        "THRESHOLD")
            configure_threshold "$resource" "$category"
            ;;
        "CHAIN")
            configure_chain "$resource" "$category"
            ;;
        "AGGREGATION")
            configure_aggregation "$resource" "$category"
            ;;
        "FIRST")
            configure_first "$resource" "$category"
            ;;
        "OUTLIER")
            configure_outlier "$resource" "$category"
            ;;
        *)
            ;;
    esac
done

exit 0