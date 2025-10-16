FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    openssh-server \
    sudo \
    passwd \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd

# Create vagrant user
RUN useradd -m -s /bin/bash vagrant \
    && echo "vagrant:vagrant" | chpasswd \
    && usermod -aG sudo vagrant

# Passwordless sudo
RUN echo "vagrant ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install Vagrant's insecure SSH key
RUN mkdir -p /home/vagrant/.ssh \
    && chmod 700 /home/vagrant/.ssh \
    && curl -fsSL https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub \
       -o /home/vagrant/.ssh/authorized_keys \
    && chmod 600 /home/vagrant/.ssh/authorized_keys \
    && chown -R vagrant:vagrant /home/vagrant/.ssh

EXPOSE 22
VOLUME ["/sys/fs/cgroup"]

CMD ["/usr/sbin/sshd", "-D"]
