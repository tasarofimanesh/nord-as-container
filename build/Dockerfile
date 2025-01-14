FROM debian:bullseye

# Install required packages
RUN apt-get update && apt-get install -y \
    openvpn \
    openssh-server \
    iptables \
    iputils-ping \
    sudo && \
    mkdir /var/run/sshd && \
    echo 'root:root' | chpasswd

# Configure SSH server
RUN echo "Port 9090" >> /etc/ssh/sshd_config
RUN echo "Port 9091" >> /etc/ssh/sshd_config
RUN echo "Port 9092" >> /etc/ssh/sshd_config
RUN echo "Port 9093" >> /etc/ssh/sshd_config
RUN echo "Port 9094" >> /etc/ssh/sshd_config

# Expose port 9090 for SSH
EXPOSE 9090-9094


# Start script to initialize OpenVPN and SSH
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
