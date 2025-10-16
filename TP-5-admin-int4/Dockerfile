FROM ubuntu:focal
LABEL maintainer="Mykhailo TP-3 VAGRANT"

ENV DEBIAN_FRONTEND=noninteractive

# Install base tools + SSH
RUN apt-get update && apt-get install -y \
    openssh-server sudo passwd curl git iproute2 iputils-ping net-tools wget \
    && rm -rf /var/lib/apt/lists/*

# Prepare SSH
RUN mkdir /var/run/sshd

# Create vagrant user with password
RUN useradd -m -s /bin/bash vagrant \
    && echo "vagrant:vagrant" | chpasswd \
    && usermod -aG sudo vagrant \
    && echo "vagrant ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vagrant \
    && chmod 440 /etc/sudoers.d/vagrant

# Install Vagrant insecure SSH key
RUN mkdir -p /home/vagrant/.ssh \
    && chmod 700 /home/vagrant/.ssh \
    && curl -fsSL https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub \
       -o /home/vagrant/.ssh/authorized_keys \
    && chmod 600 /home/vagrant/.ssh/authorized_keys \
    && chown -R vagrant:vagrant /home/vagrant/.ssh

RUN apt-get update
RUN apt-get install nginx -y
# RUN sudo /usr/sbin/nginx

RUN apt-get install -y supervisor

# Supervisor configuration
RUN mkdir -p /etc/supervisor/conf.d

# Add supervisor program configs
COPY supervisord.conf /etc/supervisor/supervisord.conf

COPY index.html /var/www/html/index.html

# Configure Supervisor for SSH service
# RUN echo "[supervisord] \n\
# nodaemon = false \n\
# [program:sshd]\n\
# command=/usr/sbin/sshd -D" > /etc/supervisor.d/sshd.conf

# Configure Supervisor for Nginx service
# RUN echo "[supervisord]\n\
# nodaemon = false\n\
# [program:nginx]\n\
# command=/usr/sbin/nginx -c /etc/nginx/nginx.conf" > /etc/supervisor.d/nginx.conf

# Create directories and set permissions (if needed)
RUN mkdir -p /var/run/sshd && \
    chmod 755 /var/run/sshd


# Expose SSH
EXPOSE 22 80

# Add cgroup volume
VOLUME ["/sys/fs/cgroup"]

# Run SSH daemon in foreground (not systemd)
#CMD ["/usr/sbin/sshd", "-D"]
#CMD ["/bin/sh", "-c", "/usr/sbin/sshd -D & /usr/sbin/nginx"]


# Start the Supervisor service when the container starts
#CMD ["supervisord"]
# Run supervisor as CMD
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]

