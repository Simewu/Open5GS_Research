#!/bin/bash

./network_config.sh

run_in_background() {
    local app_name="open5gs-$1"
    if pgrep -x "$app_name" > /dev/null; then
        echo "Already running $app_name."
    else
        echo "Starting $app_name in background..."
        ./install/bin/$app_name > /dev/null 2>&1 &
    fi
}

run_in_terminal() {
    local app_name="open5gs-$1"
    if pgrep -x "$app_name" > /dev/null; then
        echo "Already running $app_name."
    else
        echo "Starting $app_name in GNOME Terminal..."
        gnome-terminal -t "$app_name Node" -- /bin/sh -c "./install/bin/$app_name"
    fi
}

apps=("nrfd" "scpd" "amfd" "smfd" "upfd" "ausfd" "udmd" "pcfd" "nssfd" "bsfd" "udrd" "sgwcd" "sgwud" "hssd" "pcrfd")

if [[ $1 == "show" ]]; then
    # Run in separate terminal windows
    for app in "${apps[@]}"; do
        run_in_terminal "$app"
    done
else
    # Run in background
    for app in "${apps[@]}"; do
        run_in_background "$app"
    done
fi

# Changed below to be ran with `./run.sh show`
# sudo gnome-terminal -t "NRF Node" -- /bin/sh -c './install/bin/open5gs-nrfd'
# sudo gnome-terminal -t "SCP Node" -- /bin/sh -c './install/bin/open5gs-scpd'
# sudo gnome-terminal -t "AMF Node" -- /bin/sh -c './install/bin/open5gs-amfd'
# sudo gnome-terminal -t "SMF Node" -- /bin/sh -c './install/bin/open5gs-smfd'
# sudo gnome-terminal -t "UPF Node" -- /bin/sh -c './install/bin/open5gs-upfd'
# sudo gnome-terminal -t "AUSF Node" -- /bin/sh -c './install/bin/open5gs-ausfd'
# sudo gnome-terminal -t "UDM Node" -- /bin/sh -c './install/bin/open5gs-udmd'
# sudo gnome-terminal -t "PCF Node" -- /bin/sh -c './install/bin/open5gs-pcfd'
# sudo gnome-terminal -t "NSSF Node" -- /bin/sh -c './install/bin/open5gs-nssfd'
# sudo gnome-terminal -t "BSF Node" -- /bin/sh -c './install/bin/open5gs-bsfd'
# sudo gnome-terminal -t "UDR Node" -- /bin/sh -c './install/bin/open5gs-udrd'
# sudo gnome-terminal -t "SGWC Node" -- /bin/sh -c './install/bin/open5gs-sgwcd'
# sudo gnome-terminal -t "SGWU Node" -- /bin/sh -c './install/bin/open5gs-sgwud'
# sudo gnome-terminal -t "HSS Node" -- /bin/sh -c './install/bin/open5gs-hssd'
# sudo gnome-terminal -t "PCRF Node" -- /bin/sh -c './install/bin/open5gs-pcrfd'
