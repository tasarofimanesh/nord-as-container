#!/bin/bash

# Get the list of all container names
containers=($(docker ps -a --format '{{.Names}}'))

# Display the list with numbers
echo "Select a container to route all x-ui traffic through it.:"
for i in "${!containers[@]}"; do
  echo "$((i+1)). ${containers[$i]}"
done

# Prompt the user to select a container by number
read -p "Enter the number of the container: " selected_number

# Assign the selected container name to vpn_container_name
vpn_container_name="${containers[$((selected_number-1))]}"


external_gateway=$(docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $vpn_container_name)

net_name=$(docker inspect --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}{{end}}' $vpn_container_name)

echo "     "
echo "External Gateway IP: $external_gateway"
echo "Network Name: $net_name"
echo "     "

# Check if the container exists and remove it if it does
if [ $(docker ps -a -q -f name=3x-ui) ]; then
    echo "Container '3x-ui' already exists. Removing it..."
    docker rm -f 3x-ui
else
    echo "No existing container named '3x-ui' found."
fi

# Run the container in the background
docker run -itd \
   -e XRAY_VMESS_AEAD_FORCED=false \
   -v $PWD/db/:/etc/x-ui/ \
   -v $PWD/cert/:/root/cert/ \
   -p 2053:2053 \
   -p 5050-5055:5050-5055 \
   --cap-add=NET_ADMIN \
   --device=/dev/net/tun \
   --network=$net_name \
   --restart=unless-stopped \
   --name 3x-ui \
   bigbugcc/3x-ui:latest

# Wait a few seconds for the container to initialize
echo "Waiting for the container to initialize..."
sleep 5

# Run commands inside the 3x-ui container using docker exec

# Install iproute2 inside the container
docker exec 3x-ui apk add --no-cache iproute2

# Configure rt_tables inside the container
docker exec 3x-ui mkdir -p /etc/iproute2
docker exec 3x-ui sh -c 'echo "20 ovpn2" > /etc/iproute2/rt_tables'

# Add iptables rules inside the container
docker exec 3x-ui iptables -t mangle -A OUTPUT -p tcp --sport 2053 -j MARK --set-mark 2
docker exec 3x-ui iptables -t mangle -A OUTPUT -p tcp --sport 5050 -j MARK --set-mark 2
docker exec 3x-ui iptables -t mangle -A OUTPUT -p tcp --sport 5051 -j MARK --set-mark 2
docker exec 3x-ui iptables -t mangle -A OUTPUT -p tcp --sport 5052 -j MARK --set-mark 2
docker exec 3x-ui iptables -t mangle -A OUTPUT -p tcp --sport 5053 -j MARK --set-mark 2
docker exec 3x-ui iptables -t mangle -A OUTPUT -p tcp --sport 5054 -j MARK --set-mark 2
docker exec 3x-ui iptables -t mangle -A OUTPUT -p tcp --sport 5055 -j MARK --set-mark 2

# Get the default gateway dynamically from the container
gateway=$(docker exec 3x-ui ip route | grep default | awk '{print $3}')

# Add the default route to ovpn2 table inside the container
docker exec 3x-ui ip route add default via $gateway table ovpn2

# Add rule for fwmark 2 inside the container
docker exec 3x-ui ip rule add from all fwmark 2 lookup ovpn2


# Replace the default route via external gateway using docker exec
docker exec 3x-ui ip route replace default via $external_gateway

echo "Network configuration complete inside the 3x-ui container."
