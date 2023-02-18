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

from resource_manager.cpu_resource import get_cpu_cores
from resource_manager.cpu_resource import get_kube_overall_cpu_shares 
from resource_manager.cpu_resource import get_kube_pods_cgroup_cpu_info
from resource_manager.cpu_resource import get_kube_all_pods_cgroup_cpu_info
from resource_manager.cpu_resource import get_kube_pod_cgroup_cpu_resource
from resource_manager.cpu_resource import update_kube_pod_cgroup_cpu_resource

def jadify_response(res, err = None):
    if err is not None:
        return {
            "error": err,
        }

    return {
        "status": "OK",
        "payload": res,
    }


@app.route("/cpu-cores", methods=["GET"])
def api_cpu_cores():
    return jsonify(jadify_response(get_cpu_cores()))
print("the controller for [GET]/cpu-cores is registered")


@app.route("/kube-overall-cpu-shares", methods=["GET"])
def api_kube_cpu_shares():
    res = jsonify(jadify_response(get_kube_overall_cpu_shares()))
    app.logger.info("response of /kube-overall-cpu-shares:", res)
    return res
print("the controller for [GET]/kube-ovall-cpu-shares is registered")


@app.route("/kube-besteffort-pods-cpu-resources", methods=["GET"])
def api_get_kube_besteffort_pods_cpu_resources():
    return jsonify(jadify_response(get_kube_pods_cgroup_cpu_info(is_besteffort = True)))
print("the controller for [GET]/kube-besteffort-pods-cpu-resources is registered")


@app.route("/kube-fixed-pods-cpu-resources", methods=["GET"])
def api_get_kube_fixed_pods_cpu_resources():
    return jsonify(jadify_response(get_kube_pods_cgroup_cpu_info(is_besteffort = False)))
print("the controller for [GET]/kube-fixed-pods-cpu-resources is registered")

@app.route("/kube-all-pods-cpu-resources", methods=["GET"])
def api_get_kube_all_pods_cgroup_cpu_info():
    return jsonify(jadify_response(get_kube_all_pods_cgroup_cpu_info()))
print("the controller for [GET]/kube-all-pods-cpu-resources is registered")



@app.route("/kube-pod-cpu-resource", methods=["GET"])
def api_get_kube_pod_cpu_quota():
    resource_type = request.args.get('type')
    pod_uid = request.args.get('uid')
    is_besteffort_str = request.args.get('is_besteffort')
    if resource_type is None or resource_type == "" or pod_uid is None or pod_uid == "" or is_besteffort_str is None:
        return jsonify(jadify_response(None, err="invalid request"))

    is_besteffort = False
    if is_besteffort_str == "" or is_besteffort_str.lower() == "true" or is_besteffort_str.lower() == "yes" or is_besteffort_str.lower() == "y" or is_besteffort_str.lower() == "t":
        is_besteffort = True
    return jsonify(jadify_response(get_kube_pod_cgroup_cpu_resource(resource_type, pod_uid, is_besteffort)))
print("the controller for [GET]/kube-pod-cpu-resource is registered")

@app.route("/kube-pod-cpu-resource", methods=["PUT"])
def api_update_kube_pod_cpu_quota():
    req = request.get_json()
    if req is None or "uid" not in req or "value" not in req or "is_besteffort" not in req or "type" not in req:
        return jsonify(jadify_response(None, err="invalid request"))
    passwd = None
    if "passwd" in req:
        passwd = req["passwd"]
    return jsonify(jadify_response(update_kube_pod_cgroup_cpu_resource(
        resource_type = req["type"],
        pod_uid = req["uid"],
        value = req["value"],
        passwd = passwd,
        is_besteffort = req["is_besteffort"],
    )))
print("the controller for [PUT]/kube-pod-cpu-resource is registered")


# Start the http server
print("start the http server on port %s" % (args.port))
if __name__ == "__main__":
    app.run(port=args.port, host='0.0.0.0')

