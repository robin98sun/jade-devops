#!/usr/bin/env python3


# reference https://medium.com/@ramandumcs/cpu-throttling-unbundled-eae883e7e494


import os
import subprocess, shutil


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

def get_cpu_cores():
    return exec_single_value_cmd("cores", int, "cat /proc/cpuinfo|grep processor|wc -l|awk '{print $1}'")


def get_kube_overall_cpu_shares():
    return exec_single_value_cmd("shares", int, "cat /sys/fs/cgroup/cpu/kubepods/cpu.shares")


def get_kube_pods_shares(is_besteffort: bool = True):

    result = {
        "error": None,
    }

    base_dir = "/sys/fs/cgroup/cpu/kubepods"
    if is_besteffort:
        base_dir = "/sys/fs/cgroup/cpu/kubepods/besteffort"

    cmd = 'ls {dir}| grep pod | while read line; do shares=`cat {dir}/$line/cpu.shares|tail -1`; echo $line $shares; done'.format(dir = base_dir)

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
            if len(parts) == 2 and len(parts[0]) > 3:
                if "pods" not in result:
                    result["pods"] = []
                result["pods"].append({
                    "uid": parts[0][3:],
                    "share": int(parts[1]),
                    "type": pod_type,
                })

    return result


SUDO_PWD = 'abacus'
def update_kube_pod_cpu_quota(pod_uid: str, quota: int, is_besteffort: bool = True):
    dir_name = os.path.dirname(os.path.realpath(__file__))
    pod_path = "kubepods/"
    if is_besteffort:
        pod_path += "besteffort/"
    pod_path += "pod" + pod_uid

    # ref: https://github.com/rajibhossen/microservice-autoscaling
    cmd ='echo %s | sudo -S python3 %s/update_cpu_quota.py --path %s --quota %s' % (SUDO_PWD, dir_name, pod_path, quota)

    print("cmd for update kube pod cpu quota: " + cmd)

    result = exec_single_value_cmd("quota", int, cmd)

    return result











