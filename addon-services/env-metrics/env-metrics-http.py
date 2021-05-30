#!/usr/bin/env python3

import argparse
import json
from flask import Flask, jsonify
from threading import Thread, Event
from time import sleep
import subprocess

parser = argparse.ArgumentParser(description='RESTful service for reading environment metrics')
parser.add_argument('--port', type=int, required=False, default=8765,
                      help='the port to listen')
args = parser.parse_args()

metrics_inst = {
    "TEMPERATURE": {
        "device": 0,
    },
    "CPU": {
        "us": 0,
        "sy": 0,
        "id": 0,
        "wa": 0,
        "st": 0,
    },
    "RAM": {
        "swpd": 0,
        "free": 0,
        "buffer": 0,
        "cache": 0,
    },
    "SWAP": {
        "si": 0,
        "so": 0,
    },
    "IO": {
        "bi": 0,
        "b0": 0,
    },
    "SYSTEM": {
        "in": 0,
        "cs": 0,
    },
    "PROCS": {
        "r": 0,
        "b": 0,
    }
}

def exec_cmd(cmd:str):
    try:
        command = cmd.split(" ")
        p = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout = p.stdout.read().decode("utf-8")
        stderr = p.stderr.read().decode("utf-8")
        retcode = p.wait()
        return stdout, stderr, retcode
    except Exception as e:
        return "", "", -999

def populate_vmstat(metrics):
    text, _, retcode = exec_cmd('vmstat 1 2')
    if retcode != 0:
        return

    vmstat = text.split("\n")[-2]
    stat_items = vmstat.split(" ")
    item_idx = 0
    for i in range(len(stat_items)):
        if stat_items[i] != "" and stat_items[i] != " ":
            if item_idx == 0:
                metrics["PROCS"]["r"] = int(stat_items[i])
            elif item_idx == 1:
                metrics["PROCS"]["b"] = int(stat_items[i])
            elif item_idx == 2:
                metrics["RAM"]["swpd"] = int(stat_items[i])
            elif item_idx == 3:
                metrics["RAM"]["free"] = int(stat_items[i])
            elif item_idx == 4:
                metrics["RAM"]["buffer"] = int(stat_items[i])
            elif item_idx == 5:
                metrics["RAM"]["cache"] = int(stat_items[i])
            elif item_idx == 6:
                metrics["SWAP"]["si"] = int(stat_items[i])
            elif item_idx == 7:
                metrics["SWAP"]["so"] = int(stat_items[i])
            elif item_idx == 8:
                metrics["IO"]["bi"] = int(stat_items[i])
            elif item_idx == 9:
                metrics["IO"]["bo"] = int(stat_items[i])
            elif item_idx == 10:
                metrics["SYSTEM"]["in"] = int(stat_items[i])
            elif item_idx == 11:
                metrics["SYSTEM"]["cs"] = int(stat_items[i])
            elif item_idx == 12:
                metrics["CPU"]["us"] = int(stat_items[i])
            elif item_idx == 13:
                metrics["CPU"]["sy"] = int(stat_items[i])
            elif item_idx == 14:
                metrics["CPU"]["id"] = int(stat_items[i])
            elif item_idx == 15:
                metrics["CPU"]["wa"] = int(stat_items[i])
            elif item_idx == 16:
                metrics["CPU"]["st"] = int(stat_items[i])
            item_idx += 1

def populate_temperatures(metrics):
    text, _, retcode = exec_cmd('sensors')
    if retcode == 0:
        metrics["TEMPERATURE"]["device"] = float(text.split('\n')[-3].split(" ")[-3].split("°")[0])
    else:
        text, err, retcode = exec_cmd('vcgencmd measure_temp')
        if retcode == 0:
            metrics["TEMPERATURE"]["device"] = float(text.split('\n')[-2].split("=")[-1].split("'")[0])

def read_metrics(metrics):
    while True:
        # vmstat - system & cpu & mem
        populate_vmstat(metrics)
        # temperature 
        populate_temperatures(metrics)
        sleep(1)

t = Thread(target=read_metrics, args=(metrics_inst, ))
t.start()


# RESTful service
app = Flask(__name__)

@app.route("/metrics", methods=["GET"])
def helloWorld():
    return jsonify(metrics_inst)

if __name__ == "__main__":
    app.run(port=args.port)
