#!/usr/bin/env bash

version=$1
if [[ "$version" == "" ]]; then
    echo "VERSION number is missing when deploying JADE clusters"
    exit 1
fi

deployment_config_directory=$2
if [[ "$deployment_config_directory" == "" ]]; then
    deployment_config_directory='ethernet-36'
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

# without pi-13 or pi-51
./jade-devops/speed-deploy-by-config.py \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --agents ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-1.1.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-1.2.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-1.4.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-2.1.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-2.2.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-2.3.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-2.4.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-3.1.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-3.2.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-3.3.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-3.4.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-4.1.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-4.2.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-4.3.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-4.4.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-5.0.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-5.2.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-5.3.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-5.4.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-5.5.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-5.6.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-5.7.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-6.0.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-6.1.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-6.2.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-6.3.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-6.4.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-6.5.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-6.6.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-6.7.json \
    --env-dir ${env_dir} \
    --version ${version}
