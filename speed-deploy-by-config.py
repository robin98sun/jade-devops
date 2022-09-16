#!/usr/bin/env python3

import argparse
import json
import random
import sys
import os
import time

parser = argparse.ArgumentParser(description='Deploy JADE in Kubernetes environment, including K8S and K3S')
parser.add_argument(
    '--master', type=str, required=True,
    help='the json file for the master node'
)

parser.add_argument(
    '--agents', type=str, required=False, nargs="+",
    help='the json files for agent nodes'
)

parser.add_argument(
    '--registry', type=str, required=False,
    help='the json file for registry node'
)

parser.add_argument(
    '--env-dir', type=str, required=True,
    help='the directory for storing env files'
)

parser.add_argument(
    '--namespace', type=str, required=False, default='default',
    help='the k3s namespace'
)

parser.add_argument(
    '--protocol', type=str, required=False, default='http',
    help='the http for communication'
)

parser.add_argument(
    '--do-not-deploy', type=bool, required=False, default=False,
    help='do not do the deployment action'
)

parser.add_argument(
    '--delete', type=str, required=False, default="pods",
    help='delete existing pods or services or all or none'
)

parser.add_argument(
    '--version', type=str, required=True,
    help='the version of Jadelet in the image tag'
)

parser.add_argument(
    '--partial-deployment', type=str, required=False, default='all',
    choices=['master', 'agent', 'all'],
    help='to update configurations for master or agents or all of them, and do not perform fresh deployments for them'
)

parser.add_argument(
    '--group-name', type=str,
    help='group name for emulation'
)

parser.add_argument(
    '--is-emulation', action='store_true', default=False,
    help='if this deployment is an emulation'
)

args = parser.parse_args()


alphabet="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890"
def random_token(length):
    random.seed()
    token = ""
    for _ in range(length):
        token += alphabet[random.randint(0, len(alphabet)-1)]
    return token 

def update_version(image, version, isa):
    if version is None:
        return image
    result = image
    if ':' in image:
        start = image.index(':')
        result = image.replace(image[start:], ":"+version)
        result += "--" + isa
    else:
        result += ":" + version + "--" + isa

    return result

def gen_env(version, master_conf, agent_conf = None, registry_conf = None, token_of_master = None, token_of_agent = None, is_emulation = False):
    master = None
    master_name = None
    master_token = token_of_master
    if master_conf is not None:
        node_keys = list(master_conf["nodes"].keys())
        master_name = node_keys[0]
        master = master_conf["nodes"][master_name]

    if master_token is None:
        tmp_master_token = None
        if master_conf is not None and "token" in master_conf:
            tmp_master_token = master["token"]
        if tmp_master_token is not None:
            master_token = tmp_master_token
    if master_token is None:
        master_token = random_token(80)

    registry = None
    registry_name = None
    registry_token = None
    if registry_conf is not None:
        node_keys = list(registry_conf["nodes"].keys())
        registry_name  = node_keys[0]
        registry = registry_conf["nodes"][registry_name]
        registry_token = registry_conf["token"]

    if agent_conf is not None:
        for agent_name in agent_conf["nodes"].keys():
            agent = agent_conf["nodes"][agent_name]
            env_file = args.env_dir + '/' + agent_name + '.txt'
            content = []
            token = token_of_agent
            if token is None and "token" in agent_conf:
                token = agent_conf["token"]
            if token is None:
                token = random_token(80)

            content.append('JADE_JADELET_VERSION='+version)
            content.append('JADE_SELFNODE_TOKEN='+token)

            if not is_emulation:
                content.append('JADE_SELFNODE_SERVICEEXTERNAL=jadelet-'+agent_name.replace('_','-').replace('.','-')+'-service-external')
            else:
                content.append('JADE_SELFNODE_SERVICEEXTERNAL=emulation-'+agent_name.replace('_','-').replace('.','-')+'-service-external')

            content.append('JADE_SELFNODE_NAMESPACE='+args.namespace)
            content.append('JADE_SELFNODE_PROTOCOL='+args.protocol)
            content.append('JADE_SELFNODE_ADDRESS='+agent["address"])
            content.append('JADE_SELFNODE_HOSTNAME='+agent["hostname"])
            if "port" in agent:
                content.append('JADE_SELFNODE_PORT='+str(agent["port"]))

            if master is not None:
                content.append('JADE_UPPERNODE_PROTOCOL='+args.protocol)
                content.append('JADE_UPPERNODE_ADDRESS='+master["address"])
                content.append('JADE_UPPERNODE_HOSTNAME='+master["hostname"])
                content.append('JADE_UPPERNODE_TOKEN='+master_token)

                if not is_emulation:
                    content.append('JADE_UPPERNODE_SERVICEEXTERNAL=jadelet-'+master_name.replace('_','-').replace('.','-')+'-service-external')
                else:
                    content.append('JADE_UPPERNODE_SERVICEEXTERNAL=emulation-'+master_name.replace('_','-').replace('.','-')+'-service-external')

                content.append('JADE_UPPERNODE_NAMESPACE='+args.namespace)
                if "port" in master:
                    content.append('JADE_UPPERNODE_PORT='+str(master["port"]))

            if registry is not None:
                content.append('JADE_REGISTRY_PROTOCOL='+args.protocol)
                content.append('JADE_REGISTRY_ADDRESS='+registry["address"])
                content.append('JADE_REGISTRY_HOSTNAME='+registry["hostname"])
                content.append('JADE_REGISTRY_TOKEN='+registry_token)

                if not is_emulation:
                    content.append('JADE_REGISTRY_SERVICEEXTERNAL=jadelet-'+registry_name.replace('_','-').replace('.','-')+'-service-external')
                else:
                    content.append('JADE_REGISTRY_SERVICEEXTERNAL=jadelet-'+registry_name.replace('_','-').replace('.','-')+'-service-external')

                content.append('JADE_REGISTRY_NAMESPACE='+args.namespace)
                if "port" in registry:
                    content.append('JADE_REGISTRY_PORT='+str(registry["port"]))

            if "isa" in agent_conf:
                content.append('JADE_JADELET_ISA='+str(agent_conf["isa"]))
            if "capacity" in agent_conf:
                if "cpu" in agent_conf["capacity"]:
                    content.append('JADE_CAPACITY_CPU='+str(agent_conf["capacity"]["cpu"]))
                if "ram" in agent_conf["capacity"]:
                    content.append('JADE_CAPACITY_RAM='+str(agent_conf["capacity"]["ram"]))
                if "disk" in agent_conf["capacity"]:
                    content.append('JADE_CAPACITY_DISK='+str(agent_conf["capacity"]["disk"]))
                if "bandwidth" in agent_conf["capacity"]:
                    content.append('JADE_CAPACITY_BANDWIDTH='+str(agent_conf["capacity"]["bandwidth"]))

            if "capabilities" in agent_conf:
                for cap_type in agent_conf["capabilities"].keys():
                    idx = 0
                    for key in agent_conf["capabilities"][cap_type]:
                        content.append('JADE_CAPABILITY_'+cap_type.upper()+'_'+str(idx)+'_NAME='+key)
                        content.append('JADE_CAPABILITY_'+cap_type.upper()+'_'+str(idx)+'_API='+agent_conf["capabilities"][cap_type][key])
                        idx+=1

            with open(env_file, 'a') as f:
                for line in content:
                    f.write(line+"\n")

    if master is None:
        return master_token
    else:
        return None

