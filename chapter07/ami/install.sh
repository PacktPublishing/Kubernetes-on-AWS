#!/bin/bash

set -euxo pipefail

add-key () {
  curl -fsSL $1 | apt-key add -
}

add-repo () {
  add-apt-repository "deb $*"
}

# Update the base system
apt-get update
apt-get upgrade -y

add-key https://download.docker.com/linux/ubuntu/gpg
add-repo https://download.docker.com/linux/ubuntu xenial stable
add-key https://packages.cloud.google.com/apt/doc/apt-key.gpg
add-repo https://apt.kubernetes.io kubernetes-xenial main
add-key https://packagecloud.io/errm/ekstrap/gpgkey
add-repo https://packagecloud.io/errm/ekstrap/ubuntu/ xenial main

apt-get update

mkdir -p /etc/systemd/system/docker.service.d/
cat << CONFIG > /etc/systemd/system/docker.service.d/10-iptables.conf
[Service]
ExecStartPost=/sbin/iptables -P FORWARD ACCEPT
CONFIG

# Logrotate config for kube-proxy
cat << CONFIG > /etc/logrotate.d/kube-proxy
/var/log/kube-proxy.log {
    rotate 5
    daily
    compress
}
CONFIG

# Install aws-iam-authenticator
curl -Lo /usr/local/bin/aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.3.0/heptio-authenticator-aws_0.3.0_linux_amd64
chmod +x /usr/local/bin/aws-iam-authenticator

# Install docker, kuberntes and ekstrap
apt-get install -y \
  docker-ce=$DOCKER_VERSION* \
  kubelet=$K8S_VERSION* \
  ekstrap=$EKSTRAP_VERSION*

# Cleanup
apt-get clean
rm -rf /tmp/*
