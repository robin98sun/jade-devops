#!/usr/bin/env bash

# before applying this command, make sure jade-addon is working on every pi device

freq=$1

update_freq() {
    host=aces-pi-$1$2
    cmd="curl -X PUT http://$host:8765/scalable-cpu-frequency"
    cmd="$cmd -H Content-Type:application/json"
    cmd="$cmd -d {\"freq\":\"$3\"}"
    echo $cmd
    $cmd
    echo ""
}

for i in {1..4}; do
    for j in {1..4}; do
        update_freq $i $j $freq
    done
done

for i in {5..6}; do
    for j in {0..7}; do
        update_freq $i $j $freq
    done
done
