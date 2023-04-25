#!/usr/bin/env  bash

item=mem

if [[ "$1" != "" ]];then
    item=$1
fi

cmd="cat /sys/fs/cgroup/cpu/cpuacct.usage"
if [[ "$item" == cpu ]];then
    cmd="cat /sys/fs/cgroup/cpu/cpuacct.usage"
elif [[ "$item" == mem ]];then
    cmd="cat /sys/fs/cgroup/memory/memory.usage_in_bytes|awk '{print \$1/1024/1024}'"
fi


kubectl get pods|sed '1d'|awk '{print $1}'|while read pod; do
    echo $pod
    
    kubectl exec -it $pod -n default -- /bin/bash <<!

    $cmd

!
    
    echo ""
done
