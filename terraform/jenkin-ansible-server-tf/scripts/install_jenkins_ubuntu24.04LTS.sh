#!/bin/bash
exec > /var/log/user-data.log 2>&1

echo "=== Updating system packages ==="
apt-get update -y
apt-get upgrade -y

echo "=== Checking for Java installation ==="
if ! command -v java &> /dev/null; then
    echo "Java not found — installing OpenJDK 21..."
    apt-get install -y openjdk-21-jdk
else
    echo "Java is already installed: $(java -version 2>&1 | head -n 1)"
fi

echo "=== Adding Jenkins repository and key ==="
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/" | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null

echo "=== Installing Jenkins ==="
apt-get update -y
apt-get install -y jenkins

echo "=== Enabling and starting Jenkins service ==="
systemctl enable jenkins
systemctl start jenkins

echo "=== Jenkins installation complete ==="
systemctl status jenkins --no-pager

echo "=== Updating system packages after jenkins installation ==="
apt-get update -y
apt-get upgrade -y