# Read configurations
def read_json_file(filename):
    with open(filename) as f:
        conf = json.load(f)
    return conf

def emulate_config(conf):
    if args.is_emulation:
        if "nodes" in conf:
            new_nodes = {}
            for node_name in conf["nodes"]:
                new_node_name = None
                if args.group_name is not None:
                    new_node_name = "{}-{}-{}-{}-{}".format(node_name, args.group_name, str(int(time.time()*1000))[-10:], int(random.random()*1000), int(random.random()*1000))
                else:
                    new_node_name = "{}-{}-{}-{}".format(node_name, str(int(time.time()*1000))[-10:], int(random.random()*1000), int(random.random()*1000))

                new_node_name = new_node_name[0:32].replace(".", "-").replace("/", "-").replace(" ", "-")

                new_nodes[new_node_name] = {
                    "hostname": conf["nodes"][node_name]["hostname"],
                    "address": conf["nodes"][node_name]["address"],
                }
            conf["nodes"] = new_nodes
    return conf

master_conf = emulate_config(read_json_file(args.master))
agents = []
if args.agents is not None and len(args.agents) > 0:
    for agent in args.agents:
        agent_conf = emulate_config(read_json_file(agent))
        agents.append(agent_conf)

registry_conf = None
if args.registry is not None:
    registry_conf = read_json_file(args.registry)

# Generate environment files
# create env dir if needed
# if args.env_dir is not None:
#     os.system("mkdir -p "+args.env_dir)

master_token=gen_env(
                args.version, master_conf = None, agent_conf = master_conf, registry_conf = registry_conf,
                token_of_master = master_conf["token"], token_of_agent = master_conf["token"],
                is_emulation = args.is_emulation,
            )

for agent_conf in agents: 
    gen_env(args.version, master_conf, agent_conf, None, master_token, agent_conf["token"], is_emulation = args.is_emulation,)

# Deploy cluster
current_dir = os.path.dirname(os.path.abspath(__file__))
deploy_script = current_dir+'/speed-deploy.sh'
if os.path.exists(deploy_script):
    print("deploying:")
    if args.partial_deployment == 'all':
        agents.insert(0, master_conf)
    elif args.partial_deployment == 'master':
        agents = [master_conf]

    for conf in agents:
        if "nodes" in conf and "image" in conf and "isa" in conf:
            image = conf["image"]
            isa = conf["isa"]
            image = update_version(image, args.version, isa)
            for node in conf["nodes"]:
                cmd = deploy_script + ' ' + node + ' ' + image
                cmd += ' ' + args.env_dir + '/' + node + '.txt' 
                cmd += ' ' + args.namespace 
                if args.delete != "none":
                    cmd += ' ' + args.delete
                else:
                    cmd += ' none'

                if args.is_emulation:
                    cmd += ' emulation'
                else:
                    cmd += ' none'

                cmd += ' ' + conf["nodes"][node]["hostname"]

                print(cmd)
                if not args.do_not_deploy:
                    os.system(cmd)
