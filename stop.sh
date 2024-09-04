#!/bin/bash

# Function to stop service
stop_service() {
    local app_name="open5gs-$1"
    if pgrep -x "$app_name" > /dev/null; then
        echo "Stopping $app_name..."
        sudo pkill -9 -x "$app_name"
    else
        echo "$app_name is not running."
    fi
}

# Array of applications
apps=("nrfd" "scpd" "amfd" "smfd" "upfd" "ausfd" "udmd" "pcfd" "nssfd" "bsfd" "udrd" "sgwcd" "sgwud" "hssd" "pcrfd")

# Check if sudo is needed and prompt if it is not already running as root
if [[ $(id -u) -ne 0 ]]; then
    echo "Some operations require root privileges..."
    # Try to elevate privileges
    sudo echo "Privileges elevated successfully."
fi

# Iterate through each application and stop if running
for app in "${apps[@]}"; do
    stop_service "$app"
done

#echo lab | sudo -S pkill -f -9 open5gs
