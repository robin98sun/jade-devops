#!/usr/bin/env python3


# reference https://medium.com/@ramandumcs/cpu-throttling-unbundled-eae883e7e494


import os
import subprocess, shutil
import json

DEFAULT_PASSWD = 'abacus'

# utility functions
def exec(cmd, verbose=False, stdout=None, stderr=None):
    if verbose:
        print(cmd)

    stdout_target = stdout
    stderr_target = stderr
    if stdout is None:
        stdout_target = subprocess.PIPE
    if stderr is None:
        stderr_target = subprocess.PIPE
    process = subprocess.Popen(
                     cmd,
                     stdout = stdout_target, 
                     stderr = stderr_target,
                     shell  = True,
               )
    
    stdout_output, stderr_output = process.communicate()

    if type(stdout_output) == bytes:
        stdout_output = stdout_output.decode("utf-8")
    if type(stderr_output) == bytes:
        stderr_output = stderr_output.decode("utf-8")
    if verbose:
        if stdout_output != "":
            print(stdout_output)
        if stderr_output != "":
            print("ERROR:", stderr_output)

    if stdout_output is not None and stdout_output != "":
        stdout_output = stdout_output.strip()

    return stdout_output, stderr_output


def exec_single_value_cmd(key, data_type, cmd):
    result = {
        "error": None,
    }
    result[key] = None

    stdout, stderr = exec(cmd)

    if stderr is not None and stderr != "":
        result["error"] = stderr
    if stdout is not None and stdout != "":
        result[key] = data_type(stdout)

    return result

def get_cpu_architecture():
    text, err = exec('lscpu -J')
    if err != None:
        return None

    cpu_info = json.loads(text)
    if "lscpu" in cpu_info:
        for item in cpu_info["lscpu"]:
            if "field" in item and "data" in item:
                if item["field"] == "Architecture:":
                    return item["data"]
    return None

def get_cpu_architecture():
    text, err = exec('lscpu -J')
    if err != None and err != "":
        return text, err
    
    cpu_info = json.loads(text)
    if "lscpu" in cpu_info:
        for item in cpu_info["lscpu"]:
            if "field" in item and "data" in item:
                if item["field"] == "Architecture:":
                    return item["data"], None
    return None, 'lscpu is not found'

# raspberry pi cpu frequency scaling
# ref: https://forums.raspberrypi.com/viewtopic.php?t=152692
# be sure to remove 'force_turbo=1' in the file '/boot/config.txt' for the pi device and reboot to make its CPU frequency scalable if there was the line
def get_scalable_cpu_freq(prop):
    result = {
        "error": "unsupported",
    }

    arch, err = get_cpu_architecture()
    if err is not None:
        result["error"] = err
        result["arch"] = arch
        return result
    elif arch is None or "arm" not in arch:
        result["arch"] = arch
        return result

    cmd = None
    if prop == "freq-cur":
        cmd = "sudo cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq"
    elif prop == "freq-min":
        cmd = "sudo cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq"
    elif prop == "freq-max":
        cmd = "sudo cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq"
    elif prop == "is-scalable":
        cmd = "cat /boot/config.txt|grep -i 'force_turbo=1'|grep -v '\#'|wc -l|awk '{print $1}'"
    if cmd is None:
        result["prop"] = prop
        return result

    result[prop] = 0

    result = exec_single_value_cmd(prop, int, cmd)
    if prop == "is-scalable":
        if prop in result:
            if result[prop] == 0:
                result[prop] = True
            else:
                result[prop] = False
    elif prop in result:
        result[prop] = result[prop]/1000
    
    return result

# echo "powersave"| sudo tee /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
def update_scalable_cpu_freq(freq, passwd=None):
    result = {
        "error": "unsupported",
    }    
    arch, err = get_cpu_architecture()
    if err is not None:
        result["error"] = err
        result["arch"] = arch
        return result
    elif arch is None or "arm" not in arch:
        result["arch"] = arch
        return result

    freq_in_file = freq
    if freq < 10000:
        freq_in_file = freq*1000

    dir_name = os.path.dirname(os.path.realpath(__file__))
    sudo_passwd = passwd
    if passwd is None or passwd == "":
        sudo_passwd = DEFAULT_PASSWD

    for scale in ["min", "max"]:

        # ref: https://github.com/rajibhossen/microservice-autoscaling
        cmd ='echo %s | sudo -S python3 %s/update_cpu_frequency_raspberry_pi.py --type %s --value %s' % (sudo_passwd, dir_name, scale, freq_in_file)

        result = exec_single_value_cmd("value", int, cmd)

        if "error" in result and result["error"] is not None:
            return result

    return get_scalable_cpu_freq("freq-cur")





