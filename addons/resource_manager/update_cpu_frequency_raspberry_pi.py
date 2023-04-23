#!/usr/bin/env python3

# https://github.com/rajibhossen/microservice-autoscaling


# modify raspberry pi cpu frequency 

def update_raspberry_pi_cpu_frequency(scale_type, value, set_scalable = False, set_unscalable = False):

    path = '/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq'

    if scale_type == "max":
        path = '/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq'
    elif scale_type != "min":
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
    parser = argparse.ArgumentParser(description='update raspberry pi cpu frequency')
    parser.add_argument('--type', type=str, choices=['min', 'max'], help='min or max')
    parser.add_argument('--value', type=int, help='the new frequency value')
    parser.add_argument('--set-scalable', action='store_true', help='set the device to scalable and reboot')
    parser.add_argument('--set-unscalable', action='store_true', help='set the device to unscalable and reboot')
    args = parser.parse_args()

    update_raspberry_pi_cpu_frequency(args.type, args.value, args.set_scalable, args.set_unscalable)
