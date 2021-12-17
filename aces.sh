#!/usr/bin/env bash

# this is only a batch script for building images on the cluster of lab
# password of docker-registry
cmd=$1
version=$2
registry=$3
password=$4
scheme=$5

if [[ "$scheme" == "" ]];then
    # scheme="scheme-1tier-ethernet16"
    # scheme="scheme-multi_tiers-ethernet16"
    # scheme="scheme-2tiers-ethernet16"
    scheme="scheme-2tiers-ethernet-partial"
fi
scheme_deployment_cmd="./jade-devops/deployments/lab/schemes/${scheme}/deployment.sh"

deployment_config_directory='ethernet-16'
master_host='aces-diamonds-ace.uta.edu'

if [[ "$cmd" != "reuse" && "$cmd" != "reboot-all" && "$cmd" != "reboot-cluster" && "$cmd" != "stop" && "$cmd" != "addon" ]];then
    # export version to modules
    for f in jade-go jade-ui/src jade-devops jade-devops jadesdk plankton jade-tests/sim-v3 jade-app-temp-hum; do
        echo '{ "version": "'${version}'" }' > ${f}/version.json
    done

    # git commit 
    rm -rf jade-go/app plankton/plankton jadelet.source.tar.gz jade-go/ui jade-app-temp-hum/jade-app

    echo "save source code to git repository"
    cd jade-go
    git add .
    git commit -m "version: $version"
    git tag -a v$version -m "version: $version"
    git push origin master

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

    cd ../jade-app-temp-hum
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
    tar czf jadelet.source.tar.gz jade-go jadesdk plankton jade-devops jade-tests/sim-v3 jade-app-temp-hum

    if [[ "$cmd" != "devops" ]];then
        cmd="build-and-push"
    fi
fi

if [[ "$cmd" != "reboot-all" && "$cmd" != "reboot-cluster" && "$cmd" != "stop" && "$cmd" != "addon" && "$cmd" != "devops" ]]; then
    echo "build on the remote servers"
    if [[ "$ccmd" != "devops" ]];then
        ./jade-devops/remote-build.sh \
            ${master_host} robin \
            aces-pi-44 pi \
            ./jadelet.source.tar.gz \
            $cmd \
            ${registry} "${version}--arm32" \
            ${password}
    fi

    remote_cmd="reuse"    
    if [[ "$cmd" == "devops" ]];then
        remote_cmd="save"
    fi
    ./jade-devops/remote-build.sh \
        none none \
        ${master_host} robin \
        ./jadelet.source.tar.gz \
        ${remote_cmd} \
        ${registry} "${version}--amd64" \
        ${password}
fi

if [[ "$cmd" == "devops" ]];then
    echo "DevOps has been copied to remote cluster"
    exit 0
fi

if [[ "$cmd" != "addon" ]];then
    echo "stop existing jade system and jade applications"
    ssh robin@${master_host} <<!
        # delete jade
        echo "kubectl get pods|grep jadelet|grep -v Terminating|awk '{print \$1}'|xargs kubectl delete pods"
        kubectl get pods|grep jade|awk '{print \$1}'|xargs kubectl delete pods --grace-period=0 --force
        # delete app pods
        echo "kubectl get deployments|grep app-jade|awk '{print \$1}'|xargs kubectl delete deployments"
        kubectl get deployments|grep jade|awk '{print \$1}'|xargs kubectl delete deployments --grace-period=0 --force
        # delete app services
        echo "kubectl get services|grep srv-app-jade|awk '{print \$1}'|xargs kubectl delete services"
        kubectl get services|grep srv-app-jade|awk '{print \$1}'|xargs kubectl delete services

        if [[ "$cmd" == "stop" ]];then
            exit 0
        fi

        if [[ "$cmd" != "addon" ]];then
            # deploy jade
            echo "deploying jade system, using scheme: ${scheme_deployment_cmd}"
            cd ~/Dev/src/jadelet
            chmod u+x ${scheme_deployment_cmd}
            ${scheme_deployment_cmd} ${version} ${deployment_config_directory}
        fi
!
fi

if [[ "$cmd" == "stop" || "$cmd" == "reboot-cluster" ]];then
    exit 0
fi

if [[ "$cmd" != "addon" && "$cmd" != "reboot-cluster" ]];then
    echo "copy jade-test to master node"
    # copy test scripts onto cluster
    scp ./jade-tests/sim-v3/*.py robin@${master_host}:~/sim-v3
    scp ./jade-tests/sim-v3/*.sh robin@${master_host}:~/sim-v3
    scp ./jade-tests/sim-v3/*.json robin@${master_host}:~/sim-v3
fi

if [[ "$cmd" == "addon" || "$cmd" == "new" || "$cmd" == "reboot-all" ]];then
    echo "deploy addons on master node"
    ./jade-devops/deploy-addons.sh robin ${master_host}
    echo ""
    for i in {1..4}; do
        for j in {1..4}; do
            echo "deploy addons on pi ${i}${j}"
            ./jade-devops/deploy-addons.sh pi aces-pi-${i}${j} 
            echo ""
        done
    done
fi
