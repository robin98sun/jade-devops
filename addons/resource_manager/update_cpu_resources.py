#!/usr/bin/env python3

# https://github.com/rajibhossen/microservice-autoscaling


# modify cpu quota

def update_cpu_resources(resource_type, pod_path, value, period=100000):

    path = '/sys/fs/cgroup/cpu/' + pod_path

    if resource_type == "quota":
        path += '/cpu.cfs_quota_us'
    elif resource_type == "period":
        path += '/cpu.cfs_period_us'
    elif resource_type == "shares":
        path += '/cpu.shares'
    else:
        print(-999)
        return

    with open(path, 'r+') as f:
        data = f.read()
        f.seek(0)
        f.write(str(value))
        f.truncate()
        # verify
        f.seek(0)
        data = f.read()
        print(data)
        f.close()

if __name__ == "__main__":

    import argparse
    parser = argparse.ArgumentParser(description='update cpu quota for kubernetes pod')
    parser.add_argument('--type', type=str, help='the resource type to update')
    parser.add_argument('--path', type=str, help='the dir path of pod')
    parser.add_argument('--value', type=int, help='the new value of the resource')
    args = parser.parse_args()

    update_cpu_resources(args.type, args.path, args.value)

