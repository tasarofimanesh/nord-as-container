#!/bin/bash

# Configuration
IMAGE_NAME="nord"
DOCKERFILE_PATH="."

# Check if the image already exists
if docker images | grep -q "$IMAGE_NAME"; then
    echo "Docker image $IMAGE_NAME already exists. Deleting it..."
    docker rmi -f $IMAGE_NAME

    if [ $? -eq 0 ]; then
        echo "Existing Docker image $IMAGE_NAME has been removed."
    else
        echo "Failed to remove the existing Docker image $IMAGE_NAME. Exiting."
        exit 1
    fi
fi

# Build the Docker image
echo "Building the Docker image: $IMAGE_NAME..."
docker build -t $IMAGE_NAME $DOCKERFILE_PATH

# Check if the build was successful
if [ $? -eq 0 ]; then
    echo "Docker image $IMAGE_NAME built successfully!"
else
    echo "Failed to build the Docker image $IMAGE_NAME. Check the Dockerfile and logs for details."
    exit 1
fi
