#!/usr/bin/env bash

# this is only a batch script for building images on the cluster of lab
# password of docker-registry
password=$1
version=$2
cmd=$3

if [[ "$cmd" != "reuse" ]];then
    rm -rf jade-go/app plankton/plankton jadelet.source.tar.gz jade-go/ui

    echo "save source code to git repository"
    cd jade-go
    git add .
    git commit -m "version: $version"
    git tag -a v$version -m "version: $version"
    git push private dev/robin

    cd ../jadesdk
    git add .
    git commit -m "version: $version"
    git tag -a v$version -m "version: $version"
    git push origin master

    cd ../plankton
    git add .
    git commit -m "version: $version"
    git tag -a v$version -m "version: $version"
    git push origin master

    cd ..
    echo "packing source code"
    cp -r jade-ui/build jade-go/ui
    tar czf jadelet.source.tar.gz jade-go jadesdk plankton jade-devops

fi

echo "build on the remote servers"
./jade-devops/remote-build.sh \
    aces-diamonds-ace robin \
    aces-pi-11 pi \
    ./jadelet.source.tar.gz \
    build-and-push \
    robin98 ${version}-arm32 \
    ${password}

./jade-devops/remote-build.sh \
    none none \
    aces-diamonds-ace robin \
    ./jadelet.source.tar.gz \
    reuse \
    robin98 ${version}-amd64 \
    ${password}

echo "deploy on the cluster master"
ssh robin@aces-diamonds-ace <<!
# delete jade
echo "kubectl get pods|grep jadelet|grep -v Terminating|awk '{print \$1}'|xargs kubectl delete pods"
kubectl get pods|grep jadelet|grep -v Terminating|awk '{print \$1}'|xargs kubectl delete pods
# delete app pods
echo "kubectl get deployments|grep app-jade|awk '{print \$1}'|xargs kubectl delete deployments"
kubectl get deployments|grep app-jade|awk '{print \$1}'|xargs kubectl delete deployments
# delete app services
echo "kubectl get services|grep srv-app-jade|awk '{print \$1}'|xargs kubectl delete services"
kubectl get services|grep srv-app-jade|awk '{print \$1}'|xargs kubectl delete services
# deploy jade
cd ~/Dev/src/jadelet
./jade-devops/speed-deploy-by-config.py \
    --master ./jade-devops/deployments/lab/ipaddr-version/master-node.json \
    --agents ./jade-devops/deployments/lab/ipaddr-version/agent-nodes-1.json \
             ./jade-devops/deployments/lab/ipaddr-version/agent-nodes-2.json \
             ./jade-devops/deployments/lab/ipaddr-version/agent-nodes-3.json \
    --env-dir ./jade-devops/deployments/lab/env \
    --version ${version}
!