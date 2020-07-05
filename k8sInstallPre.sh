#!/bin/sh

set -e 
set -o 
set -x 

yum install -y bash-completion ebtables ipset tmux nfs-utils socat wget conntrack ceph-common glusterfs-client  && \

yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine && \

yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo && \

yum install -y yum-utils docker-ce docker-ce-cli containerd.io && \

systemctl start docker && systemctl enable docker

setenforce 0

sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

