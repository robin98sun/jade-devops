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

env_dir=./jade-devops/deployments/lab/env
rm -rf ${env_dir}
mkdir -p ${env_dir}

# top tier (tier0)
./jade-devops/speed-deploy-by-config.py \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/master-node.json \
    --agents ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-4.1.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-4.2.json \
    --env-dir ${env_dir} \
    --version ${version} 

# tier1
# cluster1: 1-tier cluster with 6 leaves
./jade-devops/speed-deploy-by-config.py \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-4.1.json \
    --agents ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-1.3.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-2.3.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-2.4.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-3.3.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-3.4.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-4.3.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'agent'

# cluster2: 2-tier cluster with 2 sub-clusters
./jade-devops/speed-deploy-by-config.py \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-4.2.json \
    --agents ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-1.2.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-1.4.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-2.1.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-2.2.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-3.2.json \
             ./jade-devops/deployments/lab/hosts/$deployment_config_directory/agent-nodes-4.4.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'agent'





