#!/usr/bin/env python3

# https://github.com/rajibhossen/microservice-autoscaling


# modify cpu quota

def update_cpu_quota(pod_path, value, period=100000):

    path = '/sys/fs/cgroup/cpu/' + pod_path + '/cpu.cfs_quota_us'

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
    parser = argparse.ArgumentParser(description='RESTful service for reading environment metrics')
    parser.add_argument('--path', type=str, help='the dir path of pod')
    parser.add_argument('--quota', type=int, help='the cpu quota of pod')
    args = parser.parse_args()

    update_cpu_quota(args.path, args.quota)

