#!/usr/bin/env bash

# this is only a batch script for building images on the cluster of lab
# password of docker-registry
cmd=$1
version=$2
registry=$3
password=$4
scheme=$5

if [[ "$scheme" == "" ]];then
    # scheme="scheme-1tier-ethernet32"
    # scheme="scheme-1tier-ethernet16"
    # scheme="scheme-multi_tiers-ethernet16"
    # scheme="scheme-2tiers-ethernet16"
    # scheme="scheme-2tiers-ethernet-partial"
    scheme="scheme-2tiers-4clusters-32pi-decentralized"
    # scheme="scheme-2tiers-1cluster-8pi"
fi
scheme_deployment_cmd="./jade-devops/deployments/lab/schemes/${scheme}/deployment.sh"

deployment_config_directory='ethernet-32'
master_host='aces-diamonds-ace.uta.edu'
isa_arm_host='aces-devpi-01'
test_util='test-framework'

if [[ "$version" != "" ]];then
    # export version to modules
    for f in jade-go jade-ui/src jade-devops jade-devops jadesdk plankton jade-tests/${test_util}/bin jade-tests/${test_util} jade-app-temp-hum; do
        echo "writing version number [$version] at $f "
        echo '{ "version": "'${version}'" }' > ${f}/version.json
    done
fi

if [[ "$cmd" != "reuse" && "$cmd" != "reboot-all" && "$cmd" != "reboot-cluster" && "$cmd" != "stop" && "$cmd" != "addon" && "$cmd" != "test-framework" ]];then

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

    # cd ../jade-doc
    # git add .
    # git commit -m "version: $version"
    # git tag -a v$version -m "version: $version"
    # git push origin master

    # cd ../jade-ui
    # git add .
    # git commit -m "version: $version"
    # git tag -a v$version -m "version: $version"
    # git push origin master  
    # echo "building UI"
    # npm run build

    cd ../jade-tests
    git add .
    git commit -m "version: $version"
    git tag -a v$version -m "version: $version"
    git push origin master

    cd ..
    echo "packing source code"

    cp -r jade-ui/build jade-go/ui 
    tar czf jadelet.source.tar.gz jade-go jadesdk plankton jade-devops jade-tests/${test_util} jade-app-temp-hum

    # if [[ "$cmd" != "devops" ]];then
    #     cmd="build-and-push"
    # fi
fi

if [[ "$cmd" != "reboot-all" && "$cmd" != "reboot-cluster" && "$cmd" != "stop" && "$cmd" != "addon" && "$cmd" != "devops" && "$cmd" != "test-framework" && "$cmd" != "save" ]]; then
    echo "build on the remote servers"
    if [[ "$cmd" != "devops" ]];then
        ./jade-devops/remote-build.sh \
            ${master_host} robin \
            ${isa_arm_host} pi \
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

if [[ "$cmd" == "save" ]];then
    echo "source code saved"
    exit 0
fi

if [[ "$cmd" != "addon" && "$cmd" != "test-framework" ]];then
    echo "stop existing jade system and jade applications"
    ssh robin@${master_host} <<!
        # delete app pods
        echo "kubectl get deployments|grep app-jade|awk '{print \$1}'|xargs kubectl delete deployments"
        kubectl get deployments|grep jade|awk '{print \$1}'|xargs kubectl delete deployments --grace-period=0 --force
        # delete jade
        echo "kubectl get pods|grep jadelet|grep -v Terminating|awk '{print \$1}'|xargs kubectl delete pods"
        kubectl get pods|grep jade|awk '{print \$1}'|xargs kubectl delete pods --grace-period=0 --force
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

if [[ "$cmd" == "stop" || "$cmd" == "reboot-cluster" || "$cmd" == "reboot-all" ]];then
    exit 0
fi

if [[ "$cmd" != "addon" && "$cmd" != "reboot-cluster" || "$cmd" == "test-framework" ]];then
    # copy test scripts onto cluster
    echo "copy ${test_util} to cluster nodes"
    ssh robin@${master_host} <<!
        echo "updating ${test_util} on ${master_host}"
        if [[ -d ./${test_util} || -f ./${test_util} ]];then
            rm -rf ./${test_util}
        fi

        if [[ ! -d ./test-data ]]; then
            mkdir ./test-data
        fi
!
    scp -r ./jade-tests/${test_util} robin@${master_host}:~/${test_util}
    
    for i in {1..4}; do
        host=aces-cluster-0${i}
ssh robin@${host} <<!
        echo "updating ${test_util} on ${host}"
        if [[ -d ./${test_util} || -f ./${test_util} ]];then
            rm -rf ./${test_util}
        fi
!
        scp -r ./jade-tests/${test_util} robin@${host}:~/${test_util}
    done

    if [[ ! -d ./test-data ]]; then
        mkdir ./test-data
    fi
fi

if [[  "$cmd" == "build-and-push" || "$cmd" == "addon" || "$cmd" == "reboot-all" ]];then
    echo "deploy addons on master node"
    ./jade-devops/deploy-addons.sh robin ${master_host}
    echo ""
    for i in {1..4}; do
        for j in {1..4}; do
            echo "deploy addons on pi ${i}${j}"
            ./jade-devops/deploy-addons.sh pi aces-pi-${i}${j}.uta.edu 
            echo ""
        done
    done


    for i in {5..6}; do
        for j in {0..7}; do
            echo "deploy addons on pi ${i}${j}"
            ./jade-devops/deploy-addons.sh pi aces-pi-${i}${j}.uta.edu 
            echo ""
        done
    done

    for i in {1..4}; do
        echo "deploy addons on cluster ${j}"
        ./jade-devops/deploy-addons.sh robin aces-cluster-0${i}.uta.edu 
        echo ""
    done
fi
