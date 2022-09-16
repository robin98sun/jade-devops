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
    root_dir="./jade-devops"
fi

env_dir=${root_dir}/deployments/lab/env
# rm -rf ${env_dir}
if [[ ! -d $env_dir ]];then
    mkdir -p ${env_dir}
fi


# dedicated registry
./jade-devops/speed-deploy-by-config.py \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/master-node.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# tier1
# cluster1: cluster 01: SEIR225
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/master-node.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --agents ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-2.1.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-2.2.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-2.3.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-2.4.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-4.1.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-4.2.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-4.3.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-4.4.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

