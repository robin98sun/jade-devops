#!/usr/bin/env bash

# this is only a batch script for building images on the cluster of lab
# password of docker-registry
registry=$1
password=$2
version=$3
cmd=$4

if [[ "$cmd" != "reuse" ]];then
    # export version to modules
    for f in jade-go jade-ui/src jade-devops jade-devops jadesdk plankton jade-tests/sim-v2; do
        echo '{ "version": "'${version}'" }' > ${f}/version.json
    done

    # git commit 
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

    cd ../jade-devops
    git add .
    git commit -m "version: $version"
    git tag -a v$version -m "version: $version"
    git push origin master

    cd ../jade-doc
    git add .
    git commit -m "version: $version"
    git tag -a v$version -m "version: $version"
    git push origin master

    cd ../jade-ui
    git add .
    git commit -m "version: $version"
    git tag -a v$version -m "version: $version"
    git push origin master
    
    echo "building UI"
    npm run build

    cd ../jade-tests
    git add .
    git commit -m "version: $version"
    git tag -a v$version -m "version: $version"
    git push origin master

    cd ..
    echo "packing source code"

    cp -r jade-ui/build jade-go/ui 
    tar czf jadelet.source.tar.gz jade-go jadesdk plankton jade-devops jade-tests/sim-v2

fi

echo "build on the remote servers"
if [[ "$cmd" != "reuse" ]]; then
    cmd="build-and-push"
fi

./jade-devops/remote-build.sh \
    aces-diamonds-ace robin \
    aces-pi-11 pi \
    ./jadelet.source.tar.gz \
    $cmd \
    ${registry} ${version}-arm32 \
    ${password}

./jade-devops/remote-build.sh \
    none none \
    aces-diamonds-ace robin \
    ./jadelet.source.tar.gz \
    reuse \
    ${registry} ${version}-amd64 \
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
    --master ./jade-devops/deployments/lab/ipaddr-version-16/master-node.json \
    --agents ./jade-devops/deployments/lab/ipaddr-version-16/agent-nodes-1.1.json \
             ./jade-devops/deployments/lab/ipaddr-version-16/agent-nodes-1.2.json \
             ./jade-devops/deployments/lab/ipaddr-version-16/agent-nodes-1.3.json \
             ./jade-devops/deployments/lab/ipaddr-version-16/agent-nodes-1.4.json \
             ./jade-devops/deployments/lab/ipaddr-version-16/agent-nodes-2.1.json \
             ./jade-devops/deployments/lab/ipaddr-version-16/agent-nodes-2.2.json \
             ./jade-devops/deployments/lab/ipaddr-version-16/agent-nodes-2.3.json \
             ./jade-devops/deployments/lab/ipaddr-version-16/agent-nodes-2.4.json \
             ./jade-devops/deployments/lab/ipaddr-version-16/agent-nodes-3.1.json \
             ./jade-devops/deployments/lab/ipaddr-version-16/agent-nodes-3.2.json \
             ./jade-devops/deployments/lab/ipaddr-version-16/agent-nodes-3.3.json \
             ./jade-devops/deployments/lab/ipaddr-version-16/agent-nodes-3.4.json \
             ./jade-devops/deployments/lab/ipaddr-version-16/agent-nodes-4.1.json \
             ./jade-devops/deployments/lab/ipaddr-version-16/agent-nodes-4.2.json \
             ./jade-devops/deployments/lab/ipaddr-version-16/agent-nodes-4.3.json \
             ./jade-devops/deployments/lab/ipaddr-version-16/agent-nodes-4.4.json \
    --env-dir ./jade-devops/deployments/lab/env \
    --version ${version}
!


# copy test scripts onto cluster
mv ./jade-tests/sim-v2/traces ./jade-tests/
scp -r ./jade-tests/sim-v2 robin@aces-diamonds-ace:~/
mv ./jade-tests/traces ./jade-tests/sim-v2/traces