#!/usr/bin/env bash

# this is only a batch script for building images on the cluster of lab
# password of docker-registry
cmd=$1
branch=$2
version=$3
registry=$4
password=$5
scheme=$6

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

if [[ "$version" != "" && "$branch" == "master" ]];then
    # export version to modules
    for f in jade-go jade-ui/src jade-devops jade-devops jadesdk plankton jade-tests/${test_util}/bin jade-tests/${test_util} jade-app-temp-hum; do
        echo "writing version number [$version] at $f "
        echo '{ "version": "'${version}'" }' > ${f}/version.json
    done
fi


function check_git_branch_exist() {
    git_branch_check=$1
    if [[ "$git_branch_check" == "" ]];then
        echo 0
    fi

    git branch |grep "$git_branch_check"|wc -l|awk '{print $1}'
}

function get_current_git_branch() {
    git branch |grep "*"|awk '{if (NF>1 && $1=="*"){print $2}}'
}

function git_save_branch() {
    git_branch_save=$1
    comments=$2

    git add .
    git commit -m "$comments"
    git tag -a "v$comments" -m "version: $comments"
    git push origin "$git_branch_save"
}

function git_save() {
    target_branch=$1
    comment_version=$2

    pwd
    echo "going to save source code to branch $target_branch"

    curr_branch=`get_current_git_branch`

    if [[ "$curr_branch" != "$target_branch" ]];then
        echo "saving branch $curr_branch before checking out branch $target_branch"
        git_save_branch "$curr_branch" "$comment_version"

        if [[ `check_git_branch_exist $target_branch` -eq 0 ]];then
            echo "checking out new branch $target_branch"
            git checkout -b $target_branch
        else
            echo "checking out existing branch $target_branch"
            git checkout $target_branch
        fi
    fi


    echo "merging from previous branch $curr_branch to $target_branch"
    git merge "$curr_branch"

    echo "saving branch $target_branch"
    git_save_branch "$target_branch" "$comment_version"

    echo ""

}

function git_goto() {
    target_branch=$1
    comment_version=$2


}


if [[ "$cmd" == "new" || "$cmd" == "save" || "$cmd" == "goto" ]];then

    # git commit 
    rm -rf jade-go/app plankton/plankton jadelet.source.tar.gz jade-go/ui jade-app-temp-hum/jade-app

    echo "save source code to git repository"
    cd jade-go
    if [[ "$cmd" == "goto" ]];then
        git_goto $branch $version
    else
        git_save $branch $version
    fi

    cd ../jadesdk
    if [[ "$cmd" == "goto" ]];then
        git_goto $branch $version
    else
        git_save $branch $version
    fi

    cd ../plankton
    if [[ "$cmd" == "goto" ]];then
        git_goto $branch $version
    else
        git_save $branch $version
    fi

    cd ../jade-app-temp-hum
    if [[ "$cmd" == "goto" ]];then
        git_goto $branch $version
    else
        git_save $branch $version
    fi

    cd ../jade-devops
    if [[ "$cmd" == "goto" ]];then
        git_goto $branch $version
    else
        git_save $branch $version
    fi

    # cd ../jade-doc
    # if [[ "$cmd" == "goto" ]];then
    #     git_goto $branch $version
    # else
    #     git_save $branch $version
    # fi

    # cd ../jade-ui
    # if [[ "$cmd" == "goto" ]];then
    #     git_goto $branch $version
    # else
    #     git_save $branch $version
    # fi
    # echo "building UI"
    # npm run build

    cd ../jade-tests
    if [[ "$cmd" == "goto" ]];then
        git_goto $branch $version
    else
        git_save $branch $version
    fi

    cd ..
    echo "packing source code"

    cp -r jade-ui/build jade-go/ui 
    tar czf jadelet.source.tar.gz jade-go jadesdk plankton jade-devops jade-tests/${test_util} jade-app-temp-hum

fi

if [[ "$cmd" == "save" ]];then
    echo "source code saved"
    exit 0
fi

if [[ "$branch" != "master" ]];then
    version=`echo "${branch}-${version}" | tr "/" "-" | tr " " "-"`
fi

if [[ "$cmd" == "new" ]];then
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

if [[ "$cmd" == "stop" || "$cmd" == "new" || "$cmd" == "reboot" || "$cmd" == "restart" ]];then
    echo "stop existing jade system and jade applications"
    ssh robin@${master_host} <<!
        # delete app pods
        echo "kubectl get deployments|grep app-jade|awk '{print \$1}'|xargs kubectl delete deployments"
        #kubectl get deployments|grep jade|awk '{print \$1}'|xargs kubectl delete deployments --grace-period=0 --force
        kubectl get deployments|grep jade|awk '{print \$1}'|xargs kubectl delete deployments --grace-period=0 
        # delete jade
        echo "kubectl get pods|grep jadelet|grep -v Terminating|awk '{print \$1}'|xargs kubectl delete pods"
        #kubectl get pods|grep jade|awk '{print \$1}'|xargs kubectl delete pods --grace-period=0 --force
        kubectl get pods|grep jade|awk '{print \$1}'|xargs kubectl delete pods --grace-period=0 
        # delete app services
        echo "kubectl get services|grep srv|grep "-jade-app-"|awk '{print \$1}'|xargs kubectl delete services"
        kubectl get services|grep srv-app-jade|awk '{print \$1}'|xargs kubectl delete services

        if [[ "$cmd" == "stop" ]];then
            exit 0
        fi

        # deploy jade
        echo "deploying jade system, using scheme: ${scheme_deployment_cmd}"
        cd ~/Dev/src/jadelet
        chmod u+x ${scheme_deployment_cmd}
        ${scheme_deployment_cmd} ${version} ${deployment_config_directory}
!
fi

if [[ "$cmd" == "stop" ]];then
    exit 0
fi

if [[  "$cmd" == "new" || "$cmd" == "addon" || "$cmd" == "reboot" || "$cmd" == "restart" ]];then
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

if [[ "$cmd" == "reboot" || "$cmd" == "restart" || "$cmd" == "addon" ]];then
    exit 0
fi

if [[ "$cmd" == "new" || "$cmd" == "test-framework" ]];then
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


