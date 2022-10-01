#!/usr/bin/env bash
node_name=$1
image=$2
env_file=$3
namespace=$4
delete=$5
is_emulation=$6
host_name=$7


if [[ "$host_name" == "" ]];then
  host_name="$node_name"
fi

if [[ "$env_file" == "" ]];then
  env_file="./jade-devops/deployments/lab/env/${node_name}.txt"
fi

if [[ "$namespace" == "" ]];then
  namespace=default
fi

if [[ "$delete" == "pods" || "$delete" == "all" ]];then
  kubectl get pods|sed '1d'|awk '{print $1}'|grep jadelet-${node_name}|xargs kubectl delete pods
fi

function service_name() {
  if [ "$1" == "emulation" ];then
    echo "emulation-${node_name}-service-external"
  else
    echo "jadelet-${node_name}-service-external"
  fi
}

if [[ "$delete" == "services" || "$delete" == "all" ]];then
  srvName=`service_name ${is_emulation}`
  kubectl delete service $srvName
fi

# Deploy agents
deployment_name="jadelet"
if [[ "$is_emulation" == "emulation" ]];then
  deployment_name="emulation"
fi
./jade-devops/k8s-deployer.py --print --namespace $namespace --deployment-name $deployment_name \
  --application-name jadelet --application-image $image \
  --target-host ${host_name} --node-name ${node_name} --container-port 8080 \
  --env-var-file ${env_file} 

# if [[ "$is_emulation" != "emulation" ]];then
#   service_name=`service_name ${is_emulation}`
#   port=`kubectl get service/${service_name} --namespace $namespace  --template='{{(index .spec.ports 0).nodePort}}'`
#   echo $node_name $port  
# fi