# noed-as-container

This guide outlines how to create and use a Docker container that routes all outgoing traffic (except SSH traffic) through a VPN tunnel (tun) connected to a NordVPN server. The VPN server location is specified using the start-vpn-xxx.sh script, where xxx represents the target country.


**How It Works**

The container routes all outgoing traffic through a VPN tunnel (tun), except for SSH traffic.

The VPN tunnel connects to the NordVPN server of the country specified in the start-vpn-xxx.sh script.

Example: start-vpn-trk.sh connects to the Istanbul server of NordVPN.

**Getting Started**
**Building the Docker Image**

Use the provided Dockerfile and start.sh script to build the Docker image locally:

docker build -t nord .

Alternatively, you can pull the pre-built image from DockerHub:

docker pull hosdeburgh2/nord

If you pull the image from DockerHub, update the image name in the start-vpn-xxx.sh script from nord to hosdeburgh2/nord.

**Configuration Files**
The container requires the following configuration files to be mounted to /etc/nord/config inside the container. Ensure these files exist on the local machine:

**1. nord-xxx.ovpn**

The OpenVPN configuration file for the NordVPN server of the target country (xxx).

**2. pass.txt**

Contains your NordVPN account credentials.

Format:

username
password

**3 -rootpass.txt**

Contains the root password for connecting to the container via SSH.

Format:

rootpassword

**Usage Instructions**
**Starting the Container**

Run the appropriate start-vpn-xxx.sh script for your target country:

./start-vpn-xxx.sh

Replace xxx with the country code (e.g., trk for Turkey).

Ensure the /etc/nord/config folder on your local machine is mounted to the container’s /etc/nord/config directory.

**Connecting to the Container**

Use an SSH client (e.g., Netmode Syna) to connect to the container.

**Notes**

**1-Folder Mounting:**
Ensure the /etc/nord/config folder on your local machine contains the necessary configuration files and is correctly mounted to the container.

**2-Container SSH Access:**
SSH traffic is excluded from VPN routing, ensuring direct access to the container via SSH.

**3-Updating Image Name:**
If pulling the image from DockerHub, update the start-vpn-xxx.sh script to replace nord with hosdeburgh2/nord.

**Example Folder Structure**

Local machine folder: /etc/nord/config

/etc/nord/config/
  nord-trk.ovpn      # OpenVPN config for Turkey server
  pass.txt           # NordVPN credentials
  rootpass.txt       # Root SSH password for the container

**Additional Information**

The start-vpn-xxx.sh script determines the NordVPN server to which the container connects.

The container ensures secure traffic routing via the specified VPN tunnel while maintaining SSH access independently.
