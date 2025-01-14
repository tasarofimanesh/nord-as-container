#!/bin/bash

#-----------------------------------------------
# Define the base config directory
CONFIG_DIR="/etc/nord/config"

# Get the OpenVPN configuration file from the environment variable
if [ -z "$NORD_OVPN_FILE" ]; then
    echo "Error: NORD_OVPN_FILE environment variable is not set!"
    exit 1
fi

NORD_OVPN_PATH="$CONFIG_DIR/$NORD_OVPN_FILE"

# Validate that the specified OpenVPN configuration file exists
if [ ! -f "$NORD_OVPN_PATH" ]; then
    echo "Error: Configuration file $NORD_OVPN_PATH not found!"
    exit 1
fi

#-----------------------------------------------
# Define paths to pass.txt and rootpass.txt
PASS_TXT_PATH="$CONFIG_DIR/pass.txt"
ROOTPASS_TXT_PATH="$CONFIG_DIR/rootpass.txt"

# Check if rootpass.txt exists and update the root password
if [ -f "$ROOTPASS_TXT_PATH" ]; then
    ROOT_PASSWORD=$(cat "$ROOTPASS_TXT_PATH")
    echo "root:$ROOT_PASSWORD" | chpasswd
    echo "Root password has been updated."
else
    echo "Error: rootpass.txt not found! Root password will not be updated."
fi

# Enable root login in SSH configuration
if grep -q "^#PermitRootLogin" /etc/ssh/sshd_config; then
    sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
elif grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
    sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
else
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
fi

# Restart the SSH service to apply changes
service ssh restart

#-----------------------------------------------
# Ensure pass.txt exists and is referenced in the OpenVPN config
if [ ! -f "$PASS_TXT_PATH" ]; then
    echo "Error: pass.txt not found at $PASS_TXT_PATH!"
    exit 1
fi

if ! grep -q "auth-user-pass $PASS_TXT_PATH" "$NORD_OVPN_PATH"; then
    sed -i "s|auth-user-pass|auth-user-pass $PASS_TXT_PATH|g" "$NORD_OVPN_PATH"
fi

#-----------------------------------------------
# Mark outgoing packets of SSH connection with an fwmark of 2

ssh_ports=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}')

function set_fwmark() {
    if ! iptables -t mangle -nvL OUTPUT | grep -q "tcp spt:$1 MARK set 0x2"; then
        iptables -t mangle -A OUTPUT -p tcp --sport "$1" -j MARK --set-mark 2
    fi
}

for p in $ssh_ports; do
    set_fwmark "$p"
done

#-----------------------------------------------
# Create and configure the ovpn2 routing table

if ! grep -q "ovpn2" /etc/iproute2/rt_tables; then
    echo "10 ovpn2" >> /etc/iproute2/rt_tables
fi

if ! ip rule show | grep -q "from all fwmark 0x2 lookup ovpn2"; then
    ip rule add from all fwmark 2 lookup ovpn2 > /dev/null
fi

if ! ip route show table ovpn2 | grep -q "default via"; then
    ip route add default via "$(ip route | grep "default via" | awk '{print $3}')" table ovpn2
fi

#-----------------------------------------------
# OpenVPN connection management

function kill_ovpn() {
    pkill -f "openvpn --config" || true
}

function connect_ovpn() {
    kill_ovpn
    while ! ip a | grep -q tun-nord; do
        sed -i "s/dev tun$/dev tun-nord/g" "$NORD_OVPN_PATH"
        openvpn --config "$NORD_OVPN_PATH" --daemon
        for i in {1..5}; do
            echo "Connecting to NordVPN..."
            sleep 1
            if ip a | grep -q tun-nord; then
                echo "Connected to NordVPN."
                break
            fi
        done
    done

    if ! iptables -t nat -nvL POSTROUTING | grep -q tun-nord; then
        iptables -t nat -A POSTROUTING -o tun-nord -j MASQUERADE
    fi
}

connect_ovpn

#-----------------------------------------------
# Keep the container running
tail -f /dev/null
