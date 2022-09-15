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


# dedicated registry (most powerful)
./jade-devops/speed-deploy-by-config.py \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# tier1
# cluster1: cluster 01: SEIR225
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/master-node.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# cluster2: cluster 02: Akshit's Office
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-02.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# cluster3: cluster 03: Ning's Office
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-03.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# cluster4: cluster 04: Server room in SEIR
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-04.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-11.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-12.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-13.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-14.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-21.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-22.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-23.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-24.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-31.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-32.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-33.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-34.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-41.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-42.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-43.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-44.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-50.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-51.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-52.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-53.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-54.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-55.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-56.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-57.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-60.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-61.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-62.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-63.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-64.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-65.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-66.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'

# Raspberry Pi Clusters
./jade-devops/speed-deploy-by-config.py \
    --registry ./jade-devops/deployments/lab/hosts/$deployment_config_directory/cluster-nodes-01.json \
    --master ./jade-devops/deployments/lab/hosts/$deployment_config_directory/aces-pi-67.json \
    --env-dir ${env_dir} \
    --version ${version} \
    --partial-deployment 'all'