#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run the script as root with: sudo ./first_compile.sh"
    exit
fi

echo "Starting installation of Open5GS..."

installed_version=$(mongod --version 2>/dev/null | grep -oP "(?<=v)\d+\.\d+\.\d+")
if [[ $installed_version == 4.4.* ]]; then
    echo "MongoDB version 4.4.x is already installed. Skipping MongoDB installation."
else
    # Step 1: Uninstall any conflicting MongoDB version
    echo "Checking for existing MongoDB installations..."
    if dpkg -l | grep -qE "(mongodb-org|mongodb-server|mongodb-server-core)"; then
        echo "Removing conflicting MongoDB packages..."
        
        # Remove all installed MongoDB-related packages safely
        sudo apt-get purge -y mongodb-org mongodb-org-server mongodb-org-shell mongodb-org-mongos mongodb-org-tools \
                             mongodb-server mongodb-server-core mongodb-clients || { echo "Failed to remove conflicting MongoDB packages"; exit 1; }

        # Clean up MongoDB directories (data and logs)
        sudo rm -rf /var/lib/mongodb
        sudo rm -rf /var/log/mongodb
    else
        echo "No conflicting MongoDB installations found."
    fi

    # If GPG step fails, try clearing MongoDB GPG key before proceeding:
    # sudo apt-key del 656408E390CFB1F5
    # sudo rm /etc/apt/sources.list.d/mongodb-org-4.4.list

    # Step 2: Installing MongoDB 4.4
    echo "Updating package lists..."
    sudo apt update || { echo "Failed to update package lists"; exit 1; }

    echo "Installing gnupg and curl if not already installed..."
    sudo apt install -y gnupg curl || { echo "Failed to install GnuPG or curl"; exit 1; }

    # Fallback 1: Try importing the MongoDB 4.4 public key using apt-key
    echo "Attempting to import MongoDB 4.4 server public key using apt-key..."
    if ! wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -; then
        echo "Failed to import MongoDB public key using apt-key. Trying signed-by method as fallback..."
        
        # Fallback 2: Use signed-by if apt-key fails
        if ! curl -fsSL https://www.mongodb.org/static/pgp/server-4.4.asc | sudo tee /usr/share/keyrings/mongodb-archive-keyring.gpg > /dev/null; then
            echo "Failed to import MongoDB public key using curl."
            exit 1
        fi
        echo "Adding MongoDB 4.4 repository using signed-by method..."
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
    else
        echo "Adding MongoDB 4.4 repository using apt-key method..."
        echo "deb [arch=amd64] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
    fi

    echo "Updating package lists after adding MongoDB repository..."
    if ! sudo apt update; then
        echo "Failed to update package lists after adding MongoDB repository."
        exit 1
    fi

    echo "Attempting to install MongoDB 4.4..."
    if ! sudo apt-get install -y --allow-change-held-packages mongodb-org=4.4.* mongodb-org-server=4.4.* mongodb-org-shell=4.4.* mongodb-org-mongos=4.4.* mongodb-org-tools=4.4.*; then
        echo "Initial MongoDB installation failed. Attempting to fix broken installations..."
        sudo apt --fix-broken install
        sudo apt autoremove -y
        sudo apt clean
        echo "Trying to install MongoDB 4.4 again..."
        if ! sudo apt-get install -y --allow-change-held-packages mongodb-org=4.4.* mongodb-org-server=4.4.* mongodb-org-shell=4.4.* mongodb-org-mongos=4.4.* mongodb-org-tools=4.4.*; then
            echo "Failed to install MongoDB 4.4 after attempting repairs. Exiting script."
            exit 1
        fi
    fi
fi

echo "Pinning MongoDB 4.4 packages to prevent automatic updates..."
echo "mongodb-org hold" | sudo dpkg --set-selections
echo "mongodb-org-server hold" | sudo dpkg --set-selections
echo "mongodb-org-shell hold" | sudo dpkg --set-selections
echo "mongodb-org-mongos hold" | sudo dpkg --set-selections
echo "mongodb-org-tools hold" | sudo dpkg --set-selections

echo "Checking MongoDB service..."
if ! sudo systemctl is-active --quiet mongod; then
    echo "Starting MongoDB service..."
    sudo systemctl start mongod
else
    echo "MongoDB service is already running."
fi

if ! sudo systemctl is-enabled --quiet mongod; then
    echo "Enabling MongoDB service to start on boot..."
    sudo systemctl enable mongod
else
    echo "MongoDB service is already enabled to start on boot."
fi


# Step 3: Setting up TUN device
echo "Checking if TUN device ogstun exists..."
if ! ip link show ogstun > /dev/null 2>&1; then
    echo "Creating TUN device..."
    sudo ip tuntap add name ogstun mode tun
else
    echo "TUN device ogstun already exists."
fi

echo "Checking and assigning IP addresses to TUN device..."
if ! ip addr show ogstun | grep -q "10.45.0.1/16"; then
    sudo ip addr add 10.45.0.1/16 dev ogstun
else
    echo "IP address 10.45.0.1/16 already assigned to ogstun."
fi

if ! ip addr show ogstun | grep -q "2001:db8:cafe::1/48"; then
    sudo ip addr add 2001:db8:cafe::1/48 dev ogstun
else
    echo "IPv6 address 2001:db8:cafe::1/48 already assigned to ogstun."
fi

echo "Setting TUN device up..."
sudo ip link set ogstun up

# Step 4: Building Open5GS
echo "Installing dependencies for building Open5GS..."
sudo apt install -y python3-pip python3-setuptools python3-wheel ninja-build build-essential flex bison git cmake libsctp-dev libgnutls28-dev libgcrypt-dev libssl-dev libidn11-dev libmongoc-dev libbson-dev libyaml-dev libnghttp2-dev libmicrohttpd-dev libcurl4-gnutls-dev libnghttp2-dev libtins-dev libtalloc-dev meson

# Check if Open5GS has already been built and installed
if [ ! -d "build" ]; then
    echo "Compiling Open5GS with Meson..."
    meson build --prefix=$(pwd)/install
else
    echo "Open5GS build directory already exists."
fi

echo "Building Open5GS..."
ninja -C build

echo "Running test programs..."
cd build
meson test -v

echo "Installing Open5GS..."
ninja install

echo "Installation complete! Open5GS has been installed and configured."

# Get the full path of the current directory
current_dir=$(pwd)

# Define library paths
lib_sbi_path="$current_dir/open5gs/build/lib/sbi"
lib_proto_path="$current_dir/open5gs/build/lib/proto"
lib_core_path="$current_dir/install/lib/x86_64-linux-gnu"  # Use the install directory for core library

# Function to update .bashrc if necessary
update_ld_library_path() {
    local lib_path=$1
    if [[ ":$LD_LIBRARY_PATH:" != *":$lib_path:"* ]]; then
        # Append the new path to the LD_LIBRARY_PATH in .bashrc
        echo "export LD_LIBRARY_PATH=$lib_path:\$LD_LIBRARY_PATH" >> ~/.bashrc
    fi
}

# Update LD_LIBRARY_PATH with all necessary library paths
update_ld_library_path $lib_sbi_path
update_ld_library_path $lib_proto_path
update_ld_library_path $lib_core_path

# Inform the user to source .bashrc
echo "\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
echo "LD_LIBRARY_PATH updated, please run 'source ~/.bashrc' to apply changes."
