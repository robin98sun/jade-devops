#!/usr/bin/env bash

if [[ `which jq|wc -l|awk '{print $1}'` -lt 1 ]];then
    echo "jq is not installed"
    exit 1
fi

host_conf_dir=$1

if [[ "$host_conf_dir" == "" ]];then
    echo "configuration directory is not provided"
    exit 1
fi

public_keys="agent_id location accuracy avg_temperature current_temperature"

for conf_file in `ls "$host_conf_dir"`; do
    file="${host_conf_dir}/${conf_file}"
    ls -l $file
    conf=`cat $file|jq`
    capabilities=`cat $file|jq '.capabilities'`
    private="{}"
    public="{}"
    
    is_file_already_updated=false
    for key in `echo $capabilities|jq -r 'keys'|awk '{if(length($1) > 3){print substr($1,4,length($1)-4)}}' FS=','`; do

        for cri_key in `echo "public private"`; do
            if [[ "$cri_key" == "$key" ]];then
                is_file_already_updated=true
            fi
        done
        if [[ "$is_file_already_updated" == true ]];then
            break
        fi

        value=`echo "$capabilities"|jq ".\"$key\""`
        is_pub_key=false
        for pub_key in $public_keys; do
            if [[ "$key" == $pub_key ]];then
                public=`echo "$public"|jq ".\"${key}\" = $value"`
                is_pub_key=true
                break
            fi
        done
        if [[ "${is_pub_key}" == false ]];then
            private=`echo "${private}"|jq ".\"${key}\" = $value"`
        fi
    done
    if [[ "$is_file_already_updated" == true ]];then
        continue
    fi

    new_cap=`echo "{}"|jq ".private = $private" |jq ".public = $public"`
    conf=`echo $conf|jq ".capabilities = $new_cap"`
    tmpfile="${file}.tmp"
    echo $conf|jq > $tmpfile && mv $tmpfile $file
    echo "  updated"
done

