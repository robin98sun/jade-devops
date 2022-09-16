#!/usr/bin/env python3

import math
import os
import sys
import json
import time
import subprocess
from random import random
import requests
import multiprocessing


def clear_deployments():
    start_time = time.time()
    cmd = "kubectl get deployments|grep jade|awk '{print $1}'|xargs kubectl delete deployments --grace-period=0 --force"
    subprocess.run(cmd, shell=True, check=False)

    cmd = "kubectl get pods|grep jade|awk '{print $1}'|xargs kubectl delete pods --grace-period=0 --force"
    subprocess.run(cmd, shell=True, check=False)

    cmd = "kubectl get pods|grep emulation|awk '{print $1}'|xargs kubectl delete pods --grace-period=0 --force"
    subprocess.run(cmd, shell=True, check=False)

    cmd = "kubectl get services|grep jade-app|awk '{print $1}'|xargs kubectl delete services --force"
    subprocess.run(cmd, shell=True, check=False)

    cmd = "kubectl get services|grep emulation|awk '{print $1}'|xargs kubectl delete services --force"
    subprocess.run(cmd, shell=True, check=False)

    end_time = time.time()
    dur = end_time - start_time
    print("deployment is cleared in {} seconds".format(dur))

    return dur



def deploy(deploy_type: str, version: str, is_emulation: bool = True, group = None):
    curr_dir = os.path.dirname(os.path.realpath(__file__))
    host_dir='ethernet-36-nolimit'
    scheme="scheme-2tiers-4clusters-32pi-decentralized"
    script_name = "deploy-{}.sh".format(deploy_type)
    emulation = "" 
    if is_emulation:
        emulation = "emulation"
    group_name = ""
    if group is not None:
        group_name = group
    deployment_cmd="{}/deployments/lab/schemes/{}/{} {} {} {} {} {}".format(
        curr_dir, scheme, script_name, version, host_dir, curr_dir, emulation, group_name,
    )

    print("cmd: {}".format(deployment_cmd))
    # subprocess.Popen(deployment_cmd, stdout = subprocess.PIPE, stderr = subprocess.PIPE, shell = True)
    process = subprocess.run(deployment_cmd, shell=True, check=True)

    return process


if __name__ == "__main__":
    
    curr_dir = os.path.dirname(os.path.realpath(__file__))

    with open(curr_dir+'/version.json', 'r') as f:
        json_obj = json.load(f)
        version = json_obj["version"]
        if "branch" in json_obj:
            branch = json_obj["branch"]
            if branch != "master":
                version="{}-{}".format(branch, version).replace("/", "-").replace(" ", "-")

    print("jade version: {}".format(version))


    import argparse
    parser = argparse.ArgumentParser(description='generate jobs according to the configuration file')

    parser.add_argument(
        '--action', type=str, required=True, choices=[
            'try', 'full', 'ad-only', 'clear', 'registry', 
            'clusters', 'cluster01', 'cluster02', 'cluster03', 'cluster04',
        ],
        help='what action to do'
    )

    parser.add_argument(
        '--is-emulation', action='store_true', default=True,
        help='if it is emulation'
    )

    parser.add_argument(
        '--rounds', type=int, default=True,
        help='how many rounds create the emulated pods'
    )

    args = parser.parse_args()


    if args.action == 'clear':
        clear_deployments()
    elif args.action == 'full':
        # deploy('registry', version, is_emulation = False)
        # for i in range(10):
        #     deploy('cluster04', version, is_emulation = True)

        # for i in range(100):
        #     deploy('cluster03', version, is_emulation = True)

        # for i in range(100):
        #     deploy('cluster02', version, is_emulation = True)

        # for i in range(50):
        #     deploy('cluster01', version, is_emulation = True)

        pass

    elif args.action == 'ad-only':

        # deploy('registry', version, is_emulation = False)
        start_time = time.time()
        def deploy_process(i):
            group_name = "g{}".format(i)
            # deploy('ad-only', version, is_emulation = True, group = group_name)
            deploy('ad-only', version, is_emulation = True)

        p = multiprocessing.Pool(multiprocessing.cpu_count())

        rounds = 100
        if args.rounds is not None:
            rounds = args.rounds
        processes = p.map(deploy_process, range(rounds))

        end_time = time.time()
        dur = round(end_time - start_time,1)
        print("deployed {} pods in {} seconds".format(len(processes)*4, dur))


    else:
        deploy(args.action, version, is_emulation = args.is_emulation)


