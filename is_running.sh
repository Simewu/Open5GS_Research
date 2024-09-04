#!/bin/bash

check_service() {
    local app_name="open5gs-$1"
    if pgrep -x "$app_name" > /dev/null; then
        echo "$1: RUNNING"
    else
        echo "$1: NOT RUNNING"
    fi
}

apps=("nrfd" "scpd" "amfd" "smfd" "upfd" "ausfd" "udmd" "pcfd" "nssfd" "bsfd" "udrd" "sgwcd" "sgwud" "hssd" "pcrfd")

for app in "${apps[@]}"; do
    check_service "$app"
done
