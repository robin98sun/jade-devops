#!/usr/bin/env bash

target_user=$1
target_host=$2

cmd=$3
if [[ "$cmd" == "" ]];then
    cmd=rebuild
fi

target_dir=$4
if [[ "$target_dir" == "" ]];then
    target_dir="~/jade-addons"
fi

port=8765

if [[ "$target_user" == "" || "$target_host" == "" ]];then
    echo "==>Unknown target host or user"
fi

# create work dir
if [[ "$cmd" == "rebuild" ]];then
    echo "==>create work dir on target host"
    ssh ${target_user}@${target_host} << !
        if [[ -d $target_dir ]];then
            rm -rf $target_dir
        fi
        mkdir -p ${target_dir}/logs
!
fi

# copy addons
if [[ "$cmd" == "rebuild" ]];then
    echo "==>copy addon scripts"
    scp -r ./jade-devops/addons/* ${target_user}@${target_host}:${target_dir}
fi

# start addon services
if [[ "$cmd" == "rebuild" || "$cmd" == "restart" ]];then
    ssh ${target_user}@${target_host} << !
        function start_addon() {
            addon_name=\$1
            addon_script=\$2
            addon_log_dir=\$3
            
            echo "---->addon name: \${addon_name}"
            echo "---->addon script: \${addon_script}"
            echo "---->addon log dir: \${addon_log_dir}"
            if [[ ! -f \${addon_script} ]];then
                echo "---->addon script [\${addon_script}] does not exist"
                return
            fi
            chmod u+x \${addon_script}

            if [[ `ps -ef | grep -e "\${addon_name}" | grep -v "grep" |wc -l|awk '{print \$1}'` -gt 0 ]];then
                echo "stopping" `ps -ef | grep -e "\${addon_name}" | grep -v "grep" |wc -l|awk '{print \$1}'` "addones"
                ps -ef | grep -e "\${addon_name}" | grep -v "grep" 
                echo ""
                echo "---->stop existing addon script [\${addon_name}]"
                ps -ef | grep -e "\${addon_name}" | grep -v "grep" | awk '{print \$2}'|xargs kill -9
            fi
            echo "---->start addon scripts [\${addon_name}]"
            nohup \${addon_script} --port ${port} > \${addon_log_dir}/\${addon_name}.log 2>&1 &
            echo "---->done [\${addon_name}]"
        }

        start_addon metrics-env ${target_dir}/metrics-env/metrics-env-http.py ${target_dir}/logs 
!
fi