# general cpu resource based on cgroup
def get_cpu_cores():
    return exec_single_value_cmd("cores", int, "cat /proc/cpuinfo|grep processor|wc -l|awk '{print $1}'")


def get_kube_overall_cpu_shares():
    return exec_single_value_cmd("shares", int, "cat /sys/fs/cgroup/cpu/kubepods/cpu.shares")


def get_kube_pods_cgroup_cpu_info(is_besteffort: bool = True):
    result = {
        "error": None,
    }

    base_dir = "/sys/fs/cgroup/cpu/kubepods"
    if is_besteffort:
        base_dir = "/sys/fs/cgroup/cpu/kubepods/besteffort"

    cmd = "ls {dir}| grep pod | while read line; do \
                shares=`cat {dir}/$line/cpu.shares|tail -1`; \
                period=`cat {dir}/$line/cpu.cfs_period_us|tail -1`; \
                quota=`cat {dir}/$line/cpu.cfs_quota_us|tail -1`; \
                nr_period=`cat {dir}/$line/cpu.stat|grep nr_period|tail -1|awk '{{print $2}}'`; \
                nr_throttled=`cat {dir}/$line/cpu.stat|grep nr_throttled|tail -1|awk '{{print $2}}'`; \
                throttled_time=`cat {dir}/$line/cpu.stat|grep throttled_time|tail -1|awk '{{print $2}}'`; \
                echo $line $shares $period $quota $nr_period $nr_throttled $throttled_time; \
            done".format(dir = base_dir)

    stdout, stderr = exec(cmd)

    pod_type = "fixed"
    if is_besteffort:
        pod_type = "besteffort"

    if stderr is not None and stderr != "":
        result["error"] = stderr
    elif stdout is not None and stdout != "":
        lines = stdout.splitlines()
        for line in lines:
            parts = line.split(" ")
            if len(parts) == 7 and len(parts[0]) > 3:
                if "pods" not in result:
                    result["pods"] = []
                result["pods"].append({
                    "uid": parts[0][3:],
                    "type": pod_type,
                    "shares": int(parts[1]),
                    "period": int(parts[2]),
                    "quota": int(parts[3]),
                    "nr_period": int(parts[4]),
                    "nr_throttled": int(parts[5]),
                    "throttled_time": int(parts[6]),
                })

    return result


def get_kube_all_pods_cgroup_cpu_info():
    result_fixed = get_kube_pods_cgroup_cpu_info(is_besteffort = False)
    result_besteffort = get_kube_pods_cgroup_cpu_info(is_besteffort = True)

    result = {
        "error": None,
        "pods": {},
    }
    if result_fixed["error"] is not None:
        result["error"] = result_fixed["error"]
    elif result_besteffort["error"] is not None:
        result["error"] = result_besteffort["error"]
    else:
        for result_set in [result_fixed, result_besteffort]:
            if result_set is not None and "pods" in result_set:
                for pod in result_set["pods"]:
                    result["pods"][pod["uid"]] = pod

    return result

def get_pod_cgroup_cpu_path(pod_uid, is_besteffort):
    pod_path = "kubepods/"
    if is_besteffort:
        pod_path += "besteffort/"
    pod_path += "pod" + pod_uid
    return pod_path

def get_kube_pod_cgroup_cpu_resource(resource_type:str, pod_uid: str, is_besteffort: bool = True):
    pod_path = get_pod_cgroup_cpu_path(pod_uid, is_besteffort)
    cmd = "cat /sys/fs/cgroup/cpu/"+pod_path
    if resource_type == "quota":
        cmd+="/cpu.cfs_quota_us"
    elif resource_type == "period":
        cmd+="/cpu.cfs_period_us"
    elif resource_type == "shares":
        cmd+="/cpu.shares"
    else:
        return {
            "error": "unsupported resource type: "+resource_type,
        }

    return exec_single_value_cmd("value", int, cmd)


def update_kube_pod_cgroup_cpu_resource(resource_type: str, pod_uid: str, value: int, is_besteffort: bool = True, passwd:str = None):
    dir_name = os.path.dirname(os.path.realpath(__file__))
    pod_path = get_pod_cgroup_cpu_path(pod_uid, is_besteffort)

    sudo_passwd = passwd
    if passwd is None or passwd == "":
        sudo_passwd = DEFAULT_PASSWD

    # ref: https://github.com/rajibhossen/microservice-autoscaling
    cmd ='echo %s | sudo -S python3 %s/update_cpu_resources.py --type %s --path %s --value %s' % (sudo_passwd, dir_name, resource_type, pod_path, value)

    result = exec_single_value_cmd("value", int, cmd)

    return result











