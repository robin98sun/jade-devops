#!/usr/bin/env bash

version=$1
if [[ "$version" == "" ]]; then
    echo "VERSION number is missing when deploying JADE clusters"
    exit 1
fi

deployment_config_directory=$2
if [[ "$deployment_config_directory" == "" ]]; then
    deployment_config_directory='ethernet-16'
fi

root_dir=$3
if [[ "$root_dir" == "" ]];then
    root_dir="${root_dir}"
fi

env_dir=${root_dir}/deployments/lab/env
# rm -rf ${env_dir}
if [[ ! -d $env_dir ]];then
    mkdir -p ${env_dir}
fi


# dedicated registry
${root_dir}/speed-deploy-by-config.py \
    --master ${root_dir}/deployments/lab/hosts/$deployment_config_directory/master-node.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all' 

