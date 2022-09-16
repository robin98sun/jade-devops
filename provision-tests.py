#!/usr/bin/env python3

import math
import os
import sys
import json
import time
import subprocess
from random import random
import requests


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
    return stdout_output, stderr_output


def clear_deployments():
    start_time = time.time()
    cmd = "kubectl get deployments|grep jade|awk '{print $1}'|xargs kubectl delete deployments --grace-period=0"
    exec(cmd)

    cmd = "kubectl get pods|grep jade|awk '{print $1}'|xargs kubectl delete pods --grace-period=0"
    exec(cmd)

    cmd = "kubectl get services|grep srv|grep jade-app|awk '{print $1}'|xargs kubectl delete services"
    exec(cmd)
    dur = end_time - start_time
    print("deployment is cleared in {} seconds".format(dur))

    return dur



def deploy(deploy_type: str, version: str):
    curr_dir = os.path.dirname(os.path.realpath(__file__))
    host_dir='ethernet-36-nolimit'
    scheme="scheme-2tiers-4clusters-32pi-decentralized"
    deployment_cmd="{}/deployments/lab/schemes/{}/deploy-{}.sh {} {}".format(
        curr_dir, deploy_type, scheme, version, host_dir,
    )

    start_time = time.time()

    log_file = './provision-tests-deploy-{}.log'.format(deploy_type)
    err_file = './provision-tests-deploy-{}.err'.format(deploy_type)
    with open (err_file, 'a') as ef, open(log_file, 'a') as of:
        stdout, stderr = exec(deployment_cmd, stdout=of, stderr=ef)
    if stderr is not None and stderr != "":
        print("ERROR when deploying:", stderr)
    elif args.verbose:
        print("[DONE] deployment of {} is done".format(deploy_type))

    end_time = time.time()

    dur = end_time - start_time

    print("deployment is done in {} seconds".format(dur))

    return dur


if __name__ == "__main__":
    

    curr_dir = os.path.dirname(os.path.realpath(__file__))

    with open(curr_dir+'/version.json', 'r') as f:
        version = json.load(f)["version"]

    print("jade version: {}".format(version))


    import argparse
    parser = argparse.ArgumentParser(description='generate jobs according to the configuration file')

    parser.add_argument(
        '--action', type=str, required=True, choices=['clear', 'registry', 'clusters'],
        help='what action to do'
    )

    args = parser.parse_args()


    if args.action == 'clear':
        clear_deployments()
    else:
        deploy(args.action, version)


