#!/usr/bin/env bash

# this is only a batch script for building images on the devops-server of local VMs
version=$1
cmd=$2

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

    echo "building UI"
    cd ../jade-ui
    npm run build

    cd ..
    echo "packing source code"

    cp -r jade-ui/build jade-go/ui
    tar czf jadelet.source.tar.gz jade-go jadesdk plankton jade-devops

fi

# Build on the DevOps server and push to the local dorker registry
echo "build on the Devops server"
./jade-devops/remote-build.sh \
    none none \
    192.168.57.8 rin \
    ./jadelet.source.tar.gz \
    build-and-push \
    192.168.57.8 ${version}-amd64

# copy to cluster master node (to use the devops tools only, so no more buildings)
echo "copy to cluster master"
./jade-devops/remote-build.sh \
    none none \
    192.168.57.11 rin \
    ./jadelet.source.tar.gz \
    $cmd

# deploy on the cluster server
echo "deploy on the cluster master"

ssh -t rin@192.168.57.11 <<!
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
    --master ./jade-devops/deployments/vm/master-node.json \
    --agents ./jade-devops/deployments/vm/raspberry1.json \
             ./jade-devops/deployments/vm/raspberry2.json \
    --env-dir ./jade-devops/deployments/vm/env \
    --version ${version}
!