#!/usr/bin/env python3
from flask import Flask, jsonify, request
import argparse
parser = argparse.ArgumentParser(description='RESTful service for reading environment metrics')
parser.add_argument('--port', type=int, required=False, default=8765,
                      help='the port to listen')
parser.add_argument('--disk', type=str, required=False, default="/dev/sda",
                      help='the disk to monitor temperature')
args = parser.parse_args()


# RESTful service
app = Flask(__name__)


# environment metrics
from metrics_env.metrics_env_http import metrics_inst, start_metrics_env_thread
print("starting the env metrics thread...")
start_metrics_env_thread()
print("thread started")

@app.route("/metrics", methods=["GET"])
def api_metrics_env():
    return jsonify(metrics_inst)
print("the controller for [GET]/metrics is registered")




# adjust time share of cgroup

from resource_manager.cpu_resource import get_cpu_cores, get_kube_overall_cpu_shares, get_kube_pods_shares, update_kube_pod_cpu_quota

@app.route("/cpu-cores", methods=["GET"])
def api_cpu_cores():
    return jsonify(get_cpu_cores())
print("the controller for [GET]/cpu-cores is registered")


@app.route("/kube-overall-cpu-shares", methods=["GET"])
def api_kube_cpu_shares():
    return jsonify(get_kube_overall_cpu_shares())
print("the controller for [GET]/kube-ovall-cpu-shares is registered")


@app.route("/kube-besteffort-pods-cpu-shares", methods=["GET"])
def api_get_kube_besteffort_pods_shares():
    return jsonify(get_kube_pods_shares(is_besteffort = True))
print("the controller for [GET]/kube-besteffort-pods-cpu-shares is registered")


@app.route("/kube-fixed-pods-cpu-shares", methods=["GET"])
def api_get_kube_fixed_pods_shares():
    return jsonify(get_kube_pods_shares(is_besteffort = False))
print("the controller for [GET]/kube-fixed-pods-cpu-shares is registered")


@app.route("/update-kube-pod-cpu-quota", methods=["PUT"])
def api_update_kube_pod_cpu_quota():
    req = request.get_json()
    if req is None or "uid" not in req or "quota" not in req or "is_besteffort" not in req:
        return "invalid request"
    print(req)
    return jsonify(update_kube_pod_cpu_quota(
        pod_uid = req["uid"],
        quota = req["quota"],
        is_besteffort = req["is_besteffort"],
    ))
print("the controller for [PUT]/update-kube-pod-cpu-quota is registered")


# Start the http server
print("start the http server on port %s" % (args.port))
if __name__ == "__main__":
    app.run(port=args.port, host='0.0.0.0')

