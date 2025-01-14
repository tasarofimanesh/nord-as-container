#!/bin/bash

# Configuration
CONTAINER_NAME="vpn-trk"
CONFIG_PATH="/etc/nord/config"
NORD_OVPN_FILE="nord-trk.ovpn"

# Stop and remove any existing container with the same name
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    echo "Stopping and removing existing container..."
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
fi

# Run the Docker container
echo "Starting the VPN container..."
docker run -d \
    --name $CONTAINER_NAME \
    -p 9090:9090 \
    --cap-add=NET_ADMIN \
    --device=/dev/net/tun \
    -v $CONFIG_PATH:/etc/nord/config:ro \
    -e NORD_OVPN_FILE=$NORD_OVPN_FILE \
    nord

# Check if the container is running
if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
    echo "Container $CONTAINER_NAME is running successfully!"
else
    echo "Failed to start the container. Check the Docker logs for details."
fi
