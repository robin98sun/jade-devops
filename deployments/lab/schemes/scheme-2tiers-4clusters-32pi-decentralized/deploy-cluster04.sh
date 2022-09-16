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

additional_args=""
is_emulation=$4
if [[ "$is_emulation"  != "" ]];then
    additional_args="--is-emulation"
fi

if [[ "$5"  != "" ]];then
    additional_args="$additional_args --group-name $5"
fi

env_dir=${root_dir}/deployments/lab/env
# rm -rf ${env_dir}
if [[ ! -d $env_dir ]];then
    mkdir -p ${env_dir}
fi

# tier1
# cluster4: cluster 04: Server room in SEIR
${root_dir}/speed-deploy-by-config.py \
    --registry ${root_dir}/deployments/lab/hosts/$deployment_config_directory/master-node.json \
    --master ${root_dir}/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-04.json \
    --agents ${root_dir}/deployments/lab/hosts/$deployment_config_directory/agent-nodes-1.1.json \
             ${root_dir}/deployments/lab/hosts/$deployment_config_directory/agent-nodes-1.2.json \
             ${root_dir}/deployments/lab/hosts/$deployment_config_directory/agent-nodes-1.3.json \
             ${root_dir}/deployments/lab/hosts/$deployment_config_directory/agent-nodes-1.4.json \
             ${root_dir}/deployments/lab/hosts/$deployment_config_directory/agent-nodes-3.1.json \
             ${root_dir}/deployments/lab/hosts/$deployment_config_directory/agent-nodes-3.2.json \
             ${root_dir}/deployments/lab/hosts/$deployment_config_directory/agent-nodes-3.3.json \
             ${root_dir}/deployments/lab/hosts/$deployment_config_directory/agent-nodes-3.4.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all' "$additional_args"


