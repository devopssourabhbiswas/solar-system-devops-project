#!/bin/bash
exec > /var/log/user-data.log 2>&1

echo "=== Updating system packages ==="
apt-get update -y
apt-get upgrade -y

echo "=== Installing Python and dependencies ==="
apt-get install -y python3 python3-pip software-properties-common

echo "=== Installing Ansible ==="
# Install from default Ubuntu 24.04 repo (Ansible v9.x at time of writing)
apt-get install -y ansible

echo "=== Verifying Ansible installation ==="
ansible --version

echo "=== Ansible installation complete ==